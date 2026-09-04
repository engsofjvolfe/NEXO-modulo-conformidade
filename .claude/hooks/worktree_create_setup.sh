#!/bin/bash
# worktree_create_setup.sh -- evento nativo: WorktreeCreate
#
# ATENÇÃO -- mesmo limite honesto já registrado em
# worktree_remove_cleanup.sh: este evento dispara de forma confiável
# quando a worktree foi criada pelo mecanismo próprio do Claude Code
# (ferramenta EnterWorktree) -- o caminho que o fluxo deste CLAUDE.md
# usa de verdade. "git worktree add" digitado à mão no Bash pode não
# disparar este evento (mesma classe de bug já linkada no outro
# arquivo). Por isso existe um reforço em
# pre_mandatory_reading_guard.sh, que roda em toda ferramenta, dentro
# de qualquer worktree -- cobre o caminho manual mesmo se este evento
# nunca disparar ali.
#
# Sem isso, uma worktree nova nunca enxerga .claude/agents,
# .claude/hooks nem modulos/conformidade -- as três são locais, fora do
# controle de versão (ver .gitignore), e "git worktree add" só traz
# conteúdo já versionado. Ver ensure_worktree_links em lib/common.sh
# pro mecanismo (atalho de pasta / junction) e
# modulos/conformidade/decisions/0021 pro raciocínio completo.

source "$(dirname "$0")/lib/common.sh"
read_input

WT_PATH=$(field '.worktree_path')

if [[ -n "$WT_PATH" ]]; then
  ensure_worktree_links "$WT_PATH"
fi

exit 0
