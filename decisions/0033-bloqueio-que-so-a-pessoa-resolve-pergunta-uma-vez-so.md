# ADR 0033 — Bloqueio que só a pessoa resolve pergunta uma vez só

*Em resumo:* o evento `Stop` (fim da resposta), quando bloqueado, obriga
a resposta a continuar -- e continuar dispara o mesmo evento `Stop` de
novo. Pra fato que a própria resposta consegue corrigir sozinha (ex.:
emoji no texto), isso é o comportamento certo: insistir até corrigir.
Mas pra pergunta que só a pessoa conduzindo a sessão sabe responder
(autorização pendente, "isso é significativo o bastante?", "precisa ir
pra produção?"), o mesmo mecanismo virava um laço sem saída: a resposta
nunca consegue corrigir sozinha o que só a pessoa decide, então o
bloqueio se repetia sem parar, cada volta escrevendo alguma coisa nova,
sem nenhuma mensagem real da pessoa no meio -- o oposto de "perguntar e
esperar" que uma conversa normal tem.

## Status

Aceito.

## Contexto

Relatado ao vivo, repetidas vezes ao longo desta sessão: depois de um
gancho de julgamento perguntar algo, e a pessoa não responder de
imediato, a resposta seguinte só dizia "sem instrução nova" (ou
equivalente) -- mas o evento `Stop` disparava de novo sobre essa
resposta mínima, encontrava a mesma pergunta sem resposta, bloqueava
de novo, e a sessão gerava outra resposta mínima, em ciclo, por muitas
voltas seguidas, sem a pessoa ter feito nada.

A causa raiz: o desenho de bloqueio até então (usado nos quatro pontos
de julgamento do fim da resposta, e em `stop_fact_check.sh`) tratava
"pergunta sem resposta" do mesmo jeito que "coisa errada não
corrigida" -- os dois bloqueavam sem distinção, sempre que a condição
continuasse verdadeira. Mas as duas situações pedem reação diferente:
algo que a resposta corrige sozinha (emoji, por exemplo) deve continuar
bloqueando até corrigido de verdade; algo que só a pessoa resolve
(digitar `AUTORIZO-TRAVA`, responder uma pergunta de julgamento) nunca
vai se resolver só porque a resposta insiste -- insistir só produz
texto novo sem necessidade, sem nunca deixar a sessão parar de
verdade pra esperar.

Alternativas reais consideradas:

- **Manter como estava, esperando a pessoa perceber e responder em
  algum momento** -- descartada: é o próprio problema relatado -- a
  sessão fica gerando resposta atrás de resposta, sem nunca ficar
  genuinamente parada, esperando.
- **Parar de bloquear esses pontos no evento `Stop`, mover pra um aviso
  simples no texto da resposta** -- descartada: perde a garantia de que
  a pergunta realmente aparece pra pessoa -- hoje o bloqueio é o que
  torna a pergunta impossível de ignorar por engano.
- **Cada ponto pergunta uma vez, marca que já perguntou, libera o resto
  das vezes até uma mensagem nova de verdade chegar** -- escolhida: a
  pergunta continua aparecendo, garantida, na primeira vez -- depois
  disso, a resposta termina de verdade e a sessão fica parada,
  esperando, sem gerar texto à toa. Mensagem nova da pessoa reabre a
  possibilidade de perguntar de novo, porque essa mensagem pode ter
  mudado a situação.

## Decisão

Novo par de funções em `lib/common.sh`: `question_already_asked(nome)`
(lê `.claude/hooks/state/pending-question/<nome>`) e
`mark_question_asked(nome, motivo)` (escreve nesse mesmo arquivo).
`user_prompt_submit.sh` apaga toda a pasta `pending-question/` em toda
mensagem nova de verdade (mesma regra de não ficar "pendurado" que já
vale pra `AUTORIZO-TRAVA`).

Cinco pontos passam a usar esse par: `stop_fact_check.sh` (fato
puramente mecânico, mas cuja correção -- commitar, remover worktree,
trocar base do PR -- é decisão da pessoa, nunca decidida sozinha
aqui), e os três pontos que usam uma segunda inteligência artificial
no evento `Stop` (as duas checagens do fim da resposta, e a checagem
de termo técnico -- essa última convertida de tipo `prompt` pra tipo
`agent`, pra garantir acesso real à ferramenta Read/Bash necessária
pra essa checagem, incerto no tipo anterior). O quarto ponto de
julgamento (revisão de edição de documento, evento `PreToolUse`) não
entra aqui -- não é do evento `Stop`, não sofre do mesmo laço (um
bloqueio de `PreToolUse` não força a resposta a continuar sozinha, só
devolve um erro pra ferramenta que tentou rodar).

`stop_emoji_check.sh` fica de fora de propósito -- emoji é algo que a
própria resposta corrige sozinha, então continuar bloqueando até
corrigido de verdade é o comportamento certo ali.

## Consequências

- `bash -n` sem erro em `lib/common.sh`, `user_prompt_submit.sh` e
  `stop_fact_check.sh`; `jq empty` sem erro em `.claude/settings.json`.
- Teste ao vivo, numa sessão nova, ainda pendente -- ver `tasks.md`.
- Risco reconhecido: se a pergunta feita na primeira vez ainda for
  relevante depois de uma mensagem nova da pessoa que não a resolveu
  de verdade (ex.: uma mensagem sobre outro assunto), o ponto volta a
  perguntar -- comportamento aceito de propósito, porque não perguntar
  de novo correria o risco maior de nunca mais perguntar nada.
