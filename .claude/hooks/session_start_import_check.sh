#!/bin/bash
# session_start_import_check.sh -- evento: SessionStart, sem matcher
# (roda em toda sessão nova, não só depois de compactação)
#
# CLAUDE.md, "Leitura obrigatória, fonte da verdade": dezesseis
# documentos entram via importação automática (`@caminho`) -- esse
# mecanismo é do próprio Claude Code, não é um gancho deste projeto, e
# falha em silêncio quando o caminho está errado ou o arquivo não
# existe (mesmo comportamento já confirmado pros seis documentos de
# nome com espaço, que por isso viraram leitura manual em vez de
# importação -- ver TASKS.md, raiz). Nenhum gancho conferia se os
# dezesseis arquivos de fato existem no caminho declarado -- esta
# checagem fecha isso, rodando uma vez, no início de cada sessão.

source "$(dirname "$0")/lib/common.sh"
read_input

PROJECT_DIR="${CLAUDE_PROJECT_DIR}"

IMPORTS=(
  "TASKS.md"
  "README.md"
  "HANDOFF.md"
  "docs/docs-VMODEL-visao-geral/README.md"
  "modulos/README.md"
  "modulos/_template/docs/concept.md"
  "modulos/_template/docs/architecture.md"
  "modulos/_template/docs/analysis.md"
  "modulos/_template/docs/findings.md"
  "modulos/_template/docs/handoff.md"
  "modulos/_template/docs/pitfalls.md"
  "modulos/_template/docs/tasks.md"
  "modulos/_template/schemas/README.md"
  "modulos/_template/decisions/README.md"
  "modulos/motor/docs/handoff.md"
  "modulos/motor/docs/concept.md"
)

MISSING=""
for f in "${IMPORTS[@]}"; do
  if [[ ! -f "${PROJECT_DIR}/${f}" ]]; then
    MISSING+="  - $f"$'\n'
  fi
done

if [[ -n "$MISSING" ]]; then
  block "Bloqueado: arquivo(s) da importação automática do CLAUDE.md (seção 'Leitura obrigatória') não encontrado(s) no caminho declarado -- a importação @caminho falha em silêncio nesse caso, o conteúdo nunca chega no contexto da sessão:
${MISSING}
Corrija o caminho no CLAUDE.md ou restaure o arquivo antes de continuar."
fi

exit 0
