#!/bin/bash
# configurar-protecao-branch.sh
#
# Roda uma vez, fora de qualquer sessão do Claude Code, direto no seu
# terminal (precisa do `gh` autenticado com permissão de admin no
# repositório). Configura no GitHub -- não no seu computador -- a
# única camada que ninguém localmente consegue burlar sozinho:
# proteção de branch server-side pra develop e main.

set -euo pipefail

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "Configurando proteção de branch em: $REPO"

for BRANCH in develop main; do
  echo "-- $BRANCH --"
  gh api -X PUT "repos/$REPO/branches/$BRANCH/protection" \
    -H "Accept: application/vnd.github+json" \
    -f "required_status_checks=null" \
    -F "enforce_admins=true" \
    -f "required_pull_request_reviews[required_approving_review_count]=0" \
    -F "restrictions=null" \
    -F "allow_force_pushes=false" \
    -F "allow_deletions=false" \
    -F "required_linear_history=false"
done

echo "Pronto. develop e main agora recusam force-push e exclusão vindos do GitHub, não importa a ferramenta usada."
