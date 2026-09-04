# 0008 — Formato de bloqueio nos ganchos de julgamento do `Stop`, com limite reconhecido

Os ganchos que revisam a resposta por julgamento (não fato puro) no
evento `Stop` — dois `agent`, um `prompt` — pediam pro modelo responder
`{"ok": false, "reason": "..."}`, formato que o Claude Code não
reconhece: nunca impediu a resposta de terminar. Esta decisão troca o
formato pedido pelo melhor candidato documentado
(`hookSpecificOutput.decision`), mantendo os três ganchos (não
removendo nenhum), e registra por escrito que essa capacidade
continua sem confirmação.

## Status

Aceito.

## Contexto

Pesquisa direta na documentação oficial do Claude Code (três consultas
distintas, focadas neste ponto específico) confirmou, com certeza:
`{"ok": false, "reason": "..."}` não é um formato reconhecido em
nenhum evento — é só texto que aparece, nunca decisão de bloqueio.
Também confirmou, com certeza, o formato real de bloqueio pra
`PreToolUse` (`hookSpecificOutput.permissionDecision`, ver
[decisions](.) desta mesma rodada nos dois ganchos `agent` que revisam
`git commit`/preview). Já pra `Stop`, especificamente quando o gancho é
`agent`/`prompt` (não `command`), as três consultas trouxeram respostas
parcialmente contraditórias: uma mostrou um exemplo com
`hookSpecificOutput.decision: "continue"`; outra afirmou que
`agent`/`prompt` no `Stop` só suportam `additionalContext`/
`systemMessage`, sem bloqueio; uma terceira afirmou que bloqueiam
igual a `command`, sem citar o trecho literal da documentação. A
própria documentação marca esse tipo de gancho como "experimental" e
não mostra, em nenhuma das consultas, um exemplo literal de bloqueio
específico pra essa combinação (gancho `agent`/`prompt` + evento
`Stop`).

Alternativas reais consideradas:
- Manter o formato antigo (`ok`/`reason`) — descartada: confirmado, sem
  ambiguidade nenhuma, que nunca bloqueou nada.
- Remover os três ganchos de julgamento do `Stop`, confiando só em
  `stop_fact_check.sh` (fatos mecânicos,
  [decisions/0007](<0007-bloqueio-real-dos-fatos-mecanicos-do-evento-stop.md>))
  e nos ganchos `agent` de `PreToolUse` (que bloqueiam com certeza) —
  descartada: perderia de vez a checagem das perguntas que exigem
  entendimento (documentos gerais da raiz coerentes com a sessão,
  significância pro `HANDOFF.md`, instrução do usuário esquecida,
  clareza do PR, tom/emoji da resposta) — nenhuma dessas é fato puro,
  não dá pra mover pra um script comum.
- Trocar pro formato mais bem documentado
  (`hookSpecificOutput.decision: "continue"`), mantendo os três
  ganchos, e escrever a incerteza remanescente como limite reconhecido
  (mesmo padrão já usado em `MANUAL.md`, seção 10, e neste
  `concept.md`) — escolhida: custo zero (se não bloquear, o
  comportamento não piora em nada frente ao que já era antes), ganho
  potencial real, sem fingir uma certeza que a própria documentação
  oficial não sustenta.

## Decisão

Os três ganchos de julgamento do `Stop` (dois `agent`, um `prompt`,
`.claude/settings.json`) passam a pedir a resposta final em
`{"hookSpecificOutput": {"hookEventName": "Stop", "decision":
"continue", "reason": "..."}}` quando algo precisa ser corrigido ou
perguntado, e nada (ou só `systemMessage`, sem `decision`) quando está
tudo certo. Cada prompt leva uma nota explícita de que esse mecanismo
é experimental e pode não bloquear de verdade. `stop_fact_check.sh`
([decisions/0007](<0007-bloqueio-real-dos-fatos-mecanicos-do-evento-stop.md>))
continua como a garantia de verdade pros três fatos mecânicos —
independente do resultado desta decisão.

## Consequências

- Sem piora possível: o formato antigo nunca bloqueava; o novo, na
  pior hipótese (a documentação estar certa em dizer que
  `agent`/`prompt` não bloqueiam o `Stop`), continua não bloqueando --
  mas, se a hipótese otimista estiver certa, passa a bloquear de
  verdade, sem custo adicional.
- Limite reconhecido, documentado em
  [`concept.md`, Limites reconhecidos](<../docs/concept.md#limites-reconhecidos>)
  — a garantia de bloqueio real do evento `Stop`, até confirmação ao
  vivo, é só `stop_fact_check.sh` (fato mecânico); a checagem de
  julgamento continua no melhor esforço.
- Pendência nova: confirmar ao vivo, numa sessão nova, se
  `hookSpecificOutput.decision: "continue"` bloqueia de verdade um
  gancho `agent`/`prompt` no evento `Stop` — ver
  [tasks.md](<../docs/tasks.md>). Confirmado, esta ADR ganha nota de
  acompanhamento; recusado (nunca bloqueia), a alternativa descartada
  acima (mover pra fato mecânico o que for possível, aceitar o resto
  como puramente informativo) volta à mesa.
