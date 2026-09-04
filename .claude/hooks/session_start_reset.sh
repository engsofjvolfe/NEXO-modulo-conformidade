#!/bin/bash
# session_start_reset.sh -- evento: SessionStart, sem matcher (toda sessão)
#
# Achado direto, apontado nesta sessão: os diários (edit-order.log,
# read-log.txt, partial-read-log.txt) nunca eram limpos entre uma
# sessão e outra -- só cresciam pra sempre. Além do tamanho, isso é um
# bug de verdade: o CLAUDE.md fala sempre "nesta sessão" (ex.: "não
# encontrei rastro de leitura... nesta sessão") -- um registro que
# sobrevive de uma sessão pra outra deixa uma leitura feita há dias,
# numa sessão diferente, contar como "confirmada nesta sessão nova",
# o que nunca foi a intenção do texto.
#
# Este gancho arquiva (não apaga) cada diário -- guarda o histórico,
# só tira ele do caminho das checagens -- e reinicia a síntese
# (lib/common.sh, synthesis_reset) pro estado vazio. Roda uma vez, no
# início de toda sessão nova (sem matcher -- diferente do lembrete de
# pós-compactação, que só roda quando a sessão é a mesma, só o
# contexto foi resumido).

source "$(dirname "$0")/lib/common.sh"
read_input

ARCHIVE_DIR="${STATE_DIR}/arquivo"
mkdir -p "$ARCHIVE_DIR"
CARIMBO=$(date -u +%Y%m%dT%H%M%SZ)

for arquivo in edit-order.log read-log.txt partial-read-log.txt; do
  ORIGEM="${STATE_DIR}/${arquivo}"
  if [[ -s "$ORIGEM" ]]; then
    mv "$ORIGEM" "${ARCHIVE_DIR}/${CARIMBO}-${arquivo}"
  fi
done

synthesis_reset

exit 0
