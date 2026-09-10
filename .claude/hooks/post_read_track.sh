#!/bin/bash
# post_read_track.sh -- evento: PostToolUse, matcher: Read
#
# Em vez de vasculhar o arquivo de transcript inteiro atrás de "Read"
# perto de um caminho, este hook grava um registro limpo, próprio,
# toda vez que a ferramenta Read é usada de verdade. As checagens de
# leitura obrigatória e de "reler antes de editar" passam a consultar
# este arquivo, não o transcript bruto.

source "$(dirname "$0")/lib/common.sh"
read_input

FILE_PATH=$(normalize_path "$(field '.tool_input.file_path')")
OFFSET=$(field '.tool_input.offset')
LIMIT=$(field '.tool_input.limit')
TRANSCRIPT=$(field '.transcript_path')

# Todo documento deve ser lido na íntegra, sem ferramenta de resumo,
# sem corte, sem exceção -- vale pra qualquer documento do projeto
# hospedeiro ou deste módulo, não só a lista dos obrigatórios. Um Read
# com offset/limit é leitura parcial, de propósito -- não conta como
# "lido" pras checagens de leitura obrigatória nem de "reler antes de
# editar". Vai pro log separado (rastro, não apaga o pedido), nunca no
# read-log.txt principal, que as checagens conferem.
if [[ -n "$FILE_PATH" ]]; then
  if [[ -n "$OFFSET" || -n "$LIMIT" ]]; then
    echo "$(date -u +%FT%TZ) $FILE_PATH (parcial: offset=${OFFSET:-0} limit=${LIMIT:-?})" >> "${STATE_DIR}/partial-read-log.txt"
  else
    echo "$(date -u +%FT%TZ) $FILE_PATH" >> "${STATE_DIR}/read-log.txt"
    # Ficha (síntese, lib/common.sh): anda o relógio e marca esta
    # leitura como confirmada agora -- registrada tanto pelo caminho
    # completo quanto pelo nome do arquivo sozinho (comparação por
    # basename, usada pra citação de documento e leitura manual
    # obrigatória). Duas medidas de frescor gravadas juntas: por
    # número de ações (synthesis_set) e por tokens estimados de
    # conversa (synthesis_set_bytes, ver decisions/0023) -- a segunda
    # é a que decide se uma leitura parcial subsequente do mesmo
    # arquivo é permitida, e não é opcional: sem este registro,
    # nenhuma leitura parcial nunca encontraria uma leitura completa
    # fresca.
    synthesis_bump >/dev/null
    synthesis_set "leitura.${FILE_PATH}"
    synthesis_set "leitura.$(basename "$FILE_PATH")"
    BYTES_AGORA=$(transcript_chars "$TRANSCRIPT")
    synthesis_set_bytes "leitura_bytes.${FILE_PATH}" "$BYTES_AGORA"
    synthesis_set_bytes "leitura_bytes.$(basename "$FILE_PATH")" "$BYTES_AGORA"
  fi
fi

exit 0
