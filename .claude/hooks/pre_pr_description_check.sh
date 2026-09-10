#!/bin/bash
# pre_pr_description_check.sh -- evento: PreToolUse, filtro: Bash(gh pr create *)
#
# Confere se o corpo do PR (o texto passado em --body/--body-file no
# comando "gh pr create") segue o modelo do projeto
# (.github/pull_request_template.md): quatro seções, sempre nesta
# ordem -- "## O que muda", "## Por quê", "## Como testar" e
# "## Checklist do fluxo de documentação". Fato mecânico (o título da
# seção existe no texto, sim ou não), não julgamento sobre o
# conteúdo de cada seção.
#
# Não confere --body-file (aponta pra um arquivo em disco, fora do
# texto do próprio comando) -- limite conhecido, registrado em
# findings.md.

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
  log_override "pre_pr_description_check" "$(authorized_reason)"
  exit 0
fi

if ! echo "$COMMAND" | grep -Eq '\-\-body\b'; then
  exit 0
fi

REQUIRED_HEADINGS=(
  "## O que muda"
  "## Por quê"
  "## Como testar"
  "## Checklist do fluxo de documentação"
)

for heading in "${REQUIRED_HEADINGS[@]}"; do
  if ! echo "$COMMAND" | grep -qF -- "$heading"; then
    block "corpo do PR fora do modelo" "o corpo do PR não segue o modelo do projeto (.github/pull_request_template.md) -- falta a seção '$heading'. Reescreva o corpo com as quatro seções na ordem certa (O que muda, Por quê, Como testar, Checklist do fluxo de documentação). Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
  fi
done

exit 0
