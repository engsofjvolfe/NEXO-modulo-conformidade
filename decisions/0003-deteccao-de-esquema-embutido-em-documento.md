# 0003 — Detecção de esquema embutido em documento

A checagem de "esquema de dado carrega só dado puro, sem `description`
nem `example`" só olhava arquivos dentro de `schemas/*.json`. O
`CLAUDE.md`, Regras gerais, generaliza essa regra pra qualquer esquema
"em qualquer lugar do projeto -- dentro de `schemas/`... ou embutido
num documento" -- um bloco de esquema dentro de um `.md` (o YAML do
`concept.md` do motor, por exemplo) nunca era checado.

## Status

Aceito.

## Contexto

Nenhum esquema embutido hoje viola a regra (conferido por leitura
direta do YAML de `modulos/motor/docs/concept.md`) -- a lacuna é na
cobertura da checagem, não um problema já existente. Ainda assim, uma
mudança futura naquele bloco (ou um novo documento com esquema
embutido) passaria sem checagem nenhuma.

Alternativas reais consideradas:
- Checar qualquer bloco cercado por ` ```yaml `/` ```json ` dentro de
  qualquer `.md`, sem distinção -- descartada: um documento pode ter
  blocos de exemplo genéricos, sem relação com contrato de dado (um
  trecho de configuração, um recorte de log) -- tratar todo bloco como
  esquema geraria bloqueio sem sentido.
- Exigir marcação explícita (um comentário HTML tipo
  `<!-- schema -->` antes do bloco) -- descartada: exigiria mudar todo
  esquema embutido já existente só pra ganhar a checagem, e nenhuma
  convenção desse tipo existe hoje no projeto.
- Heurística: dentro de um bloco cercado por ` ```yaml `/` ```json `,
  só conta como esquema quando o bloco também contém `required` ou
  `properties`, junto com `type` -- a forma que todo bloco de contrato
  de dado deste projeto já usa (confirmado comparando contra o YAML de
  `modulos/motor/docs/concept.md` e o JSON Schema de
  `docs/docs-VMODEL-visao-geral/5 - projeto-detalhado.md`) --
  escolhida.

## Decisão

`pre_commit_hygiene.sh` ganha um item novo (3b): pra cada `.md`
alterado no commit, extrai cada bloco cercado por ` ```yaml `/
` ```json ` e aplica a heurística acima; encontrando `description` ou
`example` dentro de um bloco que já bateu a heurística de esquema,
bloqueia o commit -- mesma mensagem de erro do item 3 (esquema em
`schemas/*.json`), sem exceção autorizável (mesma categoria: fato de
texto).

## Consequências

- Verificado por teste isolado (ver
  [`findings.md`](<../docs/findings.md>)): dois casos cobertos -- bloco
  com `description` dentro de um esquema válido (detectado) e o mesmo
  bloco sem `description` (não detectado, sem falso positivo).
- Heurística nunca testada contra um bloco de esquema real de verdade
  passando pelo fluxo completo de commit (só a lógica isolada, fora de
  um repositório git) -- primeira vez que um commit tocar um `.md` com
  bloco de esquema, dentro ou fora deste módulo, serve de confirmação
  de ponta a ponta.
- Convenção "bloco com `required`/`properties` + `type` conta como
  esquema" não está escrita em nenhum documento além desta ADR e do
  comentário no próprio script -- se este projeto criar, no futuro, um
  tipo de bloco cercado que use esses termos sem ser esquema de dado
  de verdade, a heurística geraria falso positivo; nenhum caso desse
  tipo existe hoje.
