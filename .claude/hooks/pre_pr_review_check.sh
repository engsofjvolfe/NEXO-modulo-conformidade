#!/bin/bash
# pre_pr_review_check.sh -- evento: PreToolUse, filtro: Bash(gh pr create *)
#
# Confere se a revisão de PR (skill /revisar-pr) já rodou depois da
# última edição desta tarefa -- fato mecânico (comparação de duas
# marcas de tempo), não julgamento sobre o conteúdo da revisão em si.

source "$(dirname "$0")/lib/common.sh"
read_input

COMMAND=$(field '.tool_input.command')

# Auto-portão contra falha aberta do filtro `if` (decisions/0011) --
# confirma o próprio padrão de novo, sem depender só do `if` do
# settings.json.
if ! echo "$COMMAND" | grep -Eq '\bgh[[:space:]]+pr[[:space:]]+create\b'; then
  exit 0
fi

if is_authorized; then
  log_override "pre_pr_review_check" "$(authorized_reason)"
  exit 0
fi

# Sem nenhuma edição registrada nesta sessão, não há o que revisar --
# libera sem exigir nada.
[[ -s "$EDIT_LOG" ]] || exit 0

LAST_EDIT=$(tail -n 1 "$EDIT_LOG" | awk '{print $1}')

if [[ ! -s "$PR_REVIEW_LOG" ]]; then
  block "Bloqueado: nenhuma revisão de PR (comando /revisar-pr) registrada nesta sessão -- rode /revisar-pr antes de abrir o PR. Se já revisou de outro jeito, use AUTORIZO-TRAVA: <motivo>."
fi

LAST_REVIEW=$(tail -n 1 "$PR_REVIEW_LOG" | awk '{print $1}')

if [[ "$LAST_REVIEW" < "$LAST_EDIT" ]]; then
  block "Bloqueado: a última revisão de PR (/revisar-pr) é anterior à última edição desta tarefa -- algo mudou depois da revisão. Rode /revisar-pr de novo, ou, se a mudança não afeta o que os revisores checam, use AUTORIZO-TRAVA: <motivo>."
fi

exit 0
