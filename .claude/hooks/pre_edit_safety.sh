#!/bin/bash
# pre_edit_safety.sh -- evento: PreToolUse, filtro: Write|Edit

source "$(dirname "$0")/lib/common.sh"
read_input

TOOL_NAME=$(field '.tool_name')
FILE_PATH=$(normalize_path "$(field '.tool_input.file_path')")
CWD=$(normalize_path "$(field '.cwd')")
TRANSCRIPT=$(field '.transcript_path')

# Janela de frescor (em número de ações da ficha) -- quantas ações
# atrás uma leitura ainda conta como "de fresco". Usada por vários
# itens abaixo (1, 4, 5, 6, 7, 8), não só o item 4 como antes -- mesmo
# princípio geral: nenhuma leitura vale "pra sempre", a pergunta é
# sempre "li de fresco o bastante pra confiar agora?". Ver
# modulos/conformidade/decisions/0013.
RECENCY_WINDOW=20

if is_authorized; then
  log_override "pre_edit_safety" "$(authorized_reason)"
  exit 0
fi

# 1) Reler antes de editar (não se aplica a Write de arquivo novo).
# Consulta a ficha (síntese, lib/common.sh) -- agora exigindo leitura
# *fresca* (dentro da janela acima), não só "leu alguma vez nesta
# sessão". Antes, um Read feito há muitas ações, com o arquivo já
# mudado de memória por outra coisa lida ou escrita depois, ainda
# contava como "lido" -- mesmo problema geral que motivou esta rodada
# inteira (nenhuma leitura vale pra sempre). Duas mensagens distintas:
# nunca lido (mais grave, sem rastro nenhum) e lido mas desatualizado
# (já leu, só precisa confirmar de novo) -- mesmo padrão já usado no
# item 4.
if [[ "$TOOL_NAME" == "Edit" && -n "$FILE_PATH" ]]; then
  if ! synthesis_fresh "leitura.${FILE_PATH}" "$RECENCY_WINDOW"; then
    if [[ -n "$(synthesis_age "leitura.${FILE_PATH}")" ]]; then
      block "Bloqueado: $FILE_PATH foi lido nesta sessão, mas não entre as últimas $RECENCY_WINDOW ações -- pode estar desatualizado na memória. Releia antes de editar, ou use AUTORIZO-TRAVA: <motivo>."
    else
      block "Bloqueado: não encontrei rastro de que $FILE_PATH foi lido (via Read) nesta sessão antes desta edição. Se já leu de outro jeito, use AUTORIZO-TRAVA: <motivo>."
    fi
  fi
fi

# 2) Escrever fora de uma worktree
if [[ -n "$FILE_PATH" && "$CWD" != *"/.claude/worktrees/"* && "$FILE_PATH" != *"/.claude/"* ]]; then
  block "Bloqueado: escrita fora de uma worktree própria. Se isso for intencional, use AUTORIZO-TRAVA: <motivo>."
fi

# 3) Leitura manual obrigatória antes de qualquer código -- Portão pro
# Passo 2 do "Fluxo completo de uma tarefa": "nenhuma linha de código
# escrita antes disso, e a leitura obrigatória já feita de verdade".
# Só os 6 documentos de leitura manual entram aqui (ver lib/common.sh,
# first_unread_mandatory_doc, que agora também exige frescor -- mesma
# janela acima, ver decisions/0013).
UNREAD_DOC=$(first_unread_mandatory_doc)
if [[ -n "$UNREAD_DOC" ]]; then
  block "Bloqueado: leitura manual obrigatória ainda não feita ou desatualizada ('$UNREAD_DOC') -- nenhum código antes disso (CLAUDE.md, Portão pro Passo 2). Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
fi

# 4) Não concluir a partir do que já chegou carregado -- CLAUDE.md,
# topo do documento: "confirmar antes de escrever a correção", não
# depois. Se o texto novo cita outro documento .md (por nome, não a
# própria edição em si), esse documento precisa ter sido lido por
# completo (via Read) nesta sessão, dentro da janela de frescor acima
# -- não em qualquer ponto do histórico da sessão inteira. Heurística,
# com falso positivo possível (citar um nome não é sempre "depender"
# da convenção dele) -- por isso autorizável.
NEW_CONTENT=""
if [[ "$TOOL_NAME" == "Write" ]]; then
  NEW_CONTENT=$(field '.tool_input.content')
elif [[ "$TOOL_NAME" == "Edit" ]]; then
  NEW_CONTENT=$(field '.tool_input.new_string')
fi
if [[ -n "$NEW_CONTENT" ]]; then
  CITED_FILES=$(echo "$NEW_CONTENT" | grep -oE '[A-Za-z0-9_./-]+\.md' | sort -u)
  SELF_BASENAME=$(basename "$FILE_PATH" 2>/dev/null)
  for cited in $CITED_FILES; do
    cited_base=$(basename "$cited")
    [[ "$cited_base" == "$SELF_BASENAME" ]] && continue
    if ! synthesis_fresh "leitura.${cited_base}" "$RECENCY_WINDOW"; then
      if [[ -n "$(synthesis_age "leitura.${cited_base}")" ]]; then
        block "Bloqueado: este texto cita '$cited', que já foi lido nesta sessão, mas não entre as últimas $RECENCY_WINDOW ações -- pode estar desatualizado na memória, não confirmado agora. CLAUDE.md, topo: 'não concluir... a partir do que já chegou carregado, confirmar antes de escrever a correção'. Releia '$cited' de novo antes, ou use AUTORIZO-TRAVA: <motivo>."
      else
        block "Bloqueado: este texto cita '$cited' mas não encontrei rastro de leitura completa (via Read) dele nesta sessão -- CLAUDE.md, topo: 'não concluir... a partir do que já chegou carregado, confirmar antes de escrever a correção'. Releia '$cited' antes, ou, se já leu de outro jeito (ou a citação não depende do conteúdo dele), use AUTORIZO-TRAVA: <motivo>."
      fi
    fi
  done
fi

# 5) Ordem completa concept.md -> architecture.md -> schemas/ ->
# implementação, no momento da própria edição -- não só no commit.
# Trocado de "documento anterior foi EDITADO nesta sessão" (edicao.*)
# pra "documento anterior foi LIDO DE FRESCO nesta sessão"
# (synthesis_fresh sobre leitura.<basename>) -- o que garante a ordem
# certa não é ter tocado no documento antes, é ter o conteúdo atual
# dele na cabeça no momento de derivar o passo seguinte. Mesma
# limitação de basename já aceita no item 4 (dois módulos com
# concept.md não se distinguem por esse fato -- heurística, não fato
# exato, mas suficiente pro caso real de uma sessão trabalhando num
# módulo por vez).
if [[ -n "$FILE_PATH" && "$FILE_PATH" == *"/modulos/"* ]]; then
  MOD=$(echo "$FILE_PATH" | sed -E 's#.*/modulos/([^/]+)/.*#\1#')
  if [[ "$MOD" != "_template" ]]; then
    PREFIX="${FILE_PATH%%/modulos/*}"
    MODDIR="$PREFIX/modulos/$MOD"
    IS_ARCH=false; [[ "$FILE_PATH" == *"modulos/$MOD/docs/architecture.md" ]] && IS_ARCH=true
    IS_SCHEMA=false; [[ "$FILE_PATH" == *"modulos/$MOD/schemas/"* ]] && IS_SCHEMA=true
    IS_DECISION=false; [[ "$FILE_PATH" == *"modulos/$MOD/decisions/"*".md" ]] && IS_DECISION=true
    IS_CODE=false; [[ "$FILE_PATH" == *"modulos/$MOD/"* && "$FILE_PATH" != *"/docs/"* && "$FILE_PATH" != *"/schemas/"* && "$FILE_PATH" != *"/decisions/"* ]] && IS_CODE=true

    if $IS_ARCH && ! synthesis_fresh "leitura.concept.md" "$RECENCY_WINDOW"; then
      block "Bloqueado: tentando editar architecture.md em $MOD sem leitura fresca de concept.md nesta sessão -- CLAUDE.md, ordem completa (concept.md -> architecture.md -> schemas/ -> implementação). Releia concept.md antes, ou use AUTORIZO-TRAVA: <motivo>."
    fi
    if $IS_SCHEMA && ! synthesis_fresh "leitura.architecture.md" "$RECENCY_WINDOW"; then
      block "Bloqueado: tentando editar schemas/ em $MOD sem leitura fresca de architecture.md nesta sessão. Releia architecture.md antes, ou use AUTORIZO-TRAVA: <motivo>."
    fi
    # Código aceita architecture.md OU algum arquivo de schemas/ como
    # "documento anterior" -- nem todo módulo tem pasta schemas/ (ex.:
    # conformidade, sem contrato de dado próprio), então exigir as duas
    # coisas sempre bloquearia módulo sem schemas/ sem necessidade.
    # Mesma lógica "ou" que a checagem antiga (edicao.*) já usava, só
    # trocando o fato de "foi editado" pra "foi lido de fresco".
    # synthesis_any_fresh_with_prefix (lib/common.sh) cobre schemas/
    # porque o nome do arquivo lá dentro não é fixo -- não dá pra usar
    # synthesis_fresh com uma chave única.
    if $IS_CODE && ! synthesis_fresh "leitura.architecture.md" "$RECENCY_WINDOW" \
       && ! synthesis_any_fresh_with_prefix "leitura.${MODDIR}/schemas/" "$RECENCY_WINDOW"; then
      block "Bloqueado: tentando editar implementação em $MOD sem leitura fresca de architecture.md, nem de nenhum arquivo em schemas/, nesta sessão. Releia um dos dois antes, ou use AUTORIZO-TRAVA: <motivo>."
    fi

    # Caso novo: escrever uma ADR em decisions/ exige leitura fresca de
    # concept.md e architecture.md desse módulo -- a decisão precisa
    # estar embasada no desenho atual, não em memória antiga. Pula a
    # exigência se o módulo ainda não existir em disco (módulo novo,
    # sem concept.md/architecture.md pra reler ainda).
    if $IS_DECISION && [[ -d "$MODDIR" ]]; then
      CONCEPT_PATH="$MODDIR/docs/concept.md"
      ARCH_PATH="$MODDIR/docs/architecture.md"
      if [[ -f "$CONCEPT_PATH" ]] && ! synthesis_fresh "leitura.${CONCEPT_PATH}" "$RECENCY_WINDOW"; then
        block "Bloqueado: escrevendo uma ADR em $MOD/decisions/ sem leitura fresca de $CONCEPT_PATH nesta sessão. Releia antes, ou use AUTORIZO-TRAVA: <motivo>."
      fi
      if [[ -f "$ARCH_PATH" ]] && ! synthesis_fresh "leitura.${ARCH_PATH}" "$RECENCY_WINDOW"; then
        block "Bloqueado: escrevendo uma ADR em $MOD/decisions/ sem leitura fresca de $ARCH_PATH nesta sessão. Releia antes, ou use AUTORIZO-TRAVA: <motivo>."
      fi
    fi
  fi
fi

# 6) handoff.md sempre a última coisa tocada no módulo -- mantém a
# checagem de ORDEM que já existia (handoff.md já tocado bloqueia
# outra edição em docs/ depois dele -- isso é sobre "também foi
# escrito", fato diferente de frescor de leitura). Acrescenta, além
# disso: escrever no próprio handoff.md exige leitura fresca dele
# primeiro (documento envolvido nesta edição específica) -- handoff.md
# só aponta pro estado atual; sobrescrever sem reler arrisca apagar um
# ponteiro que ainda vale.
if [[ -n "$FILE_PATH" && "$FILE_PATH" == *"/modulos/"*"/docs/"* && "$FILE_PATH" != *"/docs/handoff.md" ]]; then
  MOD2=$(echo "$FILE_PATH" | sed -E 's#.*/modulos/([^/]+)/docs/.*#\1#')
  if [[ "$MOD2" != "_template" && -n "$(synthesis_age "edicao.${MOD2}.handoff")" ]]; then
    block "Bloqueado: handoff.md de $MOD2 já foi tocado nesta sessão -- CLAUDE.md: 'handoff.md é sempre a última coisa tocada dentro do módulo'. Se precisar editar mais algo em docs/, isso deveria vir antes de handoff.md. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
  fi
fi
if [[ -n "$FILE_PATH" && "$FILE_PATH" == *"/modulos/"*"/docs/handoff.md" && -f "$FILE_PATH" ]]; then
  if ! synthesis_fresh "leitura.${FILE_PATH}" "$RECENCY_WINDOW"; then
    block "Bloqueado: escrevendo handoff.md sem leitura fresca dele nesta sessão -- confirme o estado atual antes de sobrescrever. Releia $FILE_PATH antes, ou use AUTORIZO-TRAVA: <motivo>."
  fi
fi

# 7) Módulo novo sem linha em modulos/README.md -- mantém a checagem
# de ORDEM que já existia. Acrescenta: escrever no próprio
# modulos/README.md exige leitura fresca dele primeiro (documento
# envolvido) -- confirma a tabela atual antes de editar por cima dela.
if [[ -n "$FILE_PATH" && "$FILE_PATH" == *"/modulos/"* && "$FILE_PATH" != *"/modulos/README.md" ]]; then
  MOD3=$(echo "$FILE_PATH" | sed -E 's#.*/modulos/([^/]+)/.*#\1#')
  if [[ "$MOD3" != "_template" && -n "$MOD3" ]]; then
    CONCEPT_EXISTS_BEFORE=false
    [[ -n "$(synthesis_age "edicao.${MOD3}.concept")" ]] && CONCEPT_EXISTS_BEFORE=true
    IS_NEW_CONCEPT_WRITE=false
    [[ "$TOOL_NAME" == "Write" && "$FILE_PATH" == *"modulos/$MOD3/docs/concept.md" ]] && IS_NEW_CONCEPT_WRITE=true
    README_TOUCHED=false
    [[ -n "$(synthesis_age "edicao.modulos-readme")" ]] && README_TOUCHED=true
    if ( $CONCEPT_EXISTS_BEFORE || $IS_NEW_CONCEPT_WRITE ) && ! $README_TOUCHED; then
      # Só é "módulo novo" de verdade se a pasta não existia antes desta sessão
      if [[ ! -d "${CWD%.claude/worktrees/*}modulos/$MOD3" ]] || $IS_NEW_CONCEPT_WRITE; then
        block "Bloqueado: módulo '$MOD3' parece novo (concept.md criado nesta sessão) mas modulos/README.md ainda não foi tocado -- CLAUDE.md: módulo novo precisa de linha na tabela antes de continuar. Se isso for engano (módulo já existia antes), use AUTORIZO-TRAVA: <motivo>."
      fi
    fi
  fi
fi
if [[ -n "$FILE_PATH" && "$FILE_PATH" == *"/modulos/README.md" && -f "$FILE_PATH" ]]; then
  if ! synthesis_fresh "leitura.${FILE_PATH}" "$RECENCY_WINDOW"; then
    block "Bloqueado: escrevendo modulos/README.md sem leitura fresca dele nesta sessão -- confirme a tabela atual antes de acrescentar linha. Releia $FILE_PATH antes, ou use AUTORIZO-TRAVA: <motivo>."
  fi
fi

# 8) tasks.md de módulo mudando de "Em aberto" vazia pra não-vazia (ou
# o contrário) sem TASKS.md (raiz) acompanhar -- mantém a checagem de
# ORDEM que já existia. Acrescenta: escrever no próprio TASKS.md
# (raiz) exige leitura fresca dele primeiro (documento envolvido) --
# confirma a lista atual de pendências antes de editar por cima dela.
if [[ -n "$FILE_PATH" && "$FILE_PATH" == *"/modulos/"*"/docs/tasks.md" ]]; then
  OLD_HAS_ITEM=false
  NEW_HAS_ITEM=false
  if [[ "$TOOL_NAME" == "Write" ]]; then
    [[ -f "$FILE_PATH" ]] && OLD_SECTION=$(awk '/^## Em aberto/{flag=1;next}/^## /{flag=0}flag' "$FILE_PATH" 2>/dev/null)
    echo "$OLD_SECTION" | grep -q '^- \[ \]' && OLD_HAS_ITEM=true
    NEW_CONTENT_W=$(field '.tool_input.content')
    NEW_SECTION=$(echo "$NEW_CONTENT_W" | awk '/^## Em aberto/{flag=1;next}/^## /{flag=0}flag')
    echo "$NEW_SECTION" | grep -q '^- \[ \]' && NEW_HAS_ITEM=true
  elif [[ "$TOOL_NAME" == "Edit" ]]; then
    OLD_STRING=$(field '.tool_input.old_string')
    NEW_STRING=$(field '.tool_input.new_string')
    echo "$OLD_STRING" | grep -q '^- \[ \]' && OLD_HAS_ITEM=true
    echo "$NEW_STRING" | grep -q '^- \[ \]' && NEW_HAS_ITEM=true
  fi
  if [[ "$OLD_HAS_ITEM" != "$NEW_HAS_ITEM" ]] && [[ -z "$(synthesis_age "edicao.tasks-raiz")" ]]; then
    block "Bloqueado: esta edição parece mudar se $FILE_PATH tem pendência aberta (item '- [ ]' aparecendo ou sumindo), mas TASKS.md (raiz) ainda não foi tocado nesta sessão. Se isso for engano (o item '- [ ]' na edição não é sobre a seção 'Em aberto'), use AUTORIZO-TRAVA: <motivo>."
  fi
fi
if [[ -n "$FILE_PATH" && "$FILE_PATH" == *"/TASKS.md" && "$FILE_PATH" != *"/modulos/"* && -f "$FILE_PATH" ]]; then
  if ! synthesis_fresh "leitura.${FILE_PATH}" "$RECENCY_WINDOW"; then
    block "Bloqueado: escrevendo TASKS.md (raiz) sem leitura fresca dele nesta sessão -- confirme a lista atual de pendências antes de editar. Releia $FILE_PATH antes, ou use AUTORIZO-TRAVA: <motivo>."
  fi
fi

# Fragmento de texto novo desta edição -- reaproveita o mesmo cálculo
# do item 4 acima (Write -> content inteiro; Edit -> só new_string,
# porque no momento do PreToolUse o arquivo em disco ainda tem o
# conteúdo ANTIGO -- não dá pra reconstruir o arquivo novo inteiro
# aqui, mesma limitação já aceita no item 4).
NEW_FRAGMENT="$NEW_CONTENT"

# 9) Nunca usar emoji em nada escrito no projeto.
if [[ -n "$NEW_FRAGMENT" ]] && echo "$NEW_FRAGMENT" | has_emoji; then
  block "Bloqueado: encontrei um emoji neste texto -- CLAUDE.md, Regras gerais: 'nunca usar emojis em nada escrito neste projeto (código, docs, commits, chat)'. Sem exceção, não é autorizável."
fi

# 10) Pureza de esquema de dado (sem campo description/example).
if [[ -n "$NEW_FRAGMENT" ]]; then
  if [[ "$FILE_PATH" == *"/schemas/"*".json" ]]; then
    if echo "$NEW_FRAGMENT" | grep -Eq '"description"|"example"'; then
      block "Bloqueado: este esquema tem campo 'description' ou 'example' -- CLAUDE.md, Regras gerais: esquema de dado carrega só dado puro. Sem exceção, não é autorizável."
    fi
  elif [[ "$FILE_PATH" == *.md ]]; then
    if echo "$NEW_FRAGMENT" | schema_block_impure; then
      block "Bloqueado: este texto tem um bloco de esquema embutido (\`\`\`yaml ou \`\`\`json) com campo 'description' ou 'example' -- CLAUDE.md, Regras gerais: esquema de dado carrega só dado puro, mesmo embutido num documento. Sem exceção, não é autorizável."
    fi
  fi
fi

# 11) Linha de Licença em tabela de cabeçalho ("Campo | Valor").
if [[ -n "$NEW_FRAGMENT" && "$FILE_PATH" == *.md ]]; then
  if echo "$NEW_FRAGMENT" | grep -qE '^\s*\|?\s*Campo\s*\|\s*Valor' && ! echo "$NEW_FRAGMENT" | grep -qi 'Licen'; then
    block "Bloqueado: este texto cria/reescreve uma tabela de cabeçalho ('Campo | Valor') sem linha de Licença -- CLAUDE.md, Regras gerais. Se não for cabível pra este documento, use AUTORIZO-TRAVA: <motivo>."
  fi
fi

# 12) "Antes e depois" em documento nunca versionado.
if [[ -n "$NEW_FRAGMENT" && "$FILE_PATH" == *.md ]] && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  HAS_HISTORY=$(git -C "$CWD" log --oneline -- "$FILE_PATH" 2>/dev/null | head -n 1)
  if [[ -z "$HAS_HISTORY" ]] && echo "$NEW_FRAGMENT" | grep -Eiq 'era assim|ficou assim|antes:|anteriormente era|mudou de.*para'; then
    block "Bloqueado: $FILE_PATH nunca foi versionado (sem commit no histórico) e este texto usa linguagem de 'antes e depois' -- CLAUDE.md, Regras gerais: o que está sendo implementado e nunca foi versionado não entra como correção. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
  fi
fi

# 13) Achado sem registro -- lacuna real: até aqui, pitfalls.md e
# findings.md só eram checados por julgamento de IA no momento do
# commit (pre_commit_hygiene.sh), sem nenhuma trava mecânica no
# momento da própria edição, diferente do resto do fluxo. Editar
# código (não docs/, não schemas/, não decisions/) dentro de
# modulos/<mod>/ sem que pitfalls.md nem findings.md desse módulo
# tenham sido tocados nesta sessão nem uma vez sinaliza -- decidir se
# a implementação revelou um achado ou uma armadilha é julgamento de
# quem desenvolve, não fato mecânico, então isto nunca destrava
# sozinho. Duas formas de resolver: escrever a entrada correspondente
# antes, ou confirmar explicitamente que não há nada a registrar (a
# frase abaixo, mais estreita que AUTORIZO-TRAVA -- só libera este
# item, não o resto do gancho) ou, se for mesmo engano, AUTORIZO-TRAVA.
if [[ -n "$FILE_PATH" && "$FILE_PATH" == *"/modulos/"* ]]; then
  MOD13=$(echo "$FILE_PATH" | sed -E 's#.*/modulos/([^/]+)/.*#\1#')
  IS_CODE13=false
  [[ "$FILE_PATH" == *"/modulos/$MOD13/"* && "$FILE_PATH" != *"/docs/"* && "$FILE_PATH" != *"/schemas/"* && "$FILE_PATH" != *"/decisions/"* ]] && IS_CODE13=true
  if [[ "$MOD13" != "_template" ]] && $IS_CODE13 && ! no_finding_confirmed; then
    if [[ -z "$(synthesis_age "edicao.${MOD13}.pitfalls")" && -z "$(synthesis_age "edicao.${MOD13}.findings")" ]]; then
      block "Sinalizado: editando código em $MOD13 sem que pitfalls.md nem findings.md desse módulo tenham sido tocados nesta sessão -- confirme se a implementação revelou algum achado ou armadilha de ferramenta. Se revelou, registre antes de continuar; se não revelou nada, responda com a frase exata 'nada a registrar, confirmado'; se isso for engano, use AUTORIZO-TRAVA: <motivo>."
    fi
  fi
fi

# 14/15) Escolha sem ADR -- mesma lacuna do item 13, mesmo motivo:
# decisions/ só era checado por julgamento de IA no commit. Editar
# modulos/<mod>/docs/ ou modulos/<mod>/schemas/ sem nenhuma ADR nova
# em modulos/<mod>/decisions/ nesta sessão sinaliza -- decidir se a
# mudança envolveu escolha real entre alternativas é julgamento, nunca
# decidido sozinho aqui. Confirma com "sem alternativas reais,
# confirmado" (mais estreita, só libera este item) ou AUTORIZO-TRAVA.
if [[ -n "$FILE_PATH" && "$FILE_PATH" == *"/modulos/"* ]]; then
  MOD1415=$(echo "$FILE_PATH" | sed -E 's#.*/modulos/([^/]+)/.*#\1#')
  IS_DOCS1415=false; [[ "$FILE_PATH" == *"/modulos/$MOD1415/docs/"* ]] && IS_DOCS1415=true
  IS_SCHEMA1415=false; [[ "$FILE_PATH" == *"/modulos/$MOD1415/schemas/"* ]] && IS_SCHEMA1415=true
  if [[ "$MOD1415" != "_template" ]] && ( $IS_DOCS1415 || $IS_SCHEMA1415 ) && ! no_adr_confirmed; then
    if [[ -z "$(synthesis_age "edicao.${MOD1415}.decisions")" ]]; then
      SUBPASTA=${FILE_PATH#*"/modulos/$MOD1415/"}
      block "Sinalizado: editando $SUBPASTA em $MOD1415 sem nenhuma ADR nova em modulos/$MOD1415/decisions/ nesta sessão -- confirme se esta mudança envolveu escolher entre alternativas reais. Se envolveu, escreva a ADR antes de continuar; se não envolveu, responda com a frase exata 'sem alternativas reais, confirmado'; se isso for engano, use AUTORIZO-TRAVA: <motivo>."
    fi
  fi
fi

# 16) Tom pessoal em documento (exceto o arquivo de investigação de
# cada módulo) -- CLAUDE.md/modulos/README.md: "Tom impessoal... nunca
# 'o usuário pediu/relatou X'". Antes, só um gancho do tipo "agent"
# (uma segunda inteligência artificial, chamada à parte) julgava isso,
# no momento da edição -- lacuna real: essa segunda IA usava um
# formato de resposta que o Claude Code não reconhece pra bloquear de
# verdade nesse tipo de gancho (confirmado lendo a documentação
# oficial: um gancho "agent" só entende resposta no formato
# {"ok": true/false}, nunca o formato "permissionDecision" que ela
# usava) -- na prática, nunca travava. Substituído por checagem
# mecânica de palavra-chave (sinal, não certeza -- por isso
# autorizável) mais confirmação sua, mesmo padrão dos itens 13/14/15:
# nunca decidido por mim sozinho.
if [[ -n "$NEW_FRAGMENT" && "$FILE_PATH" == *.md && "$FILE_PATH" != *"/docs/analysis"* ]]; then
  if echo "$NEW_FRAGMENT" | grep -Eiq '\b(o usu[aá]rio pediu|o usu[aá]rio relatou|o dono pediu|decidimos|resolvemos|n[oó]s decidimos|achei que|eu escolhi|pedi pra)\b' && ! confirmation_confirmed "tom-impessoal"; then
    block "Sinalizado: este texto parece usar tom pessoal ('o usuário pediu', 'decidimos', etc.) em vez de fato direto -- CLAUDE.md/modulos/README.md: tom impessoal em todo documento, exceto o arquivo de investigação. Pode ser falso positivo (a palavra aparece sem ser nesse sentido). Se for violação de verdade, reescreva antes de continuar; se não for, responda com a frase exata 'tom impessoal confirmado, sem violacao'; se isso for engano de outro tipo, use AUTORIZO-TRAVA: <motivo>."
  fi
fi

# 17) O arquivo de fechamento do módulo só aponta -- CLAUDE.md/
# modulos/README.md: "link markdown de verdade + uma frase curta,
# nunca uma descrição do que o conteúdo diz". Mesma lacuna do item 16
# (antes só a segunda IA julgava, sem travar de verdade). Heurística
# mecânica: uma linha desse arquivo sem nenhum link markdown, mas
# comprida o bastante pra parecer descrição/explicação em vez de
# ponteiro, sinaliza -- sinal, não certeza (por isso autorizável),
# confirmação sua decide, nunca eu sozinho.
if [[ -n "$NEW_FRAGMENT" && "$FILE_PATH" == *"/docs/handoff"* ]]; then
  LINHA_SEM_LINK=$(echo "$NEW_FRAGMENT" | grep -E '^- ' | grep -Ev '\]\(' | awk 'length > 200')
  if [[ -n "$LINHA_SEM_LINK" ]] && ! confirmation_confirmed "sem-duplicacao"; then
    block "Sinalizado: o arquivo de fechamento do módulo parece ter uma linha longa sem link markdown -- CLAUDE.md/modulos/README.md: esse arquivo só aponta (link + frase curta), nunca descreve o que outro documento já diz. Pode ser falso positivo. Se for duplicação de verdade, corrija pra virar ponteiro; se não for, responda com a frase exata 'sem duplicacao de conteudo, confirmado'; se isso for engano de outro tipo, use AUTORIZO-TRAVA: <motivo>."
  fi
fi

exit 0
