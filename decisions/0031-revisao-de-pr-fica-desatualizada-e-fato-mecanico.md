# ADR 0031 — Revisão de PR desatualizada é fato mecânico (retroativa)

*Em resumo:* antes de abrir um PR (`gh pr create`), o projeto exige
rodar a revisão por assistentes (`/revisar-pr`). Confirmar que essa
revisão de fato aconteceu, e não ficou desatualizada por uma edição
depois dela, é uma comparação de duas marcas de tempo — fato puro, sem
julgamento nenhum envolvido, então vira script que confere, sem
segunda inteligência artificial. ADR retroativa: a decisão já estava
implementada (`pre_pr_review_check.sh`), sem registro formal.

## Status

Aceito.

## Contexto

Antes desta trava, nada impedia abrir um PR sem revisão nenhuma, ou
com revisão feita antes da última edição da tarefa (revisão
desatualizada, sem saber do que mudou depois).

A pergunta em si -- "a revisão está em dia?" -- não exige entender o
conteúdo de nada, só comparar duas marcas de tempo: a última linha do
diário de edição (`edit-order.log`) contra a última linha do diário de
revisão de PR (`pr-review-log.txt`). Isso é fato objetivo.

Alternativas reais consideradas:

- **Confiar em lembrança de quem conduz a sessão** -- descartada: é
  exatamente o tipo de coisa que texto sozinho, sem trava, tende a ser
  esquecido (mesmo raciocínio de todo o resto deste módulo).
- **Gancho `agent`, julgamento por segunda inteligência artificial** --
  descartada: a pergunta não precisa de julgamento nenhum, só
  comparação de data -- usar uma segunda inteligência artificial pra
  algo que já dá pra confirmar como fato adiciona custo e risco sem
  ganho (mesmo princípio já usado em outras decisões deste módulo:
  fato mecânico vira script, nunca pergunta de IA).
- **Script comum, comparando as duas marcas de tempo, com auto-portão
  contra falha do filtro `if`** -- escolhida.

## Decisão

`pre_pr_review_check.sh` -- gancho comum (`type: command`), evento
`PreToolUse`, filtro `Bash(gh pr create *)`. Confirma o próprio
padrão do comando de novo (auto-portão, mesmo padrão de
decisions/0011), depois compara a última linha de `edit-order.log`
contra a última linha de `pr-review-log.txt`: sem revisão nenhuma
registrada, bloqueia; revisão anterior à última edição, bloqueia;
revisão em dia, libera.

## Consequências

- Nenhum PR abre sem revisão registrada e em dia, a não ser por
  `AUTORIZO-TRAVA`.
- Teste ao vivo, numa sessão nova, segue pendência já registrada em
  `tasks.md` (confirmação dos quatro revisores de PR e deste gancho
  juntos).
