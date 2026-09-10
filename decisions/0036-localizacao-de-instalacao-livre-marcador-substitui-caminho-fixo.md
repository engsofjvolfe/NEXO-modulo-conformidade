# ADR 0036 — Localização de instalação livre, marcador substitui caminho fixo

*Em resumo:* a pasta deste projeto pode ser copiada pra qualquer
caminho, com qualquer nome, dentro de um projeto hospedeiro -- nenhum
caminho fixo exigido. `scripts/instalar.sh`, rodado uma vez da raiz do
projeto hospedeiro, descobre onde a pasta foi colocada e grava isso
num arquivo pequeno (`.claude/conformidade-caminho`); todo mecanismo
que precisava saber "onde isso está" (a sincronização automática de
`session_start_sync_modulo.sh`) passa a ler esse arquivo, em vez de
presumir um caminho.

## Status

Aceito.

## Contexto

Ao desenhar a instalação de comando único (decisions/0034), o caminho
`modulos/conformidade/` foi fixado como exigência -- decisão
questionada: um projeto hospedeiro pode já ter uma pasta `modulos/`
com convenção própria (colidindo ou confundindo), ou pode nem usar o
conceito de "módulo" internamente. Exigir um caminho fixo específico
contraria o objetivo de instalação simples, livre de amarração --
quem instala não deveria precisar adaptar a estrutura do próprio
projeto pra caber na convenção desta ferramenta.

Alternativas reais consideradas:

- **Manter caminho fixo (`modulos/conformidade/`)** -- descartada:
  colide com a liberdade que a instalação deveria dar; projeto sem
  pasta `modulos/` seria forçado a criar uma só pra isso.
- **Descobrir a raiz do projeto hospedeiro via `git rev-parse
  --show-toplevel`, a partir de onde a pasta foi copiada** --
  descartada: esta ferramenta tem repositório git próprio, separado do
  hospedeiro -- rodar esse comando de dentro dela sempre acha a raiz
  DELA mesma, nunca a do projeto hospedeiro por fora. Testado ao vivo,
  confirmado o problema antes de publicar.
- **Instalador rodado a partir da raiz do projeto hospedeiro,
  apontando pro script já copiado em qualquer lugar** -- escolhida:
  `$(pwd)` no momento da execução já é a raiz certa (responsabilidade
  de quem instala, mesmo padrão de instaladores comuns), e
  `$(dirname "$0")` já revela onde o script está, então o caminho
  relativo entre os dois é calculável sem adivinhar nada.
- **Gravar o caminho descoberto num arquivo marcador, lido por todo
  mecanismo que precisar dele depois** -- escolhida, complementar à
  anterior: sem isso, `session_start_sync_modulo.sh` (que roda a partir
  de `.claude/hooks/`, alcançado por atalho de pasta -- não pela
  pasta real desta ferramenta) não teria como recalcular o caminho
  sozinho a cada sessão.

## Decisão

`scripts/instalar.sh`: `RAIZ_DIR="$(pwd)"` (exige rodar da raiz do
projeto hospedeiro -- erro explícito se o script parecer estar sendo
rodado de dentro da própria pasta copiada); caminho relativo calculado
e gravado em `.claude/conformidade-caminho`.

`session_start_sync_modulo.sh`: lê esse arquivo pra saber onde a pasta
está, em vez do caminho fixo anterior; sai sem fazer nada se o
marcador não existir (instalação não fez esse passo ainda).

`.gitignore` (raiz do projeto hospedeiro): novo caminho no bloco de
ferramentas internas, `.claude/conformidade-caminho`.

## Consequências

- `bash -n` sem erro nos dois scripts.
- Instalação manual desta mesma sessão (`NEXO-EMBRIOLOGIA`) migrada
  pro novo mecanismo: marcador criado apontando pra
  `modulos/conformidade` (caminho onde já estava, mantido de
  propósito, sem mover nada).
- Teste ao vivo do fluxo completo (copiar em caminho livre, rodar o
  instalador, confirmar que a sincronização automática encontra o
  marcador numa sessão nova), num projeto de teste separado, ainda
  pendente -- ver `tasks.md`.
- Risco aceito: mover a pasta de lugar depois de instalada não
  atualiza os atalhos de pasta já criados sozinho -- precisa remover
  `.claude/hooks`/`.claude/agents` à mão antes de rodar o instalador de
  novo nesse caso. Não resolvido nesta decisão.
