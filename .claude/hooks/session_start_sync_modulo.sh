#!/bin/bash
# session_start_sync_modulo.sh -- evento: SessionStart, matcher:
# startup|resume|clear (todo início de sessão que carrega configuração
# do zero -- nunca "compact", que não recarrega ganchos)
#
# .claude/hooks/ e .claude/agents/, na raiz do projeto hospedeiro, são
# atalho de pasta de verdade pro clone deste projeto (mesmo conteúdo
# físico dos dois lados, sempre -- ver decisions/0025). O restante do
# que este projeto entrega ao projeto hospedeiro não pode usar esse
# mesmo recurso: cada item abaixo é um arquivo único (atalho de pasta
# do Windows só cobre pasta inteira), ou uma pasta que o projeto
# hospedeiro pode legitimamente querer usar pra outra coisa além do
# que este projeto contribui (ex.: `.github/` pode ter workflow próprio
# do projeto; `scripts/` pode ter script que nada tem a ver com este
# projeto) -- virar atalho de pasta inteira apagaria essa liberdade.
# Cada item é copiado, aqui, por cima da raiz, sempre no início de
# sessão -- único momento em que uma mudança de gancho pode de fato
# passar a valer (ver pitfalls.md, configuração de ganchos não
# recarrega na mesma sessão) -- nunca exigindo lembrar de copiar à mão.
# Ver decisions/0034 e decisions/0036 (localização livre, não mais
# caminho fixo -- lida do marcador escrito por scripts/instalar.sh).

source "$(dirname "$0")/lib/common.sh"
read_input

MARCADOR_CAMINHO="${CLAUDE_PROJECT_DIR}/.claude/conformidade-caminho"
[[ -f "$MARCADOR_CAMINHO" ]] || exit 0
CAMINHO_RELATIVO=$(cat "$MARCADOR_CAMINHO" 2>/dev/null)
[[ -n "$CAMINHO_RELATIVO" ]] || exit 0
MODULO_DIR="${CLAUDE_PROJECT_DIR}/${CAMINHO_RELATIVO}"
[[ -d "$MODULO_DIR" ]] || exit 0

SYNC_TARGETS=(
  ".claude/settings.json"
  ".claude/skills/revisar-pr"
  ".github/pull_request_template.md"
  ".vale.ini"
  ".vale/styles"
  "scripts/hooks"
  "scripts/instalar-hooks.sh"
  "scripts/instalar.sh"
  "scripts/README.md"
)

for rel in "${SYNC_TARGETS[@]}"; do
  origem="${MODULO_DIR}/${rel}"
  destino="${CLAUDE_PROJECT_DIR}/${rel}"
  [[ -e "$origem" ]] || continue

  if [[ -d "$origem" ]]; then
    mkdir -p "$destino"
    cp -r "$origem"/. "$destino"/ 2>/dev/null
  else
    mkdir -p "$(dirname "$destino")"
    if ! cmp -s "$origem" "$destino" 2>/dev/null; then
      cp "$origem" "$destino"
      echo "$(date -u +%FT%TZ) [sync-modulo] ${rel} sincronizado a partir do módulo" >> "${STATE_DIR}/overrides.log"
    fi
  fi
done

exit 0
