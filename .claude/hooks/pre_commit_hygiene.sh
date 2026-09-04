#!/bin/bash
# pre_commit_hygiene.sh -- evento: PreToolUse, filtro: Bash(git commit *)

source "$(dirname "$0")/lib/common.sh"
read_input

COMMAND=$(field '.tool_input.command')
CWD=$(field '.cwd')
TRANSCRIPT=$(field '.transcript_path')

# Auto-portão: o campo "if" do settings.json (matcher Bash, condição
# "Bash(git commit *)") já deveria restringir este script a rodar só
# quando o comando é mesmo um "git commit" -- mas a documentação
# oficial confirma que esse filtro FALHA ABERTO (roda o gancho mesmo
# sem bater o padrão) sempre que o comando não é totalmente parseável
# pelo mecanismo interno do Claude Code, o que comandos compostos,
# com aspas aninhadas ou heredoc, disparam com facilidade. Achado ao
# vivo nesta sessão: um comando qualquer, sem nenhum "git commit",
# disparou este script mesmo assim, e a checagem de emoji (item 2b)
# bloqueou um comando que não tinha nada a ver com commit. Sem este
# auto-portão, todo comando Bash da sessão paga o custo (e o risco de
# bloqueio falso) das checagens abaixo, que assumem staged diff e
# mensagem de commit reais. Não depende do "if" pra estar correto --
# só pra não rodar à toa quando o "if" funciona.
if ! echo "$COMMAND" | grep -Eq '\bgit[[:space:]]+commit\b'; then
  exit 0
fi

# 1) Trailer proibido -- fato de texto, sem exceção possível
if echo "$COMMAND" | grep -qi "Co-Authored-By"; then
  block "Bloqueado: a mensagem de commit não pode ter a linha 'Co-Authored-By: Claude ...'."
fi

# 2) Emoji em qualquer arquivo do commit -- fato de texto, sem exceção.
# Segunda conferência, no commit: pre_edit_safety.sh #9 já bloqueia
# isso no momento da própria edição (ver lá o motivo do LC_ALL).
if git -C "$CWD" diff --cached -U0 2>/dev/null | has_emoji; then
  block "Bloqueado: encontrei um emoji num arquivo que entraria neste commit."
fi

# 2b) Emoji na MENSAGEM do commit em si -- achado na releitura linha
# por linha do CLAUDE.md: "Nunca usar emojis em nada escrito neste
# projeto (código, docs, commits, chat)" cobre a mensagem do commit,
# não só o conteúdo dos arquivos alterados. A checagem acima (2) só
# olha o diff dos arquivos -- esta olha o comando "git commit" em si,
# onde o texto da mensagem aparece de verdade (-m "..." ou heredoc).
if echo "$COMMAND" | has_emoji; then
  block "Bloqueado: encontrei um emoji na própria mensagem do commit."
fi

# 3) Pureza de esquemas -- fato de texto, sem exceção. Segunda
# conferência, no commit: pre_edit_safety.sh #10 já bloqueia isso no
# momento da própria edição.
SCHEMA_FILES=$(git -C "$CWD" diff --cached --name-only -- '*/schemas/*.json' 'schemas/*.json' 2>/dev/null)
if [[ -n "$SCHEMA_FILES" ]]; then
  for f in $SCHEMA_FILES; do
    if git -C "$CWD" show ":$f" 2>/dev/null | grep -Eq '"description"|"example"'; then
      block "Bloqueado: $f tem campo 'description' ou 'example'. Esquema de dado carrega só dado puro."
    fi
  done
fi

# 3b) Pureza de esquema embutido num documento (ex.: o bloco YAML
# dentro de concept.md) -- mesma regra do item 3, agora pra esquema
# que não mora em schemas/*.json. CLAUDE.md, Regras gerais: "Qualquer
# esquema de dado... em qualquer lugar do projeto -- dentro de
# schemas/... ou embutido num documento como o Projeto Detalhado --
# carrega só dado puro". Segunda conferência, no commit:
# pre_edit_safety.sh #10 já bloqueia isso no momento da própria edição.
MD_FILES_SCHEMA=$(git -C "$CWD" diff --cached --name-only -- '*.md' 2>/dev/null)
for f in $MD_FILES_SCHEMA; do
  if git -C "$CWD" show ":$f" 2>/dev/null | schema_block_impure; then
    block "Bloqueado: $f tem um bloco de esquema embutido (cercado por \`\`\`yaml ou \`\`\`json) com campo 'description' ou 'example'. Esquema de dado carrega só dado puro, mesmo embutido num documento."
  fi
done

# A partir daqui: checagens heurísticas -- podem ser puladas com
# AUTORIZO-TRAVA: <motivo> na sua mensagem (ver hook
# user_prompt_submit.sh, que já confirmou a autorização antes deste
# script rodar).
if is_authorized; then
  log_override "pre_commit_hygiene" "$(authorized_reason)"
  exit 0
fi

# 4) Leitura obrigatória (os 6 de leitura manual -- ver
# first_unread_mandatory_doc em lib/common.sh pro motivo de não checar
# os 16 auto-importados aqui). Reforço: pre_edit_safety.sh já barra
# isso antes da primeira edição (Portão pro Passo 2); esta é a
# segunda conferência, no commit.
UNREAD_DOC=$(first_unread_mandatory_doc)
if [[ -n "$UNREAD_DOC" ]]; then
  block "Bloqueado: não encontrei rastro de leitura (via Read) de '$UNREAD_DOC' nesta sessão. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
fi

# 5) Ordem completa: concept.md -> architecture.md -> schemas/ ->
# implementação (CLAUDE.md, Fluxo de escrita e revisão de
# documentação). Achado na releitura linha por linha (primeira rodada):
# só "architecture.md antes do código" existia -- "concept.md antes de
# architecture.md" e "schemas/ antes do código" nunca foram checados.
# Achado na releitura seguinte, direto contra o código já corrigido:
# ainda faltava "architecture.md antes de schemas/" -- as três
# checagens que já existiam não cobriam esse par específico da ordem.
if [[ -f "$EDIT_LOG" ]]; then
  MODULES=$(git -C "$CWD" diff --cached --name-only -- 'modulos/*' 2>/dev/null | sed -E 's#(modulos/[^/]+)/.*#\1#' | sort -u)
  for mod in $MODULES; do
    CONCEPT_TIME=$(grep "$mod/docs/concept.md" "$EDIT_LOG" | head -n 1 | awk '{print $1}')
    ARCH_TIME=$(grep "$mod/docs/architecture.md" "$EDIT_LOG" | head -n 1 | awk '{print $1}')
    SCHEMA_TIME=$(grep -E "^\S+ $mod/schemas/" "$EDIT_LOG" | head -n 1 | awk '{print $1}')
    CODE_TIME=$(grep -E "^\S+ $mod/" "$EDIT_LOG" | grep -Ev '/docs/|/schemas/|/decisions/' | head -n 1 | awk '{print $1}')
    if [[ -n "$CONCEPT_TIME" && -n "$ARCH_TIME" && "$ARCH_TIME" < "$CONCEPT_TIME" ]]; then
      block "Bloqueado: em $mod, architecture.md foi tocado antes de concept.md nesta sessão. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
    fi
    if [[ -n "$ARCH_TIME" && -n "$SCHEMA_TIME" && "$SCHEMA_TIME" < "$ARCH_TIME" ]]; then
      block "Bloqueado: em $mod, schemas/ foi tocado antes de architecture.md nesta sessão. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
    fi
    if [[ -n "$SCHEMA_TIME" && -n "$CODE_TIME" && "$CODE_TIME" < "$SCHEMA_TIME" ]]; then
      block "Bloqueado: em $mod, implementação foi tocada antes de schemas/ nesta sessão. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
    fi
    if [[ -n "$ARCH_TIME" && -n "$CODE_TIME" && "$CODE_TIME" < "$ARCH_TIME" ]]; then
      block "Bloqueado: em $mod, implementação foi tocada antes de architecture.md nesta sessão. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
    fi
  done
fi

# 6) Linha de Licença em tabela de cabeçalho
for f in $(git -C "$CWD" diff --cached --name-only -- '*.md' 2>/dev/null); do
  CONTENT=$(git -C "$CWD" show ":$f" 2>/dev/null)
  if echo "$CONTENT" | grep -qE '^\s*\|?\s*Campo\s*\|\s*Valor' && ! echo "$CONTENT" | grep -qi 'Licen'; then
    block "Bloqueado: $f tem tabela de cabeçalho mas nenhuma linha de Licença. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
  fi
done

# 7) "Antes e depois" em documento novo (nunca versionado)
NEW_DOCS=$(git -C "$CWD" diff --cached --name-only --diff-filter=A -- '*.md' 2>/dev/null)
if [[ -n "$NEW_DOCS" ]]; then
  for f in $NEW_DOCS; do
    if git -C "$CWD" show ":$f" 2>/dev/null | grep -Eiq 'era assim|ficou assim|antes:|anteriormente era|mudou de.*para'; then
      block "Bloqueado: $f é documento novo mas usa linguagem de 'antes e depois'. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
    fi
  done
fi

# 8) handoff.md deve ser o último arquivo de documentação tocado
if [[ -f "$EDIT_LOG" ]]; then
  MODULES=$(git -C "$CWD" diff --cached --name-only -- 'modulos/*/docs/*' 2>/dev/null | sed -E 's#(modulos/[^/]+)/docs/.*#\1#' | sort -u)
  for mod in $MODULES; do
    LAST=$(grep "$mod/docs/" "$EDIT_LOG" | tail -n 1 | awk '{print $2}')
    if [[ -n "$LAST" && "$(basename "$LAST")" != "handoff.md" ]]; then
      block "Bloqueado: o último arquivo tocado em $mod/docs/ foi $(basename "$LAST"), não handoff.md. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
    fi
  done
fi

# 9) Deriva entre CLAUDE.md e o mecanismo que o aplica -- checagem
# mecânica (lista de arquivo, não julgamento de conteúdo): se
# CLAUDE.md muda neste commit sem nenhum arquivo de hook mudar junto,
# a regra nova (ou alterada) pode ter ficado só no texto, sem trava
# correspondente -- sinal de alerta, não certeza (nem toda mudança de
# CLAUDE.md exige hook novo), por isso autorizável.
CLAUDE_MD_CHANGED=$(git -C "$CWD" diff --cached --name-only -- '.claude/CLAUDE.md' 2>/dev/null)
if [[ -n "$CLAUDE_MD_CHANGED" ]]; then
  HOOK_FILES_CHANGED=$(git -C "$CWD" diff --cached --name-only -- '.claude/hooks/*' '.claude/settings.json' 'scripts-hooks/*' 2>/dev/null)
  if [[ -z "$HOOK_FILES_CHANGED" ]]; then
    block "Aviso: CLAUDE.md mudou neste commit e nenhum arquivo de hook (.claude/hooks/, .claude/settings.json, scripts-hooks/) mudou junto. Confirme se a regra nova/alterada precisa de mecanismo correspondente, ou se é ajuste que não se mecaniza (prosa, contexto). Se já confirmou, use AUTORIZO-TRAVA: <motivo>."
  fi
fi

# 10) Módulo novo sem linha em modulos/README.md (CLAUDE.md, "Fluxo de
# escrita e revisão de documentação": checklist de documentos gerais
# da raiz, item 1). Módulo novo = concept.md novo em modulos/<nome>/docs/.
NEW_CONCEPTS=$(git -C "$CWD" diff --cached --name-only --diff-filter=A -- 'modulos/*/docs/concept.md' 2>/dev/null)
if [[ -n "$NEW_CONCEPTS" ]]; then
  README_CHANGED=$(git -C "$CWD" diff --cached --name-only -- 'modulos/README.md' 2>/dev/null)
  for f in $NEW_CONCEPTS; do
    mod=$(echo "$f" | sed -E 's#modulos/([^/]+)/.*#\1#')
    [[ "$mod" == "_template" ]] && continue
    if [[ -z "$README_CHANGED" ]]; then
      block "Bloqueado: módulo novo '$mod' (concept.md criado) mas modulos/README.md não mudou neste commit -- falta a linha na tabela de módulos. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
    fi
  done
fi

# 11) tasks.md de algum módulo mudou de "Em aberto" vazia pra
# não-vazia (ou o contrário) sem TASKS.md (raiz) acompanhar
# (CLAUDE.md, mesmo checklist, item 2). Vazio = nenhuma linha "- [ ]"
# entre "## Em aberto" e o próximo "## ".
MODULE_TASKS=$(git -C "$CWD" diff --cached --name-only -- 'modulos/*/docs/tasks.md' 2>/dev/null)
if [[ -n "$MODULE_TASKS" ]]; then
  ROOT_TASKS_CHANGED=$(git -C "$CWD" diff --cached --name-only -- 'TASKS.md' 2>/dev/null)
  for f in $MODULE_TASKS; do
    OLD_SECTION=$(git -C "$CWD" show "HEAD:$f" 2>/dev/null | awk '/^## Em aberto/{flag=1;next}/^## /{flag=0}flag')
    NEW_SECTION=$(git -C "$CWD" show ":$f" 2>/dev/null | awk '/^## Em aberto/{flag=1;next}/^## /{flag=0}flag')
    OLD_EMPTY=true; echo "$OLD_SECTION" | grep -q '^- \[ \]' && OLD_EMPTY=false
    NEW_EMPTY=true; echo "$NEW_SECTION" | grep -q '^- \[ \]' && NEW_EMPTY=false
    if [[ "$OLD_EMPTY" != "$NEW_EMPTY" && -z "$ROOT_TASKS_CHANGED" ]]; then
      block "Bloqueado: $f mudou a seção 'Em aberto' de vazia pra não-vazia (ou o contrário), mas TASKS.md (raiz) não mudou neste commit. Se isso for engano, use AUTORIZO-TRAVA: <motivo>."
    fi
  done
fi

# 12) Mensagem de commit narrativa -- CLAUDE.md, Passo 4: "Nunca
# narrativa -- nada de bullet ou frase contando a jornada de
# investigação". O próprio CLAUDE.md já lista os três exemplos exatos
# de frase proibida -- fato de texto, sem exceção possível, igual aos
# itens 1/2/2b/3/3b acima (nunca autorizável).
if echo "$COMMAND" | grep -Eiq "descobrimos que|depois de tentar .* percebemos que|a causa acabou sendo"; then
  block "Bloqueado: a mensagem de commit parece contar a jornada de investigação ('descobrimos que...', 'depois de tentar X, percebemos que...', 'a causa acabou sendo...') -- CLAUDE.md, Passo 4: commit descreve o fato final, nunca como se chegou nele (esse relato pertence aos arquivos de investigação e achados do módulo, nunca ao commit). Reescreva a mensagem."
fi

# 13) Julgamento restante do commit (duplicação de conteúdo entre
# documentos do módulo, cada arquivo tocado batendo com a própria
# descrição no topo) -- antes checado por um gancho do tipo "agent"
# (segunda inteligência artificial) que usava um formato de resposta
# que este tipo de gancho não reconhece pra bloquear de verdade
# (achado equivalente ao da própria edição, ver o arquivo de achados
# do módulo conformidade). Os fatos mecânicos que essa segunda IA
# também checava (leitura obrigatória, ordem de escrita, achado/
# pitfall/ADR faltando) já são cobertos, sem IA nenhuma, pelos itens
# acima e pelos itens 13/14/15 de pre_edit_safety.sh, que rodam antes,
# no momento da própria edição -- só falta o julgamento genuíno, que
# nenhum script confirma sozinho: sinaliza sempre que o commit toca
# mais de um arquivo em docs/ ou decisions/ de um módulo, confirmação
# sua decide, nunca eu sozinho.
MODULOS_TOCADOS_DOCS=$(git -C "$CWD" diff --cached --name-only -- 'modulos/*/docs/*' 'modulos/*/decisions/*' 2>/dev/null | sed -E 's#(modulos/[^/]+)/.*#\1#' | sort -u)
for mod in $MODULOS_TOCADOS_DOCS; do
  QTD=$(git -C "$CWD" diff --cached --name-only -- "$mod/docs/*" "$mod/decisions/*" 2>/dev/null | wc -l)
  if [[ "$QTD" -gt 1 ]] && ! confirmation_confirmed "commit-revisado"; then
    block "Sinalizado: este commit toca $QTD arquivos em $mod/docs/ ou $mod/decisions/ -- confirme que nenhuma explicação foi duplicada entre eles (cada uma mora só no documento dono, o resto aponta) e que cada arquivo tocado foi relido, por completo, contra a própria descrição no topo dele (CLAUDE.md, Fluxo de escrita e revisão de documentação). Se estiver tudo certo, responda com a frase exata 'commit revisado, confirmado'; se encontrar duplicação ou divergência, corrija antes de commitar; se isso for engano de outro tipo, use AUTORIZO-TRAVA: <motivo>."
  fi
done

exit 0
