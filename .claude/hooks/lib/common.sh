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
OVERRIDES_LOG="${STATE_DIR}/overrides.log"
EDIT_LOG="${STATE_DIR}/edit-order.log"
PREVIEW_LOG="${STATE_DIR}/preview-sessions.log"
PR_REVIEW_LOG="${STATE_DIR}/pr-review-log.txt"
SYNTHESIS_FILE="${STATE_DIR}/synthesis.json"

mkdir -p "$STATE_DIR" "$CONFIRM_DIR"

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
    block "Bloqueado: jq não está instalado -- todo hook deste projeto depende dele pra ler o JSON de entrada, e sem ele as checagens não travam nada de verdade (silêncio, não segurança). Instale jq (ver MANUAL.md, seção Instalação) antes de continuar."
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

# Lista de leitura obrigatória (CLAUDE.md, seção "Leitura obrigatória,
# fonte da verdade"). Só os 6 documentos de "LEITURA MANUAL
# OBRIGATÓRIA" entram nesta checagem -- os outros 16, importados
# automaticamente via "@caminho" no próprio CLAUDE.md, já chegam
# garantidos pelo mecanismo do Claude Code assim que a sessão começa,
# sem chamada de Read nenhuma. Checar os 16 contra o read-log.txt
# bloquearia toda sessão bem-comportada (nenhuma precisa reler algo
# que já veio automaticamente) -- só os 6 manuais existem justamente
# porque o auto-import falha pra eles (espaço no nome do arquivo, ver
# TASKS.md), então só eles exigem um Read explícito de verdade.
#
# Função compartilhada porque o Portão pro Passo 2 do fluxo completo
# ("nenhuma linha de código escrita antes disso, e a leitura
# obrigatória já feita de verdade") exige essa checagem ANTES da
# primeira edição, não só no commit -- antes, só pre_commit_hygiene.sh
# conferia isso, tarde demais (dava pra editar dezenas de arquivos sem
# nunca ter lido nada).
MANUAL_MANDATORY_DOCS=(
  "1 - documento-de-conceito-geral.md"
  "2 - requisitos-conceito-geral.md"
  "3 - especificacao-conceito-geral.md"
  "4 - projeto-arquitetonico.md"
  "5 - projeto-detalhado.md"
  "prompt model.txt"
)

# Janela de frescor (em número de ações da ficha) só dos seis
# documentos de leitura manual obrigatória -- diferente da janela de
# pre_edit_safety.sh (citação de documento, ainda 20 ações). As duas
# eram a mesma constante (20) até esta rodada; separadas porque o
# julgamento por trás de cada uma é diferente: citar um documento por
# nome é um evento pontual, vale checar bem de perto; já ter lido os
# seis documentos manuais é uma condição de fundo, que precisa
# aguentar uma sessão inteira de trabalho -- inclusive um recarregamento
# de contexto no meio do caminho (evento "resume" do Claude Code), que
# não é decisão de ninguém, só o jeito como a ferramenta funciona por
# trás das cenas. Valor bem maior (pedido explícito: "pra bastante
# tempo") pra que isso não expire à toa no meio de uma sessão longa.
# Ver decisions/0015.
MANDATORY_READ_FRESHNESS_WINDOW=500

# Devolve, por stdout, o primeiro documento de leitura manual
# obrigatória ainda sem rastro de leitura *fresca* (dentro da janela
# acima) nesta sessão. Consulta a ficha (síntese), nunca relendo o
# diário inteiro. Vazio se todos os seis foram lidos, e de forma
# fresca.
#
# Antes, esta checagem usava synthesis_age sem limite -- uma leitura
# feita uma vez, há muitas ações atrás, contava como "lido" pro resto
# da sessão inteira. Corrigido: nenhuma leitura vale "pra sempre" --
# a pergunta certa é sempre "li de fresco o bastante pra confiar
# agora?", o mesmo princípio que já valia só pra citação de documento
# (pre_edit_safety.sh #4). Os seis documentos manuais deixam de ser
# exceção -- perdem a permanência que tinham antes, mesma janela do
# resto do sistema. Ver decisions/0013.
first_unread_mandatory_doc() {
  for doc in "${MANUAL_MANDATORY_DOCS[@]}"; do
    if ! synthesis_fresh "leitura.${doc}" "$MANDATORY_READ_FRESHNESS_WINDOW"; then
      echo "$doc"
      return 0
    fi
  done
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

# Bloqueia a ação atual com uma mensagem explicando o porquê.
block() {
  echo "$1" >&2
  exit 2
}

# Pastas locais deste projeto -- fora do controle de versão, ver
# .gitignore -- que uma worktree nova precisa enxergar pra funcionar de
# verdade: as definições dos quatro agentes de revisão de PR
# (.claude/agents), os próprios scripts de gancho e seu estado
# compartilhado (.claude/hooks) e a documentação do módulo de
# conformidade (modulos/conformidade). "git worktree add" só traz
# conteúdo versionado -- nenhuma das três chega numa worktree nova
# sozinha. Achado ao vivo: mesmo assim, os ganchos do evento Stop
# configurados em .claude/settings.json (só existe na pasta principal)
# disparavam normalmente de dentro de uma worktree sem nenhuma dessas
# pastas -- confirmando que ${CLAUDE_PROJECT_DIR} já resolve pra pasta
# principal em qualquer worktree; o problema real é mais estreito:
# só os caminhos usados sem esse prefixo (referência relativa dentro
# do próprio texto de um gancho, ex.: "cat .claude/hooks/state/...",
# e a lista de agentes nomeados que o Claude Code carrega olhando a
# pasta atual, não CLAUDE_PROJECT_DIR) ficavam sem efeito numa
# worktree. Ver modulos/conformidade/decisions/0021.
WORKTREE_LINK_PATHS=(".claude/agents" ".claude/hooks" "modulos/conformidade")

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
  for rel in "${WORKTREE_LINK_PATHS[@]}"; do
    target="${CLAUDE_PROJECT_DIR}/${rel}"
    link="${wt_path}/${rel}"
    [[ -e "$target" ]] || continue
    [[ -e "$link" ]] && continue
    target_win=$(cygpath -w "$target" 2>/dev/null) || continue
    link_win=$(cygpath -w "$link" 2>/dev/null) || continue
    powershell.exe -NoProfile -Command "New-Item -ItemType Junction -Path '${link_win}' -Target '${target_win}'" >/dev/null 2>&1
    echo "$(date -u +%FT%TZ) ${rel} -> ${target_win} (worktree ${wt_path})" >> "${STATE_DIR}/worktree-links.log"
  done
}
