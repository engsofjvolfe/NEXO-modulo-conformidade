# ADR 0032 — Worktree nova liga pastas locais por atalho no próprio evento de criação (retroativa)

*Em resumo:* uma worktree nova (cópia de trabalho isolada pra uma
tarefa) não enxerga, sozinha, as pastas que ficam de propósito fora do
controle de versão (ver decisions/0021) -- precisa de um atalho de
pasta criado assim que ela nasce. `worktree_create_setup.sh` faz isso
no próprio evento nativo do Claude Code que marca a criação. ADR
retroativa: a decisão já estava implementada, sem registro formal.

## Status

Aceito.

## Contexto

`git worktree add` só traz conteúdo já registrado no controle de
versão -- nenhuma pasta local (fora do controle de versão) chega
sozinha numa worktree nova. Sem correção, cada worktree nova ficaria
sem essas pastas até alguém lembrar de ligar o atalho à mão.

O Claude Code dispara um evento nativo (`WorktreeCreate`) quando cria
uma worktree pelo próprio mecanismo dele (a ferramenta que o fluxo
deste módulo usa) -- ponto natural pra rodar a mesma função que já
resolve esse problema em outro contexto (`ensure_worktree_links`,
decisions/0021).

Limite reconhecido, documentado no próprio arquivo: esse evento
dispara de forma confiável só quando a worktree nasce pelo mecanismo
próprio do Claude Code -- `git worktree add` digitado à mão no
terminal pode não disparar esse evento. Por isso existe um reforço
independente, em `pre_mandatory_reading_guard.sh` (roda em toda
ferramenta, dentro de qualquer worktree), que cobre o caminho manual
mesmo se este evento nunca disparar ali.

Alternativas reais consideradas:

- **Só o reforço em `pre_mandatory_reading_guard.sh`, sem gancho
  próprio no evento de criação** -- descartada: esse reforço só roda
  na primeira ferramenta usada dentro da worktree, atraso desnecessário
  quando existe um evento dedicado pra esse momento exato.
- **Gancho próprio no evento `WorktreeCreate`, chamando a mesma função
  já usada em outro contexto** -- escolhida: sem duplicar lógica, cobre
  o caminho comum (criação pelo mecanismo do Claude Code) no momento
  certo; o caminho manual, mais raro, já tem cobertura própria.

## Decisão

`worktree_create_setup.sh` -- gancho comum (`type: command`), evento
`WorktreeCreate`. Lê o caminho da worktree nova do JSON de entrada e
chama `ensure_worktree_links`, a mesma função já usada pra esse fim.

## Consequências

- Worktree nova, criada pelo mecanismo próprio do Claude Code, já
  nasce com as pastas locais ligadas, sem esperar a primeira ferramenta
  rodar.
- Limite do evento (não disparar em `git worktree add` manual)
  permanece documentado no próprio arquivo, coberto pelo reforço em
  `pre_mandatory_reading_guard.sh`.
- Teste ao vivo, numa sessão nova, segue como pendência em `tasks.md`.
