# ADR 0017 — Comandos git/gh isentos da leitura manual obrigatória

*Em resumo:* comandos de controle de versão (`git`/`gh` -- status,
commit, push, pull, abrir PR, etc.) deixam de depender de ter lido os
seis documentos manuais obrigatórios primeiro. As regras de segurança
específicas de git (nunca reescrever `develop`/`main`, merge sempre
com `--no-ff`, entre outras) continuam valendo do mesmo jeito, com o
mesmo `AUTORIZO-TRAVA` de sempre pra quem quiser pular alguma delas.

## Status

Aceito.

## Contexto

Pedido explícito de quem conduz a sessão: a leitura manual obrigatória
não precisa ter acontecido antes de comandos `git`/`gh` -- são passo
mecânico de controle de versão, não decisão sobre conteúdo do projeto
-- com a ressalva de que qualquer outra liberação de bloqueio, fora
dessa isenção, continua exigindo `AUTORIZO-TRAVA` digitado por quem
conduz a sessão, nunca decidido automaticamente.

Alternativas reais consideradas:

- **Isenção estreita, só pra commit/push/pull/abrir PR** -- descartada:
  o próprio pedido citou "etc.", e a queixa original (achado de
  28-08-2026,
  [findings.md](<../docs/findings.md#2026-08-28-frase-de-confirmacao-cadastrada-mas-nunca-usada>))
  já registrava a janela expirando antes de comandos simples, só de
  leitura, como conferir um PR -- uma lista fechada de subcomandos
  deixaria de fora exatamente esse tipo de caso.
- **Isenção ampla: qualquer comando Bash que contenha a palavra `git`
  ou `gh`** -- escolhida: cobre o ciclo git inteiro (inclusive
  inspeção, como `git status`/`git log`/`gh pr view`), sem exigir
  manter uma lista de subcomandos sincronizada.
- **Automação total (nenhuma marca no código, decisão implícita)** --
  descartada: a isenção fica registrada, permanente e visível, direto
  no código do gancho -- decisão tomada uma vez, por quem conduz a
  sessão, não uma liberação ad-hoc a cada chamada.

## Decisão

Em `pre_mandatory_reading_guard.sh`, antes de qualquer checagem de
leitura obrigatória: se a ferramenta é `Bash` e o comando contém a
palavra `git` ou `gh` (delimitada por borda de palavra -- não confunde
com "digital" ou "though", por exemplo), o gancho libera (`exit 0`)
sem checar os seis documentos. Nenhuma outra checagem deste ou de
qualquer outro gancho muda -- `pre_git_rules.sh` e
`pre_commit_hygiene.sh` continuam com as próprias regras de segurança,
autorizáveis só por `AUTORIZO-TRAVA` digitado por quem conduz a sessão.

## Consequências

- Sintaxe conferida com `bash -n` -- sem erro.
- Testado isoladamente: `git status` e `gh pr create` liberam mesmo
  sem nenhum documento lido; um comando comum, sem `git`/`gh`, continua
  bloqueado; `Read` de um documento fora da lista continua bloqueado
  (a isenção é só pra `Bash`).
- Achado no caminho: a primeira versão usava o nome de variável
  `BASH_COMMAND`, que colide com uma variável especial do próprio
  Bash -- ver
  [pitfalls.md](<../docs/pitfalls.md#2026-08-29-nome-de-variavel-colide-com-variavel-especial-do-bash>).
