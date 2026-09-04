#!/bin/sh
# Liga os hooks de scripts/hooks/ neste repositorio (uma vez so --
# vale pra todas as worktrees, porque elas compartilham a mesma
# configuracao de git). Rodar direto: scripts/instalar-hooks.sh

set -e

raiz=$(git rev-parse --show-toplevel)
git -C "$raiz" config core.hooksPath scripts/hooks

echo "Hooks ligados: scripts/hooks/ agora e o diretorio de hooks deste repositorio."
