# ADR 0019 — Detecção de versão subida em documento só com changelog

*Em resumo:* o gancho nativo `scripts/hooks/pre-commit` nunca
reconhecia uma subida de versão de verdade em documento sem tabela de
cabeçalho "Campo | Valor" (caso de `MANUAL.md`) -- só olhava pra linha
`| Versão |`, que nesse tipo de documento é só o título fixo da
tabela "Controle de versão", nunca tocado por uma subida de versão
real. Passa a aceitar também uma linha nova, acrescentada, que comece
com um número de versão (`| X.Y.Z |`).

## Status

Aceito.

## Contexto

Achado e teste completos em
[findings.md](<../docs/findings.md#2026-08-29-pre-commit-nunca-detectava-versao-subida-em-documento-so-com-changelog>).
Reproduzido tentando commitar `MANUAL.md` (documento sem tabela de
cabeçalho, só a tabela "Controle de versão") depois de subir a versão
dele de verdade -- o gancho continuava acusando "mudou de conteúdo mas
o campo de versão não acompanhou".

Alternativas reais consideradas:

- **Exigir que todo documento do projeto tenha tabela de cabeçalho com
  campo "Versão"** -- descartada: mudaria a estrutura de documentos já
  existentes (`MANUAL.md`) só pra satisfazer o gancho, quando o
  documento em si está correto -- o gancho que precisa reconhecer os
  dois formatos já usados no projeto, não o contrário.
- **Trocar a checagem inteira por "alguma linha de tabela contendo um
  número de versão mudou"**, sem distinguir os dois formatos --
  descartada: mais frouxa, arriscando não pegar caso real de
  esquecimento (qualquer linha com um número parecido com versão, em
  qualquer tabela do documento, passaria a contar).
- **Acrescentar uma segunda condição, específica pra linha
  ACRESCENTADA que comece com `| X.Y.Z |` (uma entrada nova de
  changelog)**, mantendo a primeira condição (`| Versão |`) intacta --
  escolhida: cobre o segundo formato sem enfraquecer a checagem do
  primeiro, e usa a mesma tabela "Controle de versão" que já é a
  convenção do projeto pra subir versão.

## Decisão

Em `scripts/hooks/pre-commit`, a checagem de arquivo `tipo=markdown`
passa a aceitar `tocou_versao=1` em dois casos, não mais um só: uma
linha `+`/`-` que bata `^\| Versão \|` (comportamento já existente,
cobre a tabela de cabeçalho de campo único), OU uma linha `+` que bata
`^\| *[0-9]+\.[0-9]+\.[0-9]+ *\|` (linha nova na tabela de changelog,
começando com um número de versão).

## Consequências

- `bash -n scripts/hooks/pre-commit` sem erro.
- Testado isoladamente, em repositório de rascunho separado, quatro
  casos: documento só com changelog, conteúdo mudado sem subir versão
  -- bloqueou; o mesmo, subindo a versão de verdade (linha nova na
  tabela) -- passou; documento com tabela de cabeçalho
  (`| Versão | X.Y.Z |`), conteúdo mudado sem subir versão -- bloqueou
  (regressão, comportamento já existente antes desta correção); o
  mesmo, subindo a versão no campo de cabeçalho -- passou (regressão).
- Pendência levantada durante esta correção: conferir se outros
  documentos do projeto, além de `MANUAL.md`, usam só a tabela
  "Controle de versão" sem tabela de cabeçalho, e portanto dependiam
  do mesmo ponto cego -- ver [tasks.md](<../docs/tasks.md>).
