#!/bin/bash
# pre_git_rules.sh -- evento: PreToolUse, filtro: Bash(git *) e Bash(gh pr create *)

source "$(dirname "$0")/lib/common.sh"
read_input

COMMAND=$(field '.tool_input.command')
CWD=$(normalize_path "$(field '.cwd')")
TRANSCRIPT=$(field '.transcript_path')

BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)

IS_REWRITE=false
if echo "$COMMAND" | grep -Eq '\brebase\b|\bcommit[[:space:]]+--amend\b|\breset[[:space:]]+--hard\b|\bpush[[:space:]]+--force\b|[[:space:]]-f([[:space:]]|$)'; then
  IS_REWRITE=true
fi

# 1) Reescrever histórico em develop/main -- NUNCA tem chave, sem exceção
if [[ "$BRANCH" == "develop" || "$BRANCH" == "main" ]] && $IS_REWRITE; then
  block "Bloqueado: reescrever histórico não é permitido em develop/main, sem exceção -- não há AUTORIZO-TRAVA que libere isso."
fi

# 1b) Commit novo direto em develop/main -- NUNCA tem chave, sem exceção.
# Todo trabalho novo nasce numa branch de tarefa, numa worktree própria;
# develop/main só recebem conteúdo por "git merge --no-ff" (Passo 7 do
# fluxo completo), nunca por "git commit" direto. Cuidado: o merge em
# si roda com develop como branch atual e produz um commit de merge --
# isso não pode ser bloqueado.
#
# Achado ao vivo: quando "git merge --no-ff" encontra conflito, ele
# para sem commitar -- terminar a mesclagem depois de resolver o
# conflito exige um "git commit" em comando separado, sem a palavra
# "merge" nele. A checagem original só olhava se "merge" aparecia no
# MESMO comando que "commit", então esse caso real (conflito, muito
# comum) caía nesta regra por engano, travando um passo que o próprio
# comentário acima já dizia que "não pode ser bloqueado". Corrigido:
# reconhece esse caso também checando MERGE_HEAD -- um arquivo que o
# git cria assim que "git merge" começa e só apaga quando a mesclagem
# termina (por commit ou por "git merge --abort"). Existir esse
# arquivo é a forma correta e padrão do git de saber "uma mesclagem
# está em andamento agora", sem depender do texto do comando.
GIT_DIR=$(git -C "$CWD" rev-parse --git-dir 2>/dev/null)
MERGE_EM_ANDAMENTO=false
[[ -n "$GIT_DIR" && -f "$GIT_DIR/MERGE_HEAD" ]] && MERGE_EM_ANDAMENTO=true
if [[ "$BRANCH" == "develop" || "$BRANCH" == "main" ]] && echo "$COMMAND" | grep -Eq '\bgit[[:space:]]+commit\b' && ! echo "$COMMAND" | grep -Eq '\bgit[[:space:]]+merge\b' && ! $MERGE_EM_ANDAMENTO; then
  block "Bloqueado: commit novo direto em $BRANCH não é permitido, sem exceção -- todo trabalho nasce numa branch de tarefa, numa worktree própria (ver regras gerais do projeto, secao Trabalho em multiplas frentes). $BRANCH só recebe conteúdo por 'git merge --no-ff', nunca por 'git commit' direto."
fi

# 2) Merge sem --no-ff -- sem chave, é trivial de corrigir direto
if [[ "$BRANCH" == "develop" ]] && echo "$COMMAND" | grep -Eq '\bgit[[:space:]]+merge\b'; then
  if ! echo "$COMMAND" | grep -q -- '--no-ff'; then
    block "Bloqueado: merge em develop sempre usa --no-ff. Só adicionar a flag, não precisa de autorização."
  fi
fi

# 3) Base do PR tem que ser develop, nunca main -- fato objetivo, não
# julgamento: gh pr view devolve isso com certeza depois de criado.
if echo "$COMMAND" | grep -Eq '\bgh[[:space:]]+pr[[:space:]]+create\b'; then
  if echo "$COMMAND" | grep -Eq '\-\-base[[:space:]]+main\b'; then
    block "Bloqueado: PR nunca vai direto pra main, sempre pra develop."
  fi
fi

# gradlew --stop automático antes de remover worktree via comando
# manual (defesa em profundidade -- o hook nativo WorktreeRemove
# cobre o caminho --worktree, este cobre o "git worktree remove"
# digitado à mão, que é como o CLAUDE.md deste projeto instrui)
if echo "$COMMAND" | grep -Eq '\bgit[[:space:]]+worktree[[:space:]]+remove\b'; then
  WT_PATH=$(echo "$COMMAND" | sed -E 's#.*worktree[[:space:]]+remove[[:space:]]+##' | awk '{print $1}')
  FULL_WT_PATH="${CWD}/${WT_PATH}"
  if [[ -f "${FULL_WT_PATH}/gradlew" ]]; then
    (cd "${FULL_WT_PATH}" && ./gradlew --stop) >/dev/null 2>&1
  fi
fi

# A partir daqui: checagens heurísticas, autorizáveis com AUTORIZO-TRAVA
if is_authorized; then
  log_override "pre_git_rules" "$(authorized_reason)"
  exit 0
fi

# 4) Investigar antes de reescrever (qualquer branch)
if $IS_REWRITE && [[ -f "$TRANSCRIPT" ]]; then
  if ! grep -Eq 'git log|git reflog|git ls-remote|git fetch' "$TRANSCRIPT"; then
    block "Bloqueado: antes de reescrever histórico, confira o estado real primeiro (git log, git reflog, git ls-remote ou git fetch). Se já conferiu de outro jeito, use AUTORIZO-TRAVA: <motivo>."
  fi
fi

# 5) Trocar de branch fora de worktree
if echo "$COMMAND" | grep -Eq '\bgit[[:space:]]+(checkout|switch)\b' && [[ "$CWD" != *"/.claude/worktrees/"* ]]; then
  if ! echo "$COMMAND" | grep -Eq '\bcheckout\b.*--[[:space:]]'; then
    block "Bloqueado: trocar de branch fora de uma worktree. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
  fi
fi

# 6) Merge em develop sem PR de verdade por trás -- CLAUDE.md, Trabalho
# em múltiplas frentes: "nunca commitar/mergear direto sem passar por
# PR, mesmo sendo projeto de um só dono". A checagem 2 (acima) já
# confere --no-ff; esta confere que o branch mesclado teve um PR
# (aberto, fechado ou já mesclado -- qualquer estado conta, o que
# importa é ter existido o ponto de checagem) antes desse momento.
if [[ "$BRANCH" == "develop" ]] && echo "$COMMAND" | grep -Eq '\bgit[[:space:]]+merge\b'; then
  MERGE_TARGET=$(echo "$COMMAND" | sed -E 's/.*\bmerge\b//' | tr ' ' '\n' | grep -Ev '^-' | grep -v '^$' | head -n 1)
  if [[ -n "$MERGE_TARGET" ]]; then
    PR_COUNT=$(gh pr list --state all --head "$MERGE_TARGET" --json number 2>/dev/null | jq 'length' 2>/dev/null)
    if [[ "${PR_COUNT:-0}" -eq 0 ]]; then
      block "Bloqueado: nenhum PR (aberto, fechado ou mesclado) encontrado com origem no branch '$MERGE_TARGET' -- CLAUDE.md exige PR sempre antes de mesclar em develop, nunca merge direto. Se isso for engano (gh não autenticado, PR criado por outro caminho), use AUTORIZO-TRAVA: <motivo>."
    fi
  fi
fi

exit 0
