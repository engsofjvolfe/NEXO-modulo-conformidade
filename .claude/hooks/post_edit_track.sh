#!/bin/bash
# post_edit_track.sh -- evento: PostToolUse, filtro: Write|Edit
#
# Toda vez que um arquivo é escrito ou editado, guarda uma linha
# "hora + caminho" no log de ordem de edição. Um git diff sozinho só
# mostra o resultado final, nunca a ordem em que as coisas foram
# tocadas -- este log guarda essa ordem de verdade.

source "$(dirname "$0")/lib/common.sh"
read_input

FILE_PATH=$(normalize_path "$(field '.tool_input.file_path')")

if [[ -n "$FILE_PATH" ]]; then
  echo "$(date -u +%FT%TZ) $FILE_PATH" >> "$EDIT_LOG"

  # Ficha (síntese, lib/common.sh): além do diário completo acima,
  # marca qual etapa do fluxo (concept/architecture/schemas/código/
  # handoff, por módulo, ou os dois documentos gerais da raiz que
  # pre_edit_safety.sh confere) acabou de ser tocada -- checagens de
  # ordem consultam isso em vez de reler o diário inteiro.
  synthesis_bump >/dev/null
  if [[ "$FILE_PATH" == *"/modulos/"* ]]; then
    MOD_ST=$(echo "$FILE_PATH" | sed -E 's#.*/modulos/([^/]+)/.*#\1#')
    case "$FILE_PATH" in
      */modulos/README.md) synthesis_set "edicao.modulos-readme" ;;
      */modulos/"$MOD_ST"/docs/concept.md) synthesis_set "edicao.${MOD_ST}.concept" ;;
      */modulos/"$MOD_ST"/docs/architecture.md) synthesis_set "edicao.${MOD_ST}.architecture" ;;
      */modulos/"$MOD_ST"/docs/handoff.md) synthesis_set "edicao.${MOD_ST}.handoff" ;;
      */modulos/"$MOD_ST"/docs/tasks.md) synthesis_set "edicao.${MOD_ST}.tasks" ;;
      */modulos/"$MOD_ST"/docs/findings.md) synthesis_set "edicao.${MOD_ST}.findings" ;;
      */modulos/"$MOD_ST"/docs/pitfalls.md) synthesis_set "edicao.${MOD_ST}.pitfalls" ;;
      */modulos/"$MOD_ST"/schemas/*) synthesis_set "edicao.${MOD_ST}.schemas" ;;
      */modulos/"$MOD_ST"/decisions/*) synthesis_set "edicao.${MOD_ST}.decisions" ;; # não conta como etapa de ORDEM do fluxo, mas os itens 13/14-15 de pre_edit_safety.sh consultam isso
      */modulos/"$MOD_ST"/docs/*) : ;; # analysis.md, sem etapa de ordem própria
      *) synthesis_set "edicao.${MOD_ST}.codigo" ;;
    esac
  elif [[ "$FILE_PATH" == *"/TASKS.md" ]]; then
    synthesis_set "edicao.tasks-raiz"
  fi
fi

exit 0
