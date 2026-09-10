#!/bin/bash
# pre_mandatory_reading_guard.sh -- evento: PreToolUse, matcher: "*" (toda ferramenta)
#
# CLAUDE.md, "Leitura obrigatória, fonte da verdade": a lista de seis
# documentos de leitura manual vale "antes de qualquer outra coisa" --
# não só antes de escrever código. Este gancho é a única checagem
# deste projeto que cobre esse "qualquer outra coisa" por inteiro:
# roda antes de toda ferramenta. TodoWrite sempre passa (não afeta
# nada fora da própria lista de tarefas -- sem efeito no repositório,
# no sistema de arquivos ou em qualquer serviço externo). Qualquer
# outra ferramenta -- Bash, Grep, Glob, Write, Edit, Agent, WebFetch,
# WebSearch, EnterWorktree, e por aí em diante -- fica bloqueada até
# os seis documentos terem passado por Read por inteiro nesta sessão.
#
# Read é um caso à parte, não uma isenção lisa: precisa continuar
# liberado pros seis documentos da lista (é o único jeito de cumprir a
# exigência -- bloquear Read também impediria de sempre satisfazer a
# própria checagem). Mas liberar TODO Read, sem olhar qual arquivo,
# abre uma brecha real -- confirmada ao vivo nesta mesma sessão: dá
# pra ler qualquer outro arquivo (documentação solta, código, o que
# for) antes dos seis obrigatórios, sem nada travar, porque a
# ferramenta usada continua sendo "Read" e passava batido. Enquanto
# sobrar documento da lista por ler, só o Read de um desses seis
# (comparado pelo nome do arquivo, não pelo caminho inteiro -- o link
# no CLAUDE.md é relativo) passa; Read de qualquer outro arquivo
# bloqueia igual a qualquer outra ferramenta. Depois que os seis
# passarem por leitura completa, Read de qualquer arquivo volta a ser
# livre, sem essa restrição.

source "$(dirname "$0")/lib/common.sh"
read_input

TOOL_NAME=$(field '.tool_name')

# Reforço pro evento nativo WorktreeCreate (worktree_create_setup.sh) --
# cobre o caminho de "git worktree add" digitado à mão, que pode não
# disparar aquele evento (mesmo limite documentado em
# worktree_remove_cleanup.sh). Roda em toda ferramenta, então pega a
# worktree assim que a primeira ação acontecer nela; idempotente e
# barato (só confere se o atalho já existe antes de fazer qualquer
# coisa), então rodar toda vez não pesa. Ver ensure_worktree_links em
# lib/common.sh.
ensure_worktree_links "$(field '.cwd')"

if [[ "$TOOL_NAME" == "TodoWrite" ]]; then
  exit 0
fi

# Edição/leitura só dentro do módulo de conformidade e do resto da
# ferramenta interna (ver INTERNAL_TOOLING_PATHS em lib/common.sh, lida
# do .gitignore) nunca depende da leitura obrigatória do NEXO -- este
# módulo tem sua própria documentação e seu próprio processo de
# escrita, sobre o produto NEXO, não parte dele. Isenção permanente,
# sem precisar de AUTORIZO-TRAVA a cada mensagem -- decidida em
# modulos/conformidade/decisions/ (ver ADR correspondente). Confere
# `file_path`, `command`, `path` e `pattern` juntos (cobre Read/Write/
# Edit, Bash, Grep/Glob) -- se nenhum campo desses existir no tipo de
# ferramenta, a checagem simplesmente não bate com nada, sem erro.
ALVO_FERRAMENTA="$(field '.tool_input.file_path')$(field '.tool_input.command')$(field '.tool_input.path')$(field '.tool_input.pattern')"
if command_touches_internal_tooling "$ALVO_FERRAMENTA"; then
  exit 0
fi

# Edição/leitura só dentro do módulo de conformidade e do resto da
# ferramenta interna (ver INTERNAL_TOOLING_PATHS em lib/common.sh, lida
# do .gitignore) nunca depende da leitura obrigatória do NEXO -- este
# módulo tem sua própria documentação e seu próprio processo de
# escrita, sobre o produto NEXO, não parte dele. Isenção permanente,
# sem precisar de AUTORIZO-TRAVA a cada mensagem -- decidida em
# modulos/conformidade/decisions/ (ver ADR correspondente). Confere
# `file_path`, `command`, `path` e `pattern` juntos (cobre Read/Write/
# Edit, Bash, Grep/Glob) -- se nenhum campo desses existir no tipo de
# ferramenta, a checagem simplesmente não bate com nada, sem erro.
ALVO_FERRAMENTA="$(normalize_path "$(field '.tool_input.file_path')")$(field '.tool_input.command')$(normalize_path "$(field '.tool_input.path')")$(field '.tool_input.pattern')"
if command_touches_internal_tooling "$ALVO_FERRAMENTA"; then
  exit 0
fi

# Comando git ou gh (qualquer um -- status, commit, push, pull, abrir
# PR, etc.) nunca depende de ter lido os seis documentos manuais
# primeiro -- decisão explícita, dada em texto, de quem desenvolve o
# sistema: esses comandos são passo mecânico de controle de versão,
# não decisão sobre conteúdo do projeto. Só o comando em si isenta
# esta checagem específica -- as regras de segurança do git em si
# (nunca reescrever develop/main, merge sempre com --no-ff, commit
# sempre fora de develop/main, etc., em pre_git_rules.sh e
# pre_commit_hygiene.sh) continuam valendo do mesmo jeito, com o mesmo
# AUTORIZO-TRAVA de sempre pra quem quiser pular alguma delas -- essa
# liberação nunca é automática, só decidida por quem está conduzindo a
# sessão, na hora. Ver decisions/0017.
#
# Nome da variável importa aqui: "BASH_COMMAND" (usado numa primeira
# versão desta correção) é o nome de uma variável especial do próprio
# Bash, atualizada sozinha, sem aviso, a cada comando executado
# (documentada pra uso em armadilhas de depuração) -- ela sobrescrevia
# o valor atribuído aqui antes do "if" seguinte rodar, fazendo o grep
# nunca ver o comando real. Achado ao testar isoladamente antes do
# commit (ver findings.md). "COMMAND" (mesmo nome já usado em
# pre_git_rules.sh e pre_commit_hygiene.sh) não colide com nada.
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(field '.tool_input.command')
  if echo "$COMMAND" | grep -Eq '\b(git|gh)\b'; then
    exit 0
  fi
fi

if is_authorized; then
  log_override "pre_mandatory_reading_guard" "$(authorized_reason)"
  exit 0
fi

UNREAD_DOC=$(first_unread_mandatory_doc)

if [[ "$TOOL_NAME" == "Read" ]]; then
  if [[ -z "$UNREAD_DOC" ]]; then
    exit 0
  fi
  REQUESTED_FILE=$(field '.tool_input.file_path')
  REQUESTED_BASENAME="${REQUESTED_FILE##*/}"
  REQUESTED_BASENAME="${REQUESTED_BASENAME##*\\}"
  for doc in "${MANUAL_MANDATORY_DOCS[@]}"; do
    if [[ "$REQUESTED_BASENAME" == "$doc" ]]; then
      exit 0
    fi
  done
  block "Bloqueado: leitura manual obrigatória ainda não feita ('$UNREAD_DOC') -- enquanto sobrar documento da lista, só é permitido usar Read nesses seis documentos, nunca em outro arquivo primeiro (CLAUDE.md exige a leitura deles antes de qualquer outra coisa, sem exceção). Leia '$UNREAD_DOC' antes de ler '$REQUESTED_BASENAME'. LEMBRETE PRA QUEM ESTÁ CONDUZINDO A IA: isso trava de verdade, sem negociação -- a IA deve te contar isso, em poucas palavras, e nunca tentar destravar sozinha. Só você decide se é engano (com AUTORIZO-TRAVA: <motivo>, digitado por você, nunca pela IA)."
fi

if [[ -n "$UNREAD_DOC" ]]; then
  block "Bloqueado: leitura manual obrigatória ainda não feita ('$UNREAD_DOC') -- CLAUDE.md exige isso antes de qualquer outra coisa, não só antes de código. Leia (via Read) os seis documentos da lista antes de usar '$TOOL_NAME'. LEMBRETE PRA QUEM ESTÁ CONDUZINDO A IA: isso trava de verdade, sem negociação -- a IA deve te contar isso, em poucas palavras, e nunca tentar destravar sozinha. Só você decide se é engano (com AUTORIZO-TRAVA: <motivo>, digitado por você, nunca pela IA)."
fi

exit 0
