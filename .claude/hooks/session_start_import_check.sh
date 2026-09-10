#!/bin/bash
# session_start_import_check.sh -- evento: SessionStart, sem matcher
# (roda em toda sessão nova, não só depois de compactação)
#
# A lista de leitura obrigatória do projeto hospedeiro
# (mandatory_reading_doc_paths, lib/common.sh) pode citar um caminho que não
# existe mais (arquivo movido, renomeado, apagado) -- sinal de erro
# tarde demais se só aparecer no meio de uma tarefa, longe do começo da
# sessão. Esta checagem confere, uma vez, no início de cada sessão, se
# cada item da lista existe de verdade no caminho declarado.

source "$(dirname "$0")/lib/common.sh"
read_input

MISSING=""
while IFS= read -r caminho; do
  [[ -z "$caminho" ]] && continue
  [[ -f "$caminho" ]] || MISSING+="  - $caminho"$'\n'
done < <(mandatory_reading_doc_paths)

if [[ -n "$MISSING" ]]; then
  block "arquivo de leitura obrigatória ausente" "arquivo(s) da lista de leitura obrigatória (arquivo de instruções do projeto hospedeiro) não encontrado(s) em nenhum caminho do projeto:
${MISSING}
Corrija o caminho declarado ou restaure o arquivo antes de continuar."
fi

exit 0
