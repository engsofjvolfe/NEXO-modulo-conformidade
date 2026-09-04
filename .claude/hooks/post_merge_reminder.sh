#!/bin/bash
# post_merge_reminder.sh -- evento: PostToolUse, filtro: Bash
#
# CLAUDE.md, seção "Depois de mesclar: e a produção?": depois de um
# push pra develop/main ou de um merge de PR, manter a pasta atual
# puxada (git pull origin develop) é etapa natural, sem precisar de
# pedido -- nunca presumir que já está atualizada. Não existia nenhum
# mecanismo pra isso ainda -- este hook fecha essa lacuna com um
# lembrete (PostToolUse não bloqueia nada, só acrescenta contexto,
# ver documentação oficial de hooks).

source "$(dirname "$0")/lib/common.sh"
read_input

COMMAND=$(field '.tool_input.command')

if echo "$COMMAND" | grep -Eq '\bgit[[:space:]]+push\b.*\b(develop|main)\b' || echo "$COMMAND" | grep -Eq '\bgh[[:space:]]+pr[[:space:]]+merge\b'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: "Lembrete do CLAUDE.md (secao \"Depois de mesclar: e a producao?\"): manter esta pasta sempre puxada com git pull origin develop depois de um merge -- nunca presumir que ja esta atualizada, e mesclar em develop nao coloca nada no ar sozinho."
    }
  }'
fi

exit 0
