# 0011 — Auto-portão contra falha aberta do filtro `if`

*Em resumo:* o campo `if` do `settings.json`, que restringe um gancho
(ex.: `pre_commit_hygiene.sh`) a rodar só quando o comando bate com um
padrão (ex.: `Bash(git commit *)`), tem uma falha documentada: quando o
comando não é totalmente interpretável pelo mecanismo interno do
Claude Code, o filtro roda o gancho mesmo assim, em vez de pular. Cada
gancho que depende de `if` pra saber "sou eu que devo rodar agora"
passa a confirmar isso de novo, sozinho, dentro do próprio script ou
prompt -- sem depender só do `if` pra estar correto.

**Status:** aceito.

**Contexto:** ao testar a checagem de emoji recém-movida pro momento
da edição, um comando qualquer (sem nenhum `git commit`) disparou o
bloqueio de emoji de `pre_commit_hygiene.sh`, um gancho com
`"if": "Bash(git commit *)"`. Consulta direta à documentação oficial
do Claude Code (`code.claude.com/docs/en/hooks`) confirmou o
mecanismo: "the filter also fails open, running your hook regardless
of pattern, when the Bash command can't be parsed" -- comandos
compostos, com aspas aninhadas ou heredoc (comuns nos testes deste
próprio módulo) disparam essa falha com facilidade. Os quatro ganchos
deste projeto que usam `if` sobre o matcher `Bash`
(`pre_commit_hygiene.sh`, os dois `if` de `pre_git_rules.sh`, e os
dois ganchos `agent` -- revisão de commit e revisão de preview) ficam,
todos, sujeitos a rodar em comandos que nada têm a ver com o padrão
que o `if` deveria restringir.

**Decisão:** cada gancho que usa `if` sobre o matcher `Bash` passa a
confirmar, como primeiro passo, se o comando de verdade bate com o
padrão que o `if` deveria garantir -- sem depender só do `if` pra
correção:
- `pre_commit_hygiene.sh`: linha nova, logo no início, que sai (`exit
  0`) se `$COMMAND` não contém `git commit` como subcomando real.
  `pre_git_rules.sh` já fazia isso, por acaso -- cada checagem interna
  dele já re-verifica o padrão específico (`git merge`, `git commit`,
  `gh pr create`, etc.) no texto do comando antes de agir, então
  nenhuma mudança foi necessária ali.
- Os dois ganchos `agent` (revisão de commit, revisão de preview):
  instrução nova, como primeiro passo do prompt, pra checar
  `tool_input.command` dentro de `$ARGUMENTS` e, se não for de fato
  uma chamada real ao comando esperado, responder `permissionDecision:
  allow` e parar -- sem gastar o resto do julgamento (até 150-180s de
  IA) num comando que não é da conta daquele gancho.

**Consequências:** a correção em `pre_commit_hygiene.sh` foi testada
isoladamente (JSON fabricado via stdin, fora do fluxo real de um
gancho) -- ver [findings.md](<../docs/findings.md>). A instrução nova
nos dois ganchos `agent` não pôde ser confirmada ao vivo dentro desta
mesma sessão (mesma limitação já registrada em
[pitfalls.md](<../docs/pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)):
ganchos do tipo `agent` não têm um script isolável pra testar fora do
fluxo real, então a confirmação de ponta a ponta desses dois fica
pendência aberta em [tasks.md](<../docs/tasks.md>). Este auto-portão
não substitui o `if` -- continua existindo pra evitar o custo de rodar
o script/prompt à toa nos casos em que o `if` funciona; só deixa de
ser a única garantia de correção.
