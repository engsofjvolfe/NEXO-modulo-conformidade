#!/bin/bash
# post_preview_track.sh -- evento: PostToolUse
# filtro: Bash(*preview-up.sh*) e Bash(*preview-down.sh*)
#
# ATENÇÃO -- limite honesto: isto NÃO prova que o teste funcionou.
# O CLAUDE.md deste projeto não define qual sinal significa "testado
# com sucesso" (a seção "Como rodar o preview isolado" está em
# branco no documento original). Sem essa definição, não existe
# evidência automática de sucesso pra capturar -- só dá pra registrar
# que o ambiente subiu e desceu, como sinal fraco de que algo
# aconteceu. A pergunta de verdade ("funcionou mesmo?") fica pro
# revisor perguntar explicitamente a você, nunca decidida sozinha.

source "$(dirname "$0")/lib/common.sh"
read_input

COMMAND=$(field '.tool_input.command')
EXIT_CODE=$(field '.tool_response.exit_code')

echo "$(date -u +%FT%TZ) cmd=[$COMMAND] exit=[${EXIT_CODE:-desconhecido}]" >> "$PREVIEW_LOG"

exit 0
