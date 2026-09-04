#!/bin/bash
# user_prompt_submit.sh -- evento: UserPromptSubmit
#
# Roda antes de qualquer mensagem sua ser processada, em toda
# mensagem, sem exceção. Três bilhetes possíveis, cada um consultado
# pelos outros hooks desta mesma resposta -- em vez de cada um
# vasculhar a conversa inteira à procura da frase por conta própria
# (impreciso, podia pegar uma autorização de mensagens atrás por
# engano): "AUTORIZO-TRAVA:" (bypass geral, qualquer gancho), "nada a
# registrar, confirmado" (item 13 de pre_edit_safety.sh, só esse
# item), "sem alternativas reais, confirmado" (itens 14/15 do mesmo
# script, só esses). Autorização geral rejeita o caso em que o texto
# depois de "AUTORIZO-TRAVA:" é só o placeholder do exemplo
# ("<motivo>", sem nada real escrito) -- ver comentário mais abaixo.
#
# Todo bilhete é apagado a cada mensagem nova, tenha ou não a frase
# correspondente -- uma autorização vale só pra tentativa imediata,
# nunca fica "pendurada" indefinidamente.

source "$(dirname "$0")/lib/common.sh"
read_input

PROMPT=$(field '.prompt')

# Achado ao vivo nesta rodada: uma mensagem que só CITA a frase
# "AUTORIZO-TRAVA: <motivo>." -- por exemplo, colando o texto de um
# gancho de bloqueio, que usa esse padrão como exemplo de como usar a
# autorização -- batia neste grep e liberava a sessão inteira sem
# nenhuma decisão real da pessoa. Antes de aceitar, exige que o texto
# depois de "AUTORIZO-TRAVA:" NÃO COMECE com o placeholder literal
# "<motivo>" -- placeholder no início nunca é autorização de verdade,
# é o padrão do exemplo reaparecendo, mesmo com mais texto depois (ex.:
# ". valeu", ou o resto do gancho colado). Uma autorização legítima
# nunca começa dessa forma. Achado a mais, na mesma rodada: a primeira
# versão desta correção exigia que o texto inteiro fosse só
# "<motivo>" (com `$` no fim do padrão) -- não bastava, porque o texto
# capturado quase sempre tem algo depois (o resto da frase onde o
# exemplo apareceu colado). Corrigido pra checar só o início.
if echo "$PROMPT" | grep -q "AUTORIZO-TRAVA:"; then
  MOTIVO=$(echo "$PROMPT" | grep -o "AUTORIZO-TRAVA:.\{1,300\}" | head -n 1)
  RAZAO_LIMPA=$(echo "$MOTIVO" | sed -E 's/^AUTORIZO-TRAVA:[[:space:]]*//')
  # Segundo achado, na mesma família de problema (a mensagem só CITA a
  # frase, sem intenção real de autorizar agora): o placeholder
  # "<motivo>" não é o único jeito de citar a frase sem querer usá-la
  # de verdade -- uma mensagem contando o que aconteceu numa sessão
  # anterior ("...só desbloqueou quando você escreveu AUTORIZO-TRAVA:
  # ....") também batia no grep acima, com um "motivo" que não é
  # motivo nenhum (só reticências, "...."), seguido do resto da frase
  # da pessoa contando a história ("Isso sugere que..."). Reproduzido
  # ao vivo nesta rodada. Uma primeira tentativa de correção (exigir 4
  # letras em qualquer lugar do texto capturado) não bastou -- o resto
  # da frase, contando a história, quase sempre tem letras de sobra,
  # então quase nunca rejeitava nada; testado isoladamente, confirmado
  # que passava batido. Corrigido pra checar só o início, mesmo
  # princípio já usado pro placeholder: reticências (duas ou mais
  # reticências, "..") logo no começo do texto, antes de qualquer
  # letra, também nunca é motivo real -- é o mesmo padrão de "citação
  # sem conteúdo" do placeholder, só com pontuação diferente.
  if echo "$RAZAO_LIMPA" | grep -qiE '^<[[:space:]]*motivo[[:space:]]*>' || echo "$RAZAO_LIMPA" | grep -qE '^\.{2,}'; then
    : > "$AUTH_FILE"
    log_override "user_prompt_submit" "IGNORADO -- sem motivo real escrito: $MOTIVO"
  else
    echo "$MOTIVO" > "$AUTH_FILE"
    log_override "user_prompt_submit" "$MOTIVO"
    echo "Autorização registrada para esta mensagem: $MOTIVO"
  fi
else
  : > "$AUTH_FILE"
fi

# Confirmação pontual pra cada ponto de checagem que só um humano pode
# resolver (nunca eu sozinho, nunca a resposta anterior de outra
# sessão) -- mais estreita que AUTORIZO-TRAVA (resolve só aquele ponto
# específico, nunca libera o resto do gancho). Tabela, não um "if" por
# frase: um ponto de checagem novo (ver pre_edit_safety.sh,
# pre_commit_hygiene.sh) só precisa de uma linha nova aqui, nunca de
# copiar este bloco inteiro de novo. Mesma regra de não ficar
# "pendurada": todo arquivo listado é limpo a cada mensagem nova,
# escrito só quando a frase exata aparece NESTA mensagem sua.
#
# Achado ao vivo nesta rodada: a vírgula literal, dentro da frase
# exigida (ex.: "commit revisado, confirmado"), é fácil de esquecer ao
# digitar de cabeça -- uma tentativa real, faltando só essa vírgula
# ("commit revisado confirmado"), não bateu com a comparação exata
# (grep -qi de string literal) e não destravou nada, sem nenhum aviso
# de "quase bateu, faltou a vírgula". Mesma família de problema do
# achado sobre AUTORIZO-TRAVA (checagem rígida demais pra pequena
# variação de digitação). Corrigido: a vírgula de cada frase vira
# opcional na comparação (`,?` numa expressão regular, no lugar da
# string literal) -- continua exigindo o resto das palavras, na ordem,
# só a pontuação entre elas fica tolerante.
CONFIRMATION_PHRASES=(
  "nada a registrar, confirmado|no-finding"
  "sem alternativas reais, confirmado|no-adr"
  "tom impessoal confirmado, sem violacao|tom-impessoal"
  "sem duplicacao de conteudo, confirmado|sem-duplicacao"
  "commit revisado, confirmado|commit-revisado"
)
for par in "${CONFIRMATION_PHRASES[@]}"; do
  frase="${par%%|*}"
  nome="${par##*|}"
  arquivo="${CONFIRM_DIR}/${nome}"
  frase_regex=$(echo "$frase" | sed -E 's/, /,? */g')
  if echo "$PROMPT" | grep -qiE "$frase_regex"; then
    echo "confirmado" > "$arquivo"
    log_override "user_prompt_submit" "$frase"
  else
    : > "$arquivo"
  fi
done

exit 0
