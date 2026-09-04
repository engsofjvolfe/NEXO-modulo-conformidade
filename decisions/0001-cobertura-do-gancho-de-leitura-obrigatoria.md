# 0001 — Cobertura do gancho de leitura obrigatória

Até aqui, a checagem "os seis documentos de leitura manual obrigatória
já foram lidos?" só rodava antes de escrever ou editar um arquivo.
Investigar (rodar comando, ler outro arquivo) não passava por nenhuma
checagem. Esta decisão faz o gancho novo (`pre_mandatory_reading_guard.sh`)
rodar antes de qualquer ferramenta, liberando só duas: `Read` (o
próprio jeito de cumprir a exigência) e `TodoWrite` (sem efeito fora
da lista de tarefas).

## Status

Aceito.

## Contexto

`CLAUDE.md`, seção "Leitura obrigatória, fonte da verdade": a lista de
seis documentos vale "antes de qualquer outra coisa" -- texto mais
amplo que só "antes de código". O gancho existente
(`pre_edit_safety.sh`) cobria exatamente "antes de código" (Portão pro
Passo 2 do "Fluxo completo de uma tarefa"), nunca o "qualquer outra
coisa" mais amplo do topo do documento. Confirmado ao vivo, na mesma
sessão que motivou esta ADR: rodar `git worktree list`/`git status`
antes de terminar a leitura dos seis documentos não disparava nenhuma
checagem.

Alternativas reais consideradas:
- Deixar como estava (só antes de escrita) -- descartada, porque não
  atende o texto literal do `CLAUDE.md`.
- Um matcher que liste, um por um, todas as ferramentas que devem ser
  bloqueadas -- descartada: pesquisa direta na documentação oficial de
  ganchos do Claude Code confirmou que não existe sintaxe de negação
  (`!Bash`) nem "todas as ferramentas exceto X" no campo `matcher` --
  qualquer lista positiva ficaria desatualizada assim que uma
  ferramenta nova aparecesse.
- Matcher `"*"` (documentação oficial confirma: cobre toda ferramenta,
  sem exceção, quando vazio/omitido/`"*"`) combinado com filtro dentro
  do próprio script, usando o campo `tool_name` (que a documentação
  confirma estar sempre presente no JSON de entrada, independente do
  matcher) -- escolhida.

## Decisão

`pre_mandatory_reading_guard.sh`, ligado a `PreToolUse` com
`"matcher": "*"`, roda antes de toda ferramenta. Dentro do script, só
duas saem sem checagem: `Read` (sem ela, a própria exigência nunca
poderia ser cumprida) e `TodoWrite` (não altera nada fora da lista de
tarefas da sessão -- sem efeito no repositório, no sistema de
arquivos, ou em qualquer serviço externo). Toda outra ferramenta --
`Bash`, `Grep`, `Glob`, `Write`, `Edit`, `Agent`, `WebFetch`,
`WebSearch`, `EnterWorktree`, e qualquer uma nova que apareça depois
-- fica bloqueada até os seis documentos passarem por `Read` completo
nesta sessão. `pre_edit_safety.sh` e `pre_commit_hygiene.sh` continuam
com a mesma checagem nos dois pontos que já cobriam -- redundância
deliberada, mesmo padrão de camadas já usado no resto deste módulo.

## Consequências

- Verificado por teste isolado (fora de uma sessão real, ver
  [`findings.md`](<../docs/findings.md>)): a função compartilhada
  `first_unread_mandatory_doc` (já existente, não alterada) devolve o
  primeiro documento não lido quando o registro está vazio, e nada
  quando os seis já foram lidos -- comportamento correto confirmado.
- Não foi possível confirmar, dentro desta mesma sessão, o bloqueio de
  verdade de uma ferramenta como `Bash` via uma chamada real -- a
  configuração de ganchos parece ser carregada uma vez, no início da
  sessão, antes deste gancho ter sido criado; confirmação ao vivo
  fica para uma sessão nova, depois deste trabalho entrar em
  `develop`. Ver pendência em [`tasks.md`](<../docs/tasks.md>).
- Nenhuma ferramenta além de `Read`/`TodoWrite` foi adicionada à lista
  de exceção -- inclusive `EnterWorktree` fica bloqueada até a leitura
  terminar, o que é mais estrito que o comportamento anterior (antes,
  dava pra criar a worktree antes de ler); combina com o texto literal
  do `CLAUDE.md` ("antes de qualquer outra coisa"), incluindo a
  criação da própria worktree.
