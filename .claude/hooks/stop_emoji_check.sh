#!/bin/bash
# stop_emoji_check.sh -- evento: Stop
#
# "Nunca usar emoji" é fato puro, sem julgamento -- não precisa de uma
# segunda inteligência artificial pra decidir, só da mesma função já
# usada em outro lugar deste sistema (has_emoji, lib/common.sh) pra
# checar a mesma coisa em arquivo editado. Antes desta correção, essa
# checagem morava dentro de um gancho do tipo "prompt" (segunda
# inteligência artificial, chamada a cada resposta), junto com uma
# checagem de julgamento de verdade (termo técnico explicado) -- ver
# decisions/0026. Separado aqui: mais rápido, sem custo de chamada de
# modelo, sem risco de girar/repetir por imprecisão de julgamento
# numa checagem que não devia depender de julgamento nenhum.

source "$(dirname "$0")/lib/common.sh"
read_input

if is_authorized; then
  log_override "stop_emoji_check" "$(authorized_reason)"
  exit 0
fi

LAST_MSG=$(field '.last_assistant_message')

if [[ -n "$LAST_MSG" ]] && echo "$LAST_MSG" | has_emoji; then
  block "emoji na resposta" "a resposta final contém um emoji -- regra geral: nunca usar emojis em nada escrito neste projeto, inclusive no chat. Reescreva sem o emoji antes de terminar a resposta."
fi

exit 0
