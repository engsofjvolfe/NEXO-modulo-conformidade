#!/bin/bash
# stop_fact_check.sh -- evento: Stop
#
# Antes deste script existir, três fatos puros (lista de worktree sem
# sobra, git status limpo, base do PR igual a "develop") eram
# checados por um hook do tipo "agent" -- uma chamada de modelo cara
# (custo + latência), a cada resposta, pra confirmar coisa que um
# script consegue confirmar sozinho, sem IA nenhuma. Isso contradiz o
# próprio princípio deste projeto (MANUAL.md, seção 1: "fato mecânico
# vira script que confere e barra, sem perguntar nada"). Este hook
# assume essa parte; o hook "agent" que continua rodando junto (ver
# settings.json) fica só com as perguntas de julgamento de verdade
# (significância pro HANDOFF.md, produção, clareza da descrição do
# PR), que exigem entendimento, não só olhar um valor.
#
# Trava de verdade, não só aviso: pesquisa direta na documentação
# oficial do Claude Code confirmou que "exit 2" é o único mecanismo de
# bloqueio garantido em qualquer evento, incluindo Stop, com a
# mensagem lida do stderr -- e que "additionalContext" (usado antes
# aqui) não bloqueia nada, só aparece como texto que pode ser seguido
# ou ignorado. Como os três fatos abaixo são objetivos (sem
# julgamento), block() aqui é seguro; AUTORIZO-TRAVA continua
# liberando, pra não travar sem saída num caso excepcional real (por
# exemplo, uma worktree "esquecida" que ainda está em uso de
# propósito).

source "$(dirname "$0")/lib/common.sh"
read_input

if is_authorized; then
  log_override "stop_fact_check" "$(authorized_reason)"
  exit 0
fi

CWD=$(normalize_path "$(field '.cwd')")
CONTEXT=""

# 1) Worktree já mesclada em develop e esquecida (CLAUDE.md: "rodar
# git worktree list de vez em quando pra conferir que não sobrou
# nenhuma"). Mesclada = a branch da worktree já está contida em
# develop (git branch --merged develop já a lista).
#
# A pasta principal do repositório nunca entra nessa lista, mesmo
# quando a própria branch dela já está contida em develop -- ela nunca
# é uma worktree de tarefa esquecida pra remover. Dois filtros, não um
# só: (a) paths_equal contra $CWD (lib/common.sh, não "==" direto --
# letra de unidade em caixas diferentes no Windows não pode quebrar a
# comparação) cobre o caso comum, checagem rodando da própria pasta
# principal; (b) branch igual a "develop"/"main" cobre o caso desta
# sessão -- rodando de dentro de uma worktree de TAREFA, $CWD nunca é
# igual à pasta principal, e "git branch --merged develop" sempre lista
# "develop" (todo branch é ancestral de si mesmo), então sem o filtro
# (b) a pasta principal aparecia, por engano, como "worktree esquecida"
# -- achado ao vivo, confirmado pelo próprio gancho disparando errado
# nesta sessão.
MERGED_BRANCHES=$(git -C "$CWD" branch --merged develop --format='%(refname:short)' 2>/dev/null)
STALE_WORKTREES=""
while IFS= read -r line; do
  WT_PATH=$(echo "$line" | awk '{print $1}')
  WT_BRANCH=$(echo "$line" | grep -oE '\[[^]]+\]' | tr -d '[]')
  [[ -z "$WT_BRANCH" ]] && continue
  [[ "$WT_BRANCH" == "develop" || "$WT_BRANCH" == "main" ]] && continue
  paths_equal "$WT_PATH" "$CWD" && continue
  if echo "$MERGED_BRANCHES" | grep -qxF "$WT_BRANCH"; then
    STALE_WORKTREES+="  - $WT_PATH (branch '$WT_BRANCH', já mesclada em develop)"$'\n'
  fi
done < <(git -C "$CWD" worktree list 2>/dev/null)
if [[ -n "$STALE_WORKTREES" ]]; then
  CONTEXT+="FATO: existe worktree já mesclada em develop e não removida:"$'\n'"$STALE_WORKTREES"
fi

# 2) git status --porcelain limpo -- só relevante se a resposta
# sinaliza entrega ("pronto", "concluíd", "finalizad").
LAST_MSG=$(field '.last_assistant_message')
if echo "$LAST_MSG" | grep -Eiq 'pronto|conclu[ií]d|finalizad'; then
  DIRTY=$(git -C "$CWD" status --porcelain 2>/dev/null)
  if [[ -n "$DIRTY" ]]; then
    CONTEXT+="FATO: a resposta sinaliza entrega, mas git status não está limpo:"$'\n'"$DIRTY"$'\n'
  fi
fi

# 3) Base do PR -- fato objetivo (nunca pergunta), só quando a
# resposta menciona PR.
if echo "$LAST_MSG" | grep -Eiq '\bPR\b|pull request'; then
  PR_JSON=$(gh pr view --json baseRefName,url 2>/dev/null)
  if [[ -n "$PR_JSON" ]]; then
    BASE=$(echo "$PR_JSON" | jq -r '.baseRefName // empty')
    if [[ "$BASE" == "main" ]]; then
      CONTEXT+="FATO: PR aberto com base em 'main' -- nunca permitido, sempre 'develop'."$'\n'
    fi
  fi
fi

if [[ -n "$CONTEXT" ]]; then
  block "Bloqueado -- fato conferido, não julgamento (CLAUDE.md, seção correspondente):
${CONTEXT}
Corrija antes de terminar a resposta. Se algum destes itens for engano ou exceção real, use AUTORIZO-TRAVA: <motivo> na próxima mensagem."
fi

exit 0
