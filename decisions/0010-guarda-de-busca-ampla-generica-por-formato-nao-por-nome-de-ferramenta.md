# 0010 — Guarda de busca ampla genérica, por formato de entrada, não por nome de ferramenta

`pre_bash_search_guard.sh` cobria `grep`/`find`/`sed -n`/`ls` amplo
usados via `Bash` como substituto de `Grep`/`Glob`. A ferramenta
`PowerShell`, com os mesmos equivalentes (`Select-String`,
`Get-ChildItem -Recurse`), ficava sem cobertura -- e qualquer
ferramenta nova de comando livre que viesse a existir no futuro
ficaria com o mesmo furo. Esta decisão troca dois (ou mais) ganchos
por nome de ferramenta por um só, genérico, reconhecendo o formato da
chamada em vez do nome dela.

## Status

Aceito.

## Contexto

Primeira correção tentada nesta sessão: um script novo,
`pre_powershell_search_guard.sh`, ligado só a `"matcher": "PowerShell"`,
espelhando `pre_bash_search_guard.sh` (ligado só a `"matcher": "Bash"`).
Apontado diretamente que isso repete o mesmo erro estrutural, só que
duplicado: cada ferramenta nova capaz de rodar comando livre (hoje
`Bash` e `PowerShell`; no futuro, qualquer outra) exigiria mais um
gancho, por nome, pra sempre correr atrás -- exatamente o padrão que
`pre_mandatory_reading_guard.sh` já evita há mais tempo, usando
`"matcher": "*"` (cobre toda ferramenta, sem lista fixa de nomes) com
o filtro de verdade dentro do próprio script.

Alternativas reais consideradas:
- Manter um gancho por nome de ferramenta (`Bash`, e agora também
  `PowerShell`) -- descartada: é o próprio problema que motivou esta
  ADR, e não fecha o caso de uma ferramenta nova ainda não prevista.
- `"matcher": "*"`, script único, decidindo internamente por
  `tool_name` (uma lista de nomes conhecidos: `Bash`, `PowerShell`) --
  descartada: ainda amarra a checagem a uma lista de nomes, só que
  dentro do script em vez de dentro do `matcher` -- mesma fragilidade,
  outro lugar.
- `"matcher": "*"`, script único, decidindo pela **forma** da chamada
  (existe `tool_input.command`? -- o campo que qualquer ferramenta de
  comando livre expõe, independente do nome dela) em vez do nome da
  ferramenta -- escolhida: cobre `Bash`, `PowerShell`, e qualquer
  ferramenta futura com o mesmo formato, sem precisar saber o nome
  dela de antemão.

## Decisão

`pre_bash_search_guard.sh` e o recém-criado
`pre_powershell_search_guard.sh` removidos; substituídos por
`pre_search_guard.sh`, ligado a `PreToolUse` com `"matcher": "*"`.
Primeira linha de lógica: sai imediatamente (sem checar nada) se a
chamada não tiver `tool_input.command` -- isso já exclui `Read`,
`Write`, `Edit`, `WebFetch` e qualquer ferramenta que não aceite
comando de texto livre, sem precisar nomeá-las. Pra chamadas que têm
esse campo, aplica os dois conjuntos de padrão (sintaxe Unix --
`grep`/`find`/`sed -n`/`ls` -- e sintaxe PowerShell --
`Select-String`/`Get-ChildItem -Recurse`/`Get-Content -Pattern`/`dir`)
ao mesmo tempo, já que não há como saber de antemão qual sintaxe o
comando vai usar sem primeiro saber a ferramenta -- checar as duas
juntas é mais simples e mais completo do que decidir com base no nome
recebido.

## Consequências

- Fecha o caminho que permitia contornar a proibição de busca ampla
  trocando de ferramenta de terminal -- inclusive uma ainda não
  prevista hoje, sem exigir gancho novo quando ela aparecer (contanto
  que aceite `tool_input.command`, formato já usado por `Bash` e
  `PowerShell`).
- Sintaxe conferida (`bash -n`); `.claude/settings.json` conferido
  (`jq empty`). Lógica não testada com uma chamada de ferramenta real
  dentro desta sessão -- mesma limitação já registrada nas ADRs
  anteriores desta rodada (configuração de gancho não recarrega na
  sessão que a edita). Confirmação ao vivo pendente pra uma sessão
  nova -- ver [tasks.md](<../docs/tasks.md>).
