# 0004 — Checagem de instruções do usuário no gancho de Stop já existente

Não existia nenhum mecanismo que conferisse, ao final de uma resposta,
se toda instrução específica dada pelo usuário numa tarefa detalhada
foi realmente atendida, sem nada pulado. Esta decisão acrescenta essa
checagem dentro do gancho de `Stop` que já fazia perguntas de
julgamento parecidas, em vez de criar um gancho `agent` novo e
separado.

## Status

Aceito.

## Contexto

Pedido direto: instrução dada no meio de uma mensagem longa, com
vários pedidos e condições, é o tipo de coisa que passa despercebida
sem uma releitura item a item. Essa pergunta ("o que o usuário pediu,
que eu talvez tenha pulado?") é julgamento -- depende de entender
linguagem natural, não é fato mecânico -- e o próprio `MANUAL.md`
(seção 1) já estabelece que julgamento nunca é decidido por um script
sozinho, vira pergunta explícita.

Alternativas reais consideradas:
- Gancho `agent` novo, próprio, só pra essa checagem -- descartada:
  `MANUAL.md`, seção 9.6, já registra que o evento `Stop` dispara em
  toda resposta, e que multiplicar chamadas de agente (custo + tempo
  de espera) nesse evento já foi identificado como problema real
  antes -- o campo `if` (que poderia pular um gancho por condição) só
  funciona em evento de ferramenta, nunca em `Stop`, confirmado na
  documentação oficial -- não dá pra pular a chamada nova em resposta
  trivial.
- Acrescentar a pergunta dentro do gancho `agent` já existente que
  faz perguntas de julgamento parecidas (significância pro
  `HANDOFF.md`, necessidade de produção, clareza do PR) -- escolhida:
  mesma categoria de pergunta (julgamento sobre completude da entrega),
  sem aumentar o número de chamadas de agente por resposta.

## Decisão

O prompt do segundo gancho de `Stop` (o que já checava `HANDOFF.md`/
produção/PR) ganha uma pergunta nova: reler todas as mensagens do
usuário na sessão (não só a última), listar cada instrução concreta
contida em qualquer mensagem que descreveu a tarefa com detalhe, e
confirmar, uma a uma, se foi atendida -- sem presumir completude só
porque a resposta final parece caprichada. Qualquer instrução sem
confirmação clara entra no `reason`, nomeada, nunca decidida sozinha.

## Consequências

- Não foi possível confirmar esta pergunta rodando de verdade dentro
  desta mesma sessão -- a sessão em que foi escrita já estava em modo
  de permissão restrito ("don't ask mode"), que impediu o próprio
  gancho de `Stop` de ler os arquivos que precisava pra concluir a
  checagem (ver [`tasks.md`](<../docs/tasks.md>)). Fica pendente
  confirmar, numa sessão sem essa restrição, que a pergunta nova
  aparece de fato e nomeia instrução esquecida quando existir uma de
  verdade.
- Aumenta o tamanho do prompt do gancho existente, sem aumentar o
  número de chamadas -- custo adicional é só de tokens lidos pelo
  próprio modelo que já rodava, não uma chamada nova.
