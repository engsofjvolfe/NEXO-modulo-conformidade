#!/bin/bash
# lib/common.sh
#
# Funções compartilhadas por todos os scripts de hook deste projeto.
# Todo script começa com:
#   source "$(dirname "$0")/lib/common.sh"
#   read_input
#
# Isso existe pra três coisas não ficarem repetidas oito vezes: ler o
# JSON de entrada, checar se há autorização ativa (AUTORIZO-TRAVA),
# e registrar em log sempre que algo relevante acontece.

STATE_DIR="${CLAUDE_PROJECT_DIR}/.claude/hooks/state"
AUTH_FILE="${STATE_DIR}/current-authorization"
CONFIRM_DIR="${STATE_DIR}/confirmations"
PENDING_QUESTION_DIR="${STATE_DIR}/pending-question"
OVERRIDES_LOG="${STATE_DIR}/overrides.log"
EDIT_LOG="${STATE_DIR}/edit-order.log"
PREVIEW_LOG="${STATE_DIR}/preview-sessions.log"
PR_REVIEW_LOG="${STATE_DIR}/pr-review-log.txt"
SYNTHESIS_FILE="${STATE_DIR}/synthesis.json"

mkdir -p "$STATE_DIR" "$CONFIRM_DIR" "$PENDING_QUESTION_DIR"

# --- Síntese (estado atual, não o diário) ---------------------------
#
# Cada log deste projeto (edit-order.log, read-log.txt, etc.) é um
# diário: cresce pra sempre, nunca apaga nada, é a fonte bruta -- ótimo
# pra investigar depois, ruim pra checar rápido (checar "isso já foi
# feito?" reler o diário inteiro toda vez, ficando mais lento conforme
# a sessão cresce). A síntese é o oposto: um arquivo pequeno, JSON, que
# guarda só o estado ATUAL de cada coisa (foi tocado? há quanto tempo,
# em número de ações, não em relógio?) -- suficiente pra responder
# "isso já foi feito, e ainda vale?" sem reler nada.
#
# "Ainda vale" é a parte importante -- a síntese não é "marcar como
# feito pra sempre": cada entrada carrega o número da ação (não da
# hora do relógio) em que foi confirmada, e cada checagem decide, na
# hora, se essa distância (ação atual menos ação registrada) ainda é
# aceitável pra aquela regra específica -- mesmo princípio já usado
# antes só pra citação de documento (janela das 20 leituras mais
# recentes), generalizado agora pra qualquer fato guardado aqui.
#
# O diário nunca é substituído -- continua existindo, cresce do mesmo
# jeito, serve de prova bruta pra quem quiser investigar ou fazer uma
# segunda conferência independente, sem confiar na síntese de ninguém.
# A síntese só existe *a mais*, como atalho rápido.
#
# Reinicia (arquivo novo, contador em zero) uma vez por sessão --
# ver session_start_reset.sh -- pra nunca deixar um fato de uma sessão
# anterior contar como "confirmado nesta sessão".

synthesis_init() {
  # "Existe" não basta -- achado ao vivo nesta rodada: duas chamadas
  # concorrentes de synthesis_bump/synthesis_set (lote de Read em
  # paralelo, cada Read disparando seu próprio post_read_track.sh) só
  # escreviam num "${SYNTHESIS_FILE}.tmp" fixo -- uma concorrência
  # dessas truncou o arquivo real pra 0 bytes. Daí em diante, `[[ -f ]]`
  # continuava vendo "existe" e nunca recriava; e um arquivo vazio, lido
  # por `jq` (sem `-e`), produz zero valores de saída sem erro nenhum
  # (jq trata entrada vazia como sucesso silencioso) -- então toda
  # leitura seguinte regravava por cima do mesmo vazio, pra sempre, sem
  # nenhum aviso. Checar conteúdo válido, não só existência, quebra
  # esse ciclo -- reconstrói do zero se o arquivo estiver vazio ou não
  # for JSON.
  if [[ ! -s "$SYNTHESIS_FILE" ]] || ! jq empty "$SYNTHESIS_FILE" >/dev/null 2>&1; then
    echo '{"acao_atual": 0, "fatos": {}}' > "$SYNTHESIS_FILE"
  fi
}

# Nome de arquivo temporário único por chamada (PID + número aleatório)
# -- nunca o mesmo "${SYNTHESIS_FILE}.tmp" fixo de antes.
synthesis_tmp_path() {
  echo "${SYNTHESIS_FILE}.$$.${RANDOM}.tmp"
}

# Trava baseada em mkdir (criar uma pasta é atômico entre processos,
# inclusive no Windows -- dois processos tentando criar a mesma pasta
# ao mesmo tempo, só um consegue) -- em volta de cada leitura+escrita
# da ficha. Achado ao vivo nesta rodada: mesmo depois de corrigir a
# corrupção (arquivo virando 0 bytes), um lote de escritas concorrentes
# (várias leituras em paralelo, cada uma com seu próprio processo)
# ainda perdia fatos -- cada processo lê o estado atual, escreve o
# próprio resultado por cima, e quem termina por último apaga o que os
# outros escreveram nesse meio-tempo. A trava serializa as escritas:
# só um processo por vez lê e escreve, nenhum fato desaparece. Trava
# "presa" (processo morreu sem liberar) se quebra sozinha depois de
# ~5 segundos de espera, em vez de travar a sessão inteira pra sempre.
synthesis_lock() {
  local lockdir="${SYNTHESIS_FILE}.lock"
  local tentativas=0
  while ! mkdir "$lockdir" 2>/dev/null; do
    tentativas=$((tentativas + 1))
    if [[ $tentativas -gt 50 ]]; then
      rmdir "$lockdir" 2>/dev/null
      break
    fi
    sleep 0.1
  done
}

synthesis_unlock() {
  rmdir "${SYNTHESIS_FILE}.lock" 2>/dev/null
}

# Anda o "relógio" da síntese uma ação -- chamado pelos ganchos
# post_*_track.sh, sempre que algo relevante acontece (leitura
# completa, edição). Devolve o novo valor por stdout.
synthesis_bump() {
  synthesis_lock
  synthesis_init
  local novo tmp
  novo=$(jq '.acao_atual += 1 | .acao_atual' "$SYNTHESIS_FILE" 2>/dev/null)
  [[ -z "$novo" ]] && novo=1
  tmp=$(synthesis_tmp_path)
  if jq --argjson n "$novo" '.acao_atual = $n' "$SYNTHESIS_FILE" > "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
    mv "$tmp" "$SYNTHESIS_FILE"
  else
    rm -f "$tmp"
  fi
  synthesis_unlock
  echo "$novo"
}

# Marca um fato como confirmado agora (na ação atual). Uso:
#   synthesis_set "leitura.<nome-do-documento>"
#   synthesis_set "edicao.<modulo>.concept"
synthesis_set() {
  local chave="$1"
  synthesis_lock
  synthesis_init
  local atual tmp
  atual=$(jq -r '.acao_atual' "$SYNTHESIS_FILE" 2>/dev/null)
  tmp=$(synthesis_tmp_path)
  if jq --arg k "$chave" --argjson a "${atual:-0}" '.fatos[$k] = $a' "$SYNTHESIS_FILE" > "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
    mv "$tmp" "$SYNTHESIS_FILE"
  else
    rm -f "$tmp"
  fi
  synthesis_unlock
}

# Devolve, por stdout, há quantas ações um fato foi confirmado pela
# última vez (0 = agora mesmo; vazio = nunca confirmado nesta sessão).
synthesis_age() {
  local chave="$1"
  synthesis_init
  local confirmado_em atual
  confirmado_em=$(jq -r --arg k "$chave" '.fatos[$k] // empty' "$SYNTHESIS_FILE" 2>/dev/null)
  [[ -z "$confirmado_em" ]] && return 0
  atual=$(jq -r '.acao_atual' "$SYNTHESIS_FILE" 2>/dev/null)
  echo $(( ${atual:-0} - confirmado_em ))
}

# Um fato foi confirmado, e a distância (em ações) até agora está
# dentro do limite aceitável pra essa regra? Uso:
#   synthesis_fresh "leitura.modulos/README.md" 20
synthesis_fresh() {
  local chave="$1" limite="$2"
  local idade
  idade=$(synthesis_age "$chave")
  [[ -z "$idade" ]] && return 1
  [[ "$idade" -le "$limite" ]]
}

# Igual a synthesis_fresh, mas pra quando o "documento anterior" da
# cascata não tem nome de arquivo fixo -- uma pasta inteira (ex.:
# schemas/, que pode ter qualquer nome de arquivo dentro, ou nem
# existir pra um módulo sem contrato de dado). Devolve sucesso se
# existir ao menos um fato "leitura.<algo que começa com o prefixo>"
# dentro da janela de frescor. Uso:
#   synthesis_any_fresh_with_prefix "leitura.$MODDIR/schemas/" 20
synthesis_any_fresh_with_prefix() {
  local prefixo="$1" limite="$2"
  synthesis_init
  local atual chave idade
  atual=$(jq -r '.acao_atual' "$SYNTHESIS_FILE" 2>/dev/null)
  # Achado ao vivo enquanto testava esta função: `jq` neste ambiente
  # (Windows/Git Bash) devolve as linhas terminadas em "\r\n", e `read`
  # só corta o "\n" -- o "\r" sobrava no fim de $chave, fazendo a
  # comparação de chave contra `.fatos[$k]` falhar sempre (chave "igual
  # visualmente" mas literalmente diferente, por causa do caractere
  # invisível). Cortar "\r" explicitamente depois do `read` evita isso.
  while IFS= read -r chave; do
    chave="${chave%$'\r'}"
    [[ -z "$chave" ]] && continue
    idade=$(jq -r --arg k "$chave" '.fatos[$k] // empty' "$SYNTHESIS_FILE" 2>/dev/null)
    [[ -z "$idade" ]] && continue
    if [[ $(( ${atual:-0} - idade )) -le "$limite" ]]; then
      return 0
    fi
  done < <(jq -r --arg p "$prefixo" '.fatos | keys[] | select(startswith($p))' "$SYNTHESIS_FILE" 2>/dev/null)
  return 1
}

# Reinicia a síntese pro estado vazio -- chamado uma vez por sessão
# nova (session_start_reset.sh), nunca no meio de uma sessão.
synthesis_reset() {
  echo '{"acao_atual": 0, "fatos": {}}' > "$SYNTHESIS_FILE"
}

# Todo hook deste projeto lê o JSON de entrada via jq (função field()
# abaixo). Sem jq instalado, "field" falha e devolve string vazia --
# em silêncio, porque field() redireciona o erro do jq pra /dev/null
# de propósito (evita que uma chave ausente no JSON vire ruído). Sem
# esta checagem, um hook inteiro "roda" sem checar nada de verdade e
# sem nenhum aviso -- falha travando (fail closed) em vez de falhar
# em silêncio (fail open). Achado ao vivo nesta máquina (jq ausente),
# confirmado por teste real.
require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    block "jq ausente" "jq não está instalado -- todo hook deste projeto depende dele pra ler o JSON de entrada, e sem ele as checagens não travam nada de verdade (silêncio, não segurança). Instale jq (ver MANUAL.md, seção Instalação) antes de continuar."
  fi
}

# Lê todo o stdin uma vez (só dá pra ler uma vez por processo) e
# guarda em $HOOK_INPUT pro resto do script usar.
read_input() {
  require_jq
  HOOK_INPUT=$(cat)
}

# Atalho pra extrair um campo do JSON de entrada com jq.
# Uso: field '.tool_input.command'
field() {
  echo "$HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null
}

# Existe autorização ativa pra ESTA mensagem? (escrita pelo hook
# user_prompt_submit.sh, que roda antes de qualquer outro hook nesta
# resposta)
is_authorized() {
  [[ -s "$AUTH_FILE" ]]
}

authorized_reason() {
  [[ -f "$AUTH_FILE" ]] && cat "$AUTH_FILE"
}

# Confirmação pontual, mais estreita que AUTORIZO-TRAVA -- resolve só
# UM ponto de checagem específico, sem liberar o resto do gancho, ao
# contrário de AUTORIZO-TRAVA (bypass geral, checado uma vez no topo
# do script). Escrita por user_prompt_submit.sh quando SUA mensagem
# (nunca a minha) contém a frase exata esperada pra aquele ponto --
# apagada a cada mensagem nova, mesma regra de não ficar "pendurada".
# Um arquivo por ponto, dentro de CONFIRM_DIR -- generalizado a partir
# dos dois arquivos fixos que existiam antes (current-no-finding-
# confirmation, current-no-adr-confirmation), pra um ponto de checagem
# novo não precisar de uma variável e uma função só pra ele.
confirmation_confirmed() {
  local nome="$1"
  [[ -s "${CONFIRM_DIR}/${nome}" ]]
}

no_finding_confirmed() { confirmation_confirmed "no-finding"; }
no_adr_confirmed() { confirmation_confirmed "no-adr"; }

# Um bloqueio do evento Stop cuja resposta só a pessoa que conduz a
# sessão sabe (autorização pendente, pergunta de julgamento) não deve
# se repetir sozinho: o evento Stop, quando bloqueado, obriga a
# resposta a continuar -- e continuar dispara o mesmo evento Stop de
# novo, no mesmo bloqueio, sem nenhuma mensagem nova da pessoa no meio
# -- um laço que só termina quando ela responde, mas que a mantém
# esperando enquanto isso, porque cada volta do laço ainda escreve
# alguma coisa. Corrigido: cada ponto de bloqueio desse tipo pergunta
# uma vez, marca que já perguntou, e libera (nunca bloqueia de novo)
# enquanto a marca existir -- ela só é apagada quando uma mensagem
# nova de verdade chega (user_prompt_submit.sh), momento em que faz
# sentido perguntar de novo, porque a mensagem nova pode ter mudado a
# situação. Não se aplica a bloqueio que a própria resposta consegue
# corrigir sozinha (ex.: emoji no texto) -- esses continuam
# bloqueando toda vez, porque insistir faz sentido quando quem decide
# sou eu mesmo, não a pessoa.
question_already_asked() {
  local nome="$1"
  [[ -s "${PENDING_QUESTION_DIR}/${nome}" ]]
}

mark_question_asked() {
  local nome="$1" motivo="$2"
  echo "$motivo" > "${PENDING_QUESTION_DIR}/${nome}"
}

# Um bloqueio do evento Stop cuja resposta só a pessoa que conduz a
# sessão sabe (autorização pendente, pergunta de julgamento) não deve
# se repetir sozinho: o evento Stop, quando bloqueado, obriga a
# resposta a continuar -- e continuar dispara o mesmo evento Stop de
# novo, no mesmo bloqueio, sem nenhuma mensagem nova da pessoa no meio
# -- um laço que só termina quando ela responde, mas que a mantém
# esperando enquanto isso, porque cada volta do laço ainda escreve
# alguma coisa. Corrigido: cada ponto de bloqueio desse tipo pergunta
# uma vez, marca que já perguntou, e libera (nunca bloqueia de novo)
# enquanto a marca existir -- ela só é apagada quando uma mensagem
# nova de verdade chega (user_prompt_submit.sh), momento em que faz
# sentido perguntar de novo, porque a mensagem nova pode ter mudado a
# situação. Não se aplica a bloqueio que a própria resposta consegue
# corrigir sozinha (ex.: emoji no texto) -- esses continuam
# bloqueando toda vez, porque insistir faz sentido quando quem decide
# sou eu mesmo, não a pessoa.
question_already_asked() {
  local nome="$1"
  [[ -s "${PENDING_QUESTION_DIR}/${nome}" ]]
}

mark_question_asked() {
  local nome="$1" motivo="$2"
  echo "$motivo" > "${PENDING_QUESTION_DIR}/${nome}"
}

# Windows usa "\" como separador de caminho; as checagens deste projeto
# comparam substring com "/" (padrão Unix, usado nas regras do
# CLAUDE.md). Sem normalizar, uma checagem como '"$CWD" contém
# "/.claude/worktrees/"' nunca bate contra um caminho do Windows tipo
# "H:\...\.claude\worktrees\...", mesmo estando de verdade dentro da
# worktree -- bloqueando toda edição por engano. Usar em todo caminho
# (cwd, file_path) antes de comparar ou gravar em log.
normalize_path() {
  echo "${1//\\//}"
}

# Compara dois caminhos ignorando maiúscula/minúscula, depois de
# normalizar a barra de cada um. Necessário porque, no Windows, a letra
# de unidade do mesmo diretório pode chegar em caixas diferentes
# dependendo de quem informou o caminho -- o "cwd" que o Claude Code
# manda pro hook e o caminho que "git worktree list" devolve para essa
# mesma pasta nem sempre usam a mesma caixa, mesmo apontando pro mesmo
# lugar em disco (sistema de arquivo do Windows não diferencia
# maiúscula de minúscula). Comparação de texto, sem consultar o disco
# nem resolver link simbólico.
paths_equal() {
  local a b
  a=$(normalize_path "$1")
  b=$(normalize_path "$2")
  [[ "${a,,}" == "${b,,}" ]]
}

# Lista de leitura obrigatória -- lida direto do arquivo de instruções
# do projeto hospedeiro (o arquivo que o próprio Claude Code já
# reconhece, em qualquer projeto: "CLAUDE.md", na raiz ou dentro de
# ".claude/"), nunca escrita à mão aqui dentro. O projeto hospedeiro
# marca o trecho relevante com duas linhas fixas (ver
# CONFORMIDADE_LEITURA_MARCADOR_INICIO/FIM abaixo); sem essas marcações,
# a lista vem vazia e este mecanismo simplesmente não exige nada --
# recurso que cada projeto liga por conta própria, nunca uma lista fixa
# deste módulo.
#
# Dentro do trecho marcado, dois formatos coexistem, cada um com seu
# próprio tratamento (distinção por sintaxe, não por nome de arquivo):
# - link markdown ("[texto](caminho)") -- documento que precisa de
#   leitura manual (ferramenta Read) de verdade.
# - "@caminho" -- convenção do próprio Claude Code pra importação
#   automática de contexto no início da sessão, sem chamada de Read.
CONFORMIDADE_LEITURA_MARCADOR_INICIO='<!-- conformidade-leitura-obrigatoria-inicio -->'
CONFORMIDADE_LEITURA_MARCADOR_FIM='<!-- conformidade-leitura-obrigatoria-fim -->'

# Devolve, por stdout, o texto entre as duas marcações acima, de
# dentro do primeiro arquivo de instruções do projeto hospedeiro
# encontrado (raiz, depois ".claude/"). Vazio se nenhum dos dois
# existir, ou se as marcações não estiverem presentes ali.
mandatory_reading_section() {
  local candidato
  for candidato in "${CLAUDE_PROJECT_DIR}/CLAUDE.md" "${CLAUDE_PROJECT_DIR}/.claude/CLAUDE.md"; do
    [[ -f "$candidato" ]] || continue
    awk -v inicio="$CONFORMIDADE_LEITURA_MARCADOR_INICIO" -v fim="$CONFORMIDADE_LEITURA_MARCADOR_FIM" '
      $0 == inicio { dentro=1; next }
      $0 == fim { dentro=0 }
      dentro { print }
    ' "$candidato"
    return 0
  done
}

# Nome de cada arquivo citado como link markdown dentro do trecho
# marcado -- exige leitura manual, tratado como qualquer outro arquivo
# do projeto a partir daí (mesma regra de frescor por token, sem
# exceção -- ver decisions/0023).
mandatory_reading_manual_docs() {
  mandatory_reading_section | grep -oE '\]\(<?[^)>]+>?\)' | sed -E 's/^\]\(<?//; s/>?\)$//' | while IFS= read -r caminho; do
    basename "$caminho"
  done
}

# Caminho de cada importação automática ("@caminho") dentro do trecho
# marcado.
mandatory_reading_auto_imports() {
  mandatory_reading_section | grep -oE '@\S+' | sed -E 's/^@//'
}

# Devolve, por stdout, o primeiro documento de leitura manual
# obrigatória ainda sem leitura completa *fresca* (por tokens
# estimados, decisions/0023) nesta sessão. Consulta a ficha (síntese),
# nunca relendo o diário inteiro. Vazio se todos foram lidos, de forma
# fresca -- ou se a lista veio vazia (projeto hospedeiro não usa este
# recurso).
first_unread_mandatory_doc() {
  local doc
  while IFS= read -r doc; do
    [[ -z "$doc" ]] && continue
    if ! synthesis_fresh_bytes "leitura_bytes.${doc}" "$TRANSCRIPT" "$LIMIAR_TOKENS_FRESCOR"; then
      echo "$doc"
      return 0
    fi
  done < <(mandatory_reading_manual_docs)
}

# Um caminho de importação automática tem rastro de conteúdo real no
# arquivo de transcrição desta sessão? "O arquivo existe no disco" e "o
# conteúdo de fato entrou na conversa" são coisas diferentes -- o
# mecanismo de importação em si acontece dentro do próprio Claude Code,
# antes de qualquer gancho rodar, sem chamada de ferramenta pra
# interceptar; a única forma mecânica disponível de checar o segundo
# fato é procurar um trecho conhecido do conteúdo dentro da
# transcrição bruta. Usa a primeira linha não vazia do arquivo como
# trecho de busca -- suficiente pra confirmar presença, sem exigir
# leitura do arquivo inteiro aqui dentro do gancho.
auto_import_loaded() {
  local caminho="$1" transcript="$2" arquivo trecho
  arquivo="${CLAUDE_PROJECT_DIR}/${caminho}"
  [[ -f "$arquivo" ]] || return 1
  [[ -f "$transcript" ]] || return 1
  trecho=$(grep -m1 -E '\S' "$arquivo")
  [[ -z "$trecho" ]] && return 0
  grep -qF -- "$trecho" "$transcript" 2>/dev/null
}

# Devolve, por stdout, o primeiro caminho de importação automática sem
# rastro de conteúdo na transcrição desta sessão. Vazio se todos têm
# rastro -- ou se a lista veio vazia.
first_unloaded_auto_import() {
  local caminho
  while IFS= read -r caminho; do
    [[ -z "$caminho" ]] && continue
    if ! auto_import_loaded "$caminho" "$TRANSCRIPT"; then
      echo "$caminho"
      return 0
    fi
  done < <(mandatory_reading_auto_imports)
}

# Padrão de emoji, compartilhado entre pre_edit_safety.sh (no momento
# da edição) e pre_commit_hygiene.sh (segunda conferência, no commit),
# e função de esquema impuro, também compartilhada -- um lugar só,
# nunca cópia duplicada que possa divergir entre os dois arquivos.
#
# Cobertura, por bloco Unicode (faixas de emoji de verdade, conforme
# `emoji-data.txt` do Unicode Consortium):
# - \x{1F1E6}-\x{1F1FF}: indicadores regionais -- bandeira de país é
#   sempre um par desses dois caracteres.
# - \x{1F300}-\x{1FAFF}: pictogramas, emoticons, transporte, símbolos
#   suplementares -- o grosso dos emojis "modernos".
# - \x{2600}-\x{27BF}: símbolos diversos e dingbats (ex.: sol, coração,
#   tesoura, avião).
# - \x{2B00}-\x{2BFF}: símbolos diversos e setas (ex.: estrela, seta
#   grossa colorida -- diferente do bloco "Arrows" abaixo).
# - \x{2300}-\x{23FF}: técnico diverso (ex.: relógio, ampulheta).
#
# Deliberadamente fora do padrão, mesmo aparecendo em alguma lista de
# emoji: o bloco Unicode "Arrows" (\x{2190}-\x{21FF}, setas
# tipográficas simples como "→"/"↔") e "Geometric Shapes"
# (\x{25A0}-\x{25FF}, quadrados/círculos simples) -- os dois usados o
# tempo todo como pontuação comum na prosa deste projeto (ex.:
# "concept.md → architecture.md"), e "©"/"®"/"™" -- comuns em texto
# legal/técnico comum. Incluir esses blocos bloquearia texto legítimo
# sem nenhum emoji de verdade envolvido.
EMOJI_PATTERN='[\x{1F1E6}-\x{1F1FF}\x{1F300}-\x{1FAFF}\x{2300}-\x{23FF}\x{2600}-\x{27BF}\x{2B00}-\x{2BFF}]'

# "grep -P" com \x{...} acima de 0x7F exige locale UTF-8 -- em locale
# "C"/"POSIX" (comum em Windows/Git Bash sem variável de locale
# definida), falha em silêncio (nunca acha nada, nunca bloqueia).
# Forçar LC_ALL=C.UTF-8 aqui, confirmado por teste ao vivo.
has_emoji() {
  LC_ALL=C.UTF-8 grep -qP "$EMOJI_PATTERN"
}

# Bloco cercado por ```yaml ou ```json que também tem required ou
# properties, junto com type (forma de todo bloco de contrato de dado
# deste projeto), e além disso tem description ou example -- esquema
# que devia ser dado puro mas não é.
schema_block_impure() {
  awk '
    /^```(yaml|json)[[:space:]]*$/ { infence=1; buf=""; next }
    /^```[[:space:]]*$/ {
      if (infence) {
        if ((buf ~ /required/ || buf ~ /properties/) && buf ~ /type/) {
          if (buf ~ /description/ || buf ~ /example/) { print "HIT"; exit }
        }
      }
      infence=0; next
    }
    infence { buf = buf $0 "\n" }
  ' | grep -q HIT
}

# Registra o uso de uma autorização -- nunca some em silêncio.
log_override() {
  echo "$(date -u +%FT%TZ) [$1] $2" >> "$OVERRIDES_LOG"
}

# Aviso acrescentado automaticamente a todo bloqueio (ver block(),
# abaixo) -- nunca escrito à mão em cada chamada, pra nunca ficar
# esquecido num gancho novo ou numa mensagem editada às pressas. Falado
# com o Claude (quem lê isto primeiro, direto na saída da ferramenta),
# não com a pessoa -- é o Claude quem precisa repassar, em poucas
# palavras, pra pessoa decidir.
BLOCK_REMINDER="Claude: conte isso pra pessoa, em poucas palavras, e pare -- nunca tente contornar, nunca decida sozinho que é engano. Só a pessoa destrava, escrevendo a frase de autorização na própria mensagem dela -- você nunca escreve essa frase."

# Bloqueia a ação atual com uma mensagem explicando o porquê. O aviso
# acima entra sozinho, sempre -- quem chama block() nunca precisa (nem
# deve) repetir essa parte.
block() {
  echo "$1 $BLOCK_REMINDER" >&2
  exit 2
}

# Caminhos deste módulo e do resto da ferramenta interna do projeto --
# a mesma lista do bloco "Ferramentas internas de trabalho desta sessao"
# do .gitignore, com o mesmo motivo por trás: edição aqui nunca depende
# da leitura obrigatória do NEXO (a cascata V-Model do produto -- ver
# CLAUDE.md), porque este módulo tem sua própria documentação e seu
# próprio processo de escrita, independente do produto que ele
# fiscaliza. Continua exigindo, do mesmo jeito, a leitura obrigatória
# quando o trabalho é sobre o NEXO em si (motor, docs gerais da raiz,
# etc.) -- a isenção é só pra este conjunto de caminhos.
INTERNAL_TOOLING_PATHS=(
  "modulos/conformidade" ".claude" "scripts" "MANUAL.md"
  "FRASES-DE-CONFIRMACAO.md" "configurar-protecao-branch.sh"
  ".vale.ini" ".vale" ".gitattributes"
  ".github/pull_request_template.md"
)

# Um caminho de arquivo/pasta é parte da ferramenta interna acima?
# Compara prefixo, depois de normalizar barra e remover barra inicial
# (caminho pode chegar absoluto, ex. "H:/.../modulos/conformidade/x", ou
# relativo, ex. "modulos/conformidade/x" -- checa só o final relevante).
is_internal_tooling_path() {
  local caminho rel
  caminho=$(normalize_path "$1")
  [[ -z "$caminho" ]] && return 1
  for rel in "${INTERNAL_TOOLING_PATHS[@]}"; do
    case "$caminho" in
      "$rel"|"$rel"/*|*"/${rel}"|*"/${rel}"/*) return 0 ;;
    esac
  done
  return 1
}

# Mesma checagem, pra um comando Bash inteiro (não um único caminho) --
# usada quando a ferramenta é "Bash", em vez de "Read"/"Write"/"Edit"
# com um "file_path" só. Aceita se QUALQUER caminho da lista aparecer em
# algum lugar do texto do comando -- mais solto que is_internal_tooling_path
# de propósito (um comando pode ter vários argumentos, redirecionamento,
# pipe; exigir que o comando inteiro comece com o caminho bloquearia
# comandos legítimos como "cd modulos/conformidade && ...", "ls -la
# .claude/hooks", "diff a b" com "a"/"b" dentro de .claude/).
command_touches_internal_tooling() {
  local comando="$1" rel
  [[ -z "$comando" ]] && return 1
  for rel in "${INTERNAL_TOOLING_PATHS[@]}"; do
    case "$comando" in
      *"$rel"*) return 0 ;;
    esac
  done
  return 1
}

# Caminhos deste módulo e do resto da ferramenta interna do projeto --
# lidos direto do bloco "Ferramentas internas de trabalho desta sessao"
# do .gitignore (mesma fonte única já usada por ensure_worktree_links
# em espírito -- nenhuma lista própria escrita aqui dentro do script,
# só uma leitura). Motivo da isenção: edição aqui nunca depende da
# leitura obrigatória do projeto hospedeiro, porque este módulo tem sua
# própria documentação e seu próprio processo de escrita, independente
# do que ele fiscaliza -- a isenção é só pra este conjunto de caminhos,
# nunca pro resto do projeto hospedeiro.
internal_tooling_paths() {
  local gitignore="${CLAUDE_PROJECT_DIR}/.gitignore"
  [[ -f "$gitignore" ]] || return 0
  awk '
    /^# Ferramentas internas de trabalho desta sessao/ { dentro=1; next }
    dentro && /^$/ { exit }
    dentro && /^\// { sub(/^\//, ""); sub(/\/$/, ""); print }
  ' "$gitignore"
}

# Um caminho de arquivo/pasta é parte da ferramenta interna acima?
# Compara prefixo, depois de normalizar barra (caminho pode chegar
# absoluto, ex. "H:/.../modulos/conformidade/x", ou relativo, ex.
# "modulos/conformidade/x" -- checa só o final relevante).
is_internal_tooling_path() {
  local caminho rel
  caminho=$(normalize_path "$1")
  [[ -z "$caminho" ]] && return 1
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    case "$caminho" in
      "$rel"|"$rel"/*|*"/${rel}"|*"/${rel}"/*) return 0 ;;
    esac
  done < <(internal_tooling_paths)
  return 1
}

# Mesma checagem, pra um comando Bash inteiro (não um único caminho) --
# usada quando a ferramenta é "Bash", em vez de "Read"/"Write"/"Edit"
# com um "file_path" só. Aceita se QUALQUER caminho da lista aparecer em
# algum lugar do texto do comando -- mais solto que is_internal_tooling_path
# de propósito (um comando pode ter vários argumentos, redirecionamento,
# pipe; exigir que o comando inteiro comece com o caminho bloquearia
# comandos legítimos como "cd modulos/conformidade && ...", "ls -la
# .claude/hooks", "diff a b" com "a"/"b" dentro de .claude/).
command_touches_internal_tooling() {
  local comando="$1" rel
  [[ -z "$comando" ]] && return 1
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    case "$comando" in
      *"$rel"*) return 0 ;;
    esac
  done < <(internal_tooling_paths)
  return 1
}

# Só as entradas de internal_tooling_paths que são pasta de verdade em
# disco -- atalho de pasta do Windows (junction) não serve pra um
# arquivo único (ex.: .claude/settings.json, também citado no mesmo
# bloco do .gitignore).
worktree_link_paths() {
  local rel
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    [[ -d "${CLAUDE_PROJECT_DIR}/${rel}" ]] && echo "$rel"
  done < <(internal_tooling_paths)
}

# Só as entradas de internal_tooling_paths que são pasta de verdade em
# disco -- atalho de pasta do Windows (junction) não serve pra um
# arquivo único (ex.: .claude/settings.json, também citado no mesmo
# bloco do .gitignore).
worktree_link_paths() {
  local rel
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    [[ -d "${CLAUDE_PROJECT_DIR}/${rel}" ]] && echo "$rel"
  done < <(internal_tooling_paths)
}

# Caminhos deste módulo e do resto da ferramenta interna do projeto --
# lidos direto do bloco "Ferramentas internas de trabalho desta sessao"
# do .gitignore (mesma fonte única já usada por ensure_worktree_links
# em espírito -- nenhuma lista própria escrita aqui dentro do script,
# só uma leitura). Motivo da isenção: edição aqui nunca depende da
# leitura obrigatória do projeto hospedeiro, porque este módulo tem sua
# própria documentação e seu próprio processo de escrita, independente
# do que ele fiscaliza -- a isenção é só pra este conjunto de caminhos,
# nunca pro resto do projeto hospedeiro.
internal_tooling_paths() {
  local gitignore="${CLAUDE_PROJECT_DIR}/.gitignore"
  [[ -f "$gitignore" ]] || return 0
  awk '
    /^# Ferramentas internas de trabalho desta sessao/ { dentro=1; next }
    dentro && /^$/ { exit }
    dentro && /^\// { sub(/^\//, ""); sub(/\/$/, ""); print }
  ' "$gitignore"
}

# Um caminho de arquivo/pasta é parte da ferramenta interna acima?
# Compara prefixo, depois de normalizar barra (caminho pode chegar
# absoluto, ex. "H:/.../modulos/conformidade/x", ou relativo, ex.
# "modulos/conformidade/x" -- checa só o final relevante).
is_internal_tooling_path() {
  local caminho rel
  caminho=$(normalize_path "$1")
  [[ -z "$caminho" ]] && return 1
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    case "$caminho" in
      "$rel"|"$rel"/*|*"/${rel}"|*"/${rel}"/*) return 0 ;;
    esac
  done < <(internal_tooling_paths)
  return 1
}

# Mesma checagem, pra um comando Bash inteiro (não um único caminho) --
# usada quando a ferramenta é "Bash", em vez de "Read"/"Write"/"Edit"
# com um "file_path" só. Aceita se QUALQUER caminho da lista aparecer em
# algum lugar do texto do comando -- mais solto que is_internal_tooling_path
# de propósito (um comando pode ter vários argumentos, redirecionamento,
# pipe; exigir que o comando inteiro comece com o caminho bloquearia
# comandos legítimos como "cd modulos/conformidade && ...", "ls -la
# .claude/hooks", "diff a b" com "a"/"b" dentro de .claude/).
command_touches_internal_tooling() {
  local comando="$1" rel
  [[ -z "$comando" ]] && return 1
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    case "$comando" in
      *"$rel"*) return 0 ;;
    esac
  done < <(internal_tooling_paths)
  return 1
}

# Cria, se ainda não existir, um atalho de pasta (junction do Windows --
# ao contrário de link simbólico, não exige privilégio de administrador
# nem Modo desenvolvedor) de cada pasta acima, dentro da worktree
# informada, apontando pra pasta real da pasta principal. Idempotente:
# não faz nada quando o link (ou uma pasta de verdade com esse nome) já
# existe ali, quando a pasta de origem nem existe, ou quando o caminho
# informado já É a pasta principal. Convertido pra caminho absoluto do
# Windows (cygpath -w) antes de repassar pro PowerShell -- caminho
# estilo Git Bash (barra normal, prefixo /h/...) não é entendido pelo
# PowerShell, que é outro processo, fora do ambiente MSYS (confirmado
# ao vivo: sem essa conversão, o PowerShell interpretava um caminho
# relativo à raiz do disco, não à pasta pretendida).
ensure_worktree_links() {
  local wt_path
  wt_path=$(normalize_path "$1")
  [[ -z "$wt_path" ]] && return 0
  paths_equal "$wt_path" "$CLAUDE_PROJECT_DIR" && return 0
  # Só cria atalho quando wt_path é, de verdade, a raiz de uma worktree
  # -- exatamente ".../.claude/worktrees/<nome>", sem nenhuma subpasta
  # depois do nome. Sem essa checagem, qualquer cwd usado num comando
  # (ex.: "cd modulos/motor && ./gradlew...", ou até "cd .claude && ...",
  # ou "cd .../worktrees/<nome>/modulos/motor && ...") era tratado como
  # se fosse uma worktree nova, plantando atalho dentro dessa subpasta
  # comum -- achado ao vivo, registrado em findings.md do módulo de
  # conformidade.
  case "$wt_path" in
    */.claude/worktrees/*/*) return 0 ;;
    */.claude/worktrees/*) ;;
    *) return 0 ;;
  esac

  local rel target link target_win link_win
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    target="${CLAUDE_PROJECT_DIR}/${rel}"
    link="${wt_path}/${rel}"
    [[ -e "$target" ]] || continue
    [[ -e "$link" ]] && continue
    target_win=$(cygpath -w "$target" 2>/dev/null) || continue
    link_win=$(cygpath -w "$link" 2>/dev/null) || continue
    powershell.exe -NoProfile -Command "New-Item -ItemType Junction -Path '${link_win}' -Target '${target_win}'" >/dev/null 2>&1
    echo "$(date -u +%FT%TZ) ${rel} -> ${target_win} (worktree ${wt_path})" >> "${STATE_DIR}/worktree-links.log"
  done < <(worktree_link_paths)
}
