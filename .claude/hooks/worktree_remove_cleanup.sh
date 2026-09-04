#!/bin/bash
# worktree_remove_cleanup.sh -- evento nativo: WorktreeRemove
#
# ATENÇÃO -- limite honesto, achado na pesquisa oficial: este evento
# dispara de forma confiável quando a worktree foi criada/gerenciada
# pelo mecanismo próprio do Claude Code (flag --worktree, ferramenta
# EnterWorktree/ExitWorktree). O fluxo deste CLAUDE.md usa
# `git worktree remove` digitado à mão dentro do Bash, e há relatos
# de bug abertos no próprio repositório do Claude Code (#36205)
# mostrando que o caminho "ferramenta interna" às vezes NÃO dispara
# este evento. Por isso ele entra como reforço extra -- a checagem
# de verdade, que cobre o caminho manual, é a que já está dentro de
# pre_git_rules.sh. Este hook garante o mesmo cuidado (gradlew --stop)
# também no dia em que o fluxo passar a usar --worktree de verdade.

source "$(dirname "$0")/lib/common.sh"
read_input

WT_PATH=$(field '.worktree_path')

if [[ -n "$WT_PATH" && -f "${WT_PATH}/gradlew" ]]; then
  (cd "$WT_PATH" && ./gradlew --stop) >/dev/null 2>&1
  echo "$(date -u +%FT%TZ) gradlew --stop rodado antes de remover $WT_PATH (via evento nativo)" >> "${STATE_DIR}/worktree-cleanup.log"
fi

exit 0
