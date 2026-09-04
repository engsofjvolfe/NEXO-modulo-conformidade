# Scripts — NEXO (raiz)

<!-- doc-type: readme -->

Ferramentas de apoio ao repositório, fora do código de qualquer módulo.

## Verificação de versão

`hooks/pre-commit` avisa, antes de um commit acontecer, quando um
documento com campo de versão reconhecido (a tabela "Versão" no
cabeçalho de todo arquivo de [`modulos/_template/`](../modulos/_template/)
e dos cinco documentos de
[`docs/docs-VMODEL-visao-geral/`](../docs/docs-VMODEL-visao-geral/), ou
`schema_version` num arquivo `*.schema.json`) mudou de conteúdo sem a
própria versão subir junto. Não decide qual versão nova usar — quem
decide é sempre quem está commitando, seguindo SemVer; o hook só avisa
que a decisão está pendente, e bloqueia o commit até ela ser tomada (ou
até o commit ser refeito com `git commit --no-verify`, pra mudança
puramente cosmética, sem troca de sentido).

ADR individual (`decisions/000N-titulo.md`) fica de fora de propósito
— não leva versão própria, o histórico dela é o campo Status
(substituído pelo ADR-NNNN).

### Instalação

Rodar uma vez, em qualquer worktree (a configuração vale pro
repositório inteiro, todas as worktrees compartilham):

```
scripts/instalar-hooks.sh
```

## Licença

Todos os direitos reservados — ver [LICENSE](../LICENSE).
