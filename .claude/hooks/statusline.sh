#!/bin/bash
# statusline.sh
#
# Uso pouco comum de um recurso feito pra outra coisa: statusLine
# existe oficialmente pra mostrar custo/contexto/modelo. Nada impede
# de usar a mesma barra, sempre visível, sem precisar apertar nada,
# pra mostrar se as regras do CLAUDE.md estão sendo seguidas AGORA --
# não só quando algo falha.

input=$(cat)
CWD=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
WORKTREE=$(echo "$input" | jq -r '.workspace.git_worktree // .worktree.name // empty')
PR_NUM=$(echo "$input" | jq -r '.pr.number // empty')
PR_STATE=$(echo "$input" | jq -r '.pr.review_state // empty')

STATE_DIR="${CLAUDE_PROJECT_DIR}/.claude/hooks/state"
OVERRIDES_LOG="${STATE_DIR}/overrides.log"
EDIT_LOG="${STATE_DIR}/edit-order.log"

RED='\033[31m'; YELLOW='\033[33m'; GREEN='\033[32m'; CYAN='\033[36m'; RESET='\033[0m'

BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)

# Segmento 1: worktree e branch
if [[ -n "$WORKTREE" ]]; then
  SEG1="${GREEN}worktree: ${WORKTREE}${RESET}"
elif [[ "$BRANCH" == "develop" || "$BRANCH" == "main" ]]; then
  SEG1="${RED}FORA de worktree, em ${BRANCH}${RESET}"
else
  SEG1="${YELLOW}branch: ${BRANCH:-?} (sem worktree nomeada)${RESET}"
fi

# Segmento 2: PR aberto, se houver
SEG2=""
if [[ -n "$PR_NUM" ]]; then
  SEG2=" | ${CYAN}PR #${PR_NUM} (${PR_STATE:-?})${RESET}"
fi

# Segmento 3: autorizações usadas na sessão (contador -- não é ruim
# existir, é ruim existir demais sem ninguém olhar o log)
SEG3=""
if [[ -f "$OVERRIDES_LOG" ]]; then
  COUNT=$(wc -l < "$OVERRIDES_LOG" | tr -d ' ')
  [[ "$COUNT" -gt 0 ]] && SEG3=" | ${YELLOW}${COUNT} autorização(ões)${RESET}"
fi

# Segmento 4: último arquivo tocado (pra ver de relance se handoff.md
# realmente foi a última coisa, sem esperar o commit pra descobrir)
SEG4=""
if [[ -f "$EDIT_LOG" ]]; then
  LAST=$(tail -n 1 "$EDIT_LOG" | awk '{print $2}')
  [[ -n "$LAST" ]] && SEG4=" | último: $(basename "$LAST")"
fi

echo -e "${SEG1}${SEG2}${SEG3}${SEG4}"
