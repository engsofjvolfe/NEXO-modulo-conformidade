#!/bin/bash
# pre_search_guard.sh -- evento: PreToolUse, matcher: "*" (toda ferramenta)
#
# CLAUDE.md, seção "Ferramentas": "Não usar [...] ferramentas de
# busca ampla (Grep, Glob, Explore) por iniciativa própria [...] Só
# usar essas ferramentas quando o usuário pedir busca/exploração [...]
# na mensagem atual." O settings.json já cobre as ferramentas nomeadas
# (Grep/Glob/Agent via permissions.ask) -- mas o mesmo efeito dá pra
# conseguir através de QUALQUER ferramenta que aceite um comando de
# texto livre (Bash, PowerShell, e qualquer outra que vier a existir
# neste projeto no futuro).
#
# Achado ao vivo, apontado diretamente nesta sessão: a primeira versão
# desta correção cobria Bash e, separado, PowerShell -- dois arquivos,
# um gatilho por nome de ferramenta. Isso é o padrão errado: sempre
# vai faltar a próxima ferramenta que também aceite comando livre.
# Correção de verdade: um gancho só, matcher "*" (cobre toda
# ferramenta, sem lista fixa de nomes -- mesmo padrão já usado em
# pre_mandatory_reading_guard.sh), que olha se ESTA chamada tem um
# campo tool_input.command (a marca de "aceita comando de texto
# livre", não o nome da ferramenta em si) -- se tiver, aplica o mesmo
# conjunto de padrões proibidos, tanto de sintaxe Unix (grep/find/sed/ls,
# usado por Bash) quanto de sintaxe PowerShell (Select-String/
# Get-ChildItem/dir), porque não há como saber de antemão qual sintaxe
# o comando vai usar sem primeiro saber a ferramenta -- checar as duas
# ao mesmo tempo é mais simples e mais completo do que decidir com
# base no nome.
#
# grep/find/sed/Select-String/Get-ChildItem -Recurse usados como busca
# de conteúdo são quase sempre um substituto de Grep/Glob -- sempre
# pedem confirmação. "ls"/"dir"/"Get-ChildItem" tem um recorte real
# permitido (CLAUDE.md, memória do projeto): confirmar que um
# arquivo/pasta específica existe é ação direta e pontual, continua
# liberado; uso recursivo, com curinga, ou de mais de um caminho, é a
# mesma varredura ampla que Glob cobriria.

source "$(dirname "$0")/lib/common.sh"
read_input

TOOL_NAME=$(field '.tool_name')
COMMAND=$(field '.tool_input.command')

# Só se aplica a ferramentas que aceitam comando de texto livre --
# identificado pelo campo em si (tool_input.command existir), não por
# uma lista fixa de nomes de ferramenta. Ferramenta sem esse campo
# (Read, Write, Edit, WebFetch, etc.) não passa por aqui.
[[ -z "$COMMAND" ]] && exit 0

if is_authorized; then
  log_override "pre_search_guard" "$(authorized_reason)"
  exit 0
fi

ESCALATE_REASON=""

if echo "$COMMAND" | grep -Eq '(^|[;&|]|\bsudo\s)\s*grep\b' || echo "$COMMAND" | grep -Eiq '\bSelect-String\b'; then
  ESCALATE_REASON="'grep'/'Select-String' usado como busca de conteúdo (via $TOOL_NAME) -- mesma proibição de Grep/Glob por iniciativa própria (CLAUDE.md, Ferramentas), qualquer que seja a ferramenta usada pra rodar o comando."
elif echo "$COMMAND" | grep -Eq '(^|[;&|]|\bsudo\s)\s*find\b' || echo "$COMMAND" | grep -Eiq '\bGet-ChildItem\b.*-Recurse\b|\bgci\b.*-Recurse\b|\bdir\b.*(/s\b|-Recurse\b)'; then
  ESCALATE_REASON="'find'/'Get-ChildItem -Recurse'/'dir /s' usado como busca ampla de arquivo (via $TOOL_NAME) -- mesma proibição de Glob por iniciativa própria (CLAUDE.md, Ferramentas), qualquer que seja a ferramenta."
elif echo "$COMMAND" | grep -Eq '(^|[;&|]|\bsudo\s)\s*sed\s+-n\b' || echo "$COMMAND" | grep -Eiq '\bGet-Content\b.*-Pattern\b'; then
  ESCALATE_REASON="'sed -n'/'Get-Content -Pattern' usado como filtro de conteúdo (via $TOOL_NAME) -- mesma proibição de Grep por iniciativa própria (CLAUDE.md, Ferramentas); pra ler um arquivo já conhecido, usar a ferramenta Read."
elif echo "$COMMAND" | grep -Eq '(^|[;&|]|\bsudo\s)\s*ls\b' || echo "$COMMAND" | grep -Eiq '(^|;)\s*(Get-ChildItem|gci|dir)\b'; then
  # "ls"/"dir"/"Get-ChildItem" simples (uma pasta, sem recursão, sem
  # curinga, sem pipe pra outro filtro) continua liberado -- só escala
  # o caso amplo. Achado ao vivo (versão anterior deste gancho): um
  # regex sem limite de palavra pra "-R" casava por engano dentro de
  # um NOME DE PASTA com hífen seguido de R (ex.: "NEXO-EMBRIOLOGIA"
  # contém "-...R..."). Corrigido pra exigir token isolado.
  if echo "$COMMAND" | grep -Eq '(^|\s)-[a-zA-Z]*[Rr][a-zA-Z]*(\s|$)' \
     || echo "$COMMAND" | grep -Eiq '\*|\?|\bRecurse\b' \
     || echo "$COMMAND" | grep -Eq '\b(ls|dir|gci|Get-ChildItem)\b[^|;&]*\|' \
     || [[ $(echo "$COMMAND" | grep -oE '\b(ls|dir|gci|Get-ChildItem)\b[^;&|]*' | wc -w) -gt 4 ]]; then
    ESCALATE_REASON="'ls'/'dir'/'Get-ChildItem' usado de forma ampla (recursivo, com curinga, ou vários caminhos, via $TOOL_NAME) -- mesma proibição de Glob por iniciativa própria (CLAUDE.md, Ferramentas). Listagem simples de uma pasta específica continua liberada."
  fi
fi

if [[ -n "$ESCALATE_REASON" ]]; then
  jq -n --arg reason "$ESCALATE_REASON" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $reason
    }
  }'
fi

exit 0
