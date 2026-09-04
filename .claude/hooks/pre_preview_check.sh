#!/bin/bash
# pre_preview_check.sh -- evento: PreToolUse, filtro: Bash(*preview-up.sh*)
#
# Antes de testar no preview isolado, confirma que a documentação já
# foi escrita pra qualquer código novo ou alterado nesta sessão --
# CLAUDE.md, Passo 3: "documentação vem antes do teste". Substitui um
# gancho do tipo "agent" (segunda inteligência artificial, chamada à
# parte) que fazia essa mesma checagem lendo git status/diff -- ela
# usava um formato de resposta que este tipo de gancho não reconhece
# pra bloquear de verdade (achado no arquivo de achados do módulo
# conformidade), então nunca travava. Aqui o mesmo fato -- código
# tocado (edicao.*) sem os documentos de desenho do módulo tocados
# junto -- é checado por script puro, reaproveitando a mesma ficha
# (síntese) que pre_edit_safety.sh já mantém, sem precisar chamar
# nenhuma IA.

source "$(dirname "$0")/lib/common.sh"
read_input

COMMAND=$(field '.tool_input.command')
CWD=$(normalize_path "$(field '.cwd')")

# Auto-portão: mesmo motivo do auto-portão em pre_commit_hygiene.sh --
# o filtro "if" do settings.json falha aberto em comando não
# totalmente parseável.
if ! echo "$COMMAND" | grep -Eq 'preview-up\.sh'; then
  exit 0
fi

if is_authorized; then
  log_override "pre_preview_check" "$(authorized_reason)"
  exit 0
fi

# Módulo com código alterado (via git, não commitado ainda) mas sem os
# dois documentos de desenho (o que o módulo deve ser, e como ele é
# construído por dentro) tocados nesta sessão (edicao.*, mesma fonte
# que o restante do sistema já usa) -- sinal, não certeza (mudança de
# código pode não exigir doc nova), por isso autorizável.
#
# "git diff" sozinho só lista arquivo já rastreado e modificado --
# achado ao vivo, testando este script: um arquivo de código novo
# (nunca commitado, "untracked" pro git) não aparece ali, então um
# módulo inteiro novo, feito nesta sessão, passava por baixo desta
# checagem. "git status --porcelain --untracked-files=all" cobre os
# dois casos (modificado e novo) na mesma chamada. Segundo achado ao
# vivo, na mesma rodada de teste: sem excluir docs/, schemas/ e
# decisions/, editar o próprio documento de conceito do módulo contava
# como "código alterado" e disparava a checagem contra si mesma --
# mesma exclusão que IS_CODE já usa em pre_edit_safety.sh, item 5.
MODULOS_COM_CODIGO=$(git -C "$CWD" status --porcelain --untracked-files=all -- 'modulos/*' 2>/dev/null | awk '{print $2}' | grep -Ev '/docs/|/schemas/|/decisions/' | sed -E 's#(modulos/[^/]+)/.*#\1#' | grep -v '^modulos/_template$' | sort -u)
for mod in $MODULOS_COM_CODIGO; do
  MOD_NOME=$(basename "$mod")
  CONCEPT_TOCADO=false; [[ -n "$(synthesis_age "edicao.${MOD_NOME}.concept")" ]] && CONCEPT_TOCADO=true
  ARCH_TOCADO=false; [[ -n "$(synthesis_age "edicao.${MOD_NOME}.architecture")" ]] && ARCH_TOCADO=true
  if ! $CONCEPT_TOCADO && ! $ARCH_TOCADO; then
    block "Sinalizado: $mod tem código alterado nesta sessão, mas nem o documento de conceito nem o de arquitetura desse módulo foram tocados -- CLAUDE.md, Passo 3: documentação vem antes do teste. Se a mudança realmente não precisa de documentação nova, use AUTORIZO-TRAVA: <motivo>; senão, escreva a documentação antes de testar."
  fi
done

exit 0
