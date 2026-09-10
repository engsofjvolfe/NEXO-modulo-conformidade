#!/bin/bash
# Instalação completa deste projeto num projeto hospedeiro -- rodar UMA
# vez, de dentro da RAIZ do projeto hospedeiro (nunca de dentro da
# pasta deste projeto, que pode ter seu próprio repositório git
# separado -- usar `git rev-parse --show-toplevel` pra descobrir a
# raiz foi tentado e descartado por esse motivo: acharia a raiz DESTE
# projeto, nunca a do hospedeiro por fora). Apontar pro script já
# copiado, em qualquer lugar dentro do projeto (ver ../COMO-USAR.md --
# o caminho é escolha livre de quem instala, nunca fixo), por exemplo:
#   ./caminho/onde/copiei/scripts/instalar.sh
# Depois desta única execução, tudo mais fica automático:
# session_start_sync_modulo.sh (evento SessionStart) mantém a raiz do
# projeto sincronizada sozinho, toda sessão nova, sem exigir rodar
# nada de novo -- ele descobre onde esta pasta está lendo o marcador
# que este script escreve abaixo (${MARCADOR_CAMINHO}).
#
# Precisa de privilégio pra criar atalho de pasta (junction, Windows) --
# não exige administrador nem "Modo desenvolvedor" (testado ao vivo,
# diferente de link simbólico de arquivo, que exige um dos dois).

set -e

RAIZ_DIR="$(pwd)"
MODULO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MARCADOR_CAMINHO="${RAIZ_DIR}/.claude/conformidade-caminho"
CAMINHO_RELATIVO="${MODULO_DIR#"$RAIZ_DIR"/}"

if [[ "$CAMINHO_RELATIVO" == "$MODULO_DIR" ]]; then
  echo "Erro: rode este comando de dentro da RAIZ do projeto hospedeiro" >&2
  echo "(diretório atual: $RAIZ_DIR), apontando pro script, não de dentro" >&2
  echo "da pasta deste projeto. Exemplo: ./caminho/pra/pasta/scripts/instalar.sh" >&2
  exit 1
fi

echo "Instalando a partir de: $MODULO_DIR"
echo "Raiz do projeto hospedeiro (detectada via git): $RAIZ_DIR"
echo "Caminho relativo registrado: $CAMINHO_RELATIVO"

mkdir -p "$(dirname "$MARCADOR_CAMINHO")"
printf '%s' "$CAMINHO_RELATIVO" > "$MARCADOR_CAMINHO"

criar_atalho_pasta() {
  local rel="$1"
  local origem="${MODULO_DIR}/${rel}"
  local destino="${RAIZ_DIR}/${rel}"
  [[ -d "$origem" ]] || { echo "  (nada em $rel dentro da pasta instalada, pulando)"; return 0; }
  if [[ -e "$destino" ]]; then
    echo "  $rel já existe na raiz, deixando como está"
    return 0
  fi
  mkdir -p "$(dirname "$destino")"
  local origem_win destino_win
  origem_win=$(cygpath -w "$origem")
  destino_win=$(cygpath -w "$destino")
  powershell.exe -NoProfile -Command "New-Item -ItemType Junction -Path '${destino_win}' -Target '${origem_win}'" >/dev/null
  echo "  atalho de pasta criado: $rel -> pasta instalada"
}

echo "Criando atalhos de pasta (.claude/hooks, .claude/agents)..."
criar_atalho_pasta ".claude/hooks"
criar_atalho_pasta ".claude/agents"

echo "Copiando o restante (settings.json, skills, .github, .vale, scripts)..."
for rel in \
  ".claude/settings.json" \
  ".claude/skills/revisar-pr" \
  ".github/pull_request_template.md" \
  ".vale.ini" \
  ".vale/styles" \
  "scripts/hooks" \
  "scripts/instalar-hooks.sh" \
  "scripts/instalar.sh" \
  "scripts/README.md"
do
  origem="${MODULO_DIR}/${rel}"
  destino="${RAIZ_DIR}/${rel}"
  [[ -e "$origem" ]] || continue
  mkdir -p "$(dirname "$destino")"
  if [[ -d "$origem" ]]; then
    mkdir -p "$destino"
    cp -r "$origem"/. "$destino"/
  else
    cp "$origem" "$destino"
  fi
done
echo "  feito -- session_start_sync_modulo.sh mantém isso em dia sozinho depois daqui."

echo "Ligando os vigias nativos do git (core.hooksPath)..."
git -C "$RAIZ_DIR" config core.hooksPath scripts/hooks

echo ""
echo "Instalação completa. Abra (ou reabra) uma sessão do Claude Code na raiz de $RAIZ_DIR."
