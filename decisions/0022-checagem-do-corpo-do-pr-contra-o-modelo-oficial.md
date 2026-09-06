# 0022 — Checagem automática do corpo do PR contra o modelo oficial

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Decisions — 0022 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

*Em resumo:* uma trava nova confere, antes de abrir um PR, se o texto
da descrição tem as quatro partes que o modelo do projeto já pede
(o que muda, por quê, como testar, lista de conferência). Ela olha só
se o título de cada parte existe no texto, nunca se o conteúdo de
dentro de cada parte está bom.

## Status

Aceito.

## Contexto

Um PR foi aberto com uma descrição fora do modelo já definido em
`.github/pull_request_template.md` — faltava a seção "Por quê" e a
lista de conferência do fluxo de documentação, e um dos títulos usados
("Como foi testado") não batia com o título oficial ("Como testar").
Nenhuma trava automática existia pra pegar isso antes da abertura —
só checagem manual, sujeita a passar despercebida.

## Decisão

- Trava nova (`pre_pr_description_check.sh`), no mesmo evento das
  demais checagens de `gh pr create` (`PreToolUse`, filtro
  `Bash(gh pr create *)`): confere se o texto do comando contém, na
  ordem certa, as quatro linhas de título exigidas pelo modelo — "##
  O que muda", "## Por quê", "## Como testar", "## Checklist do fluxo
  de documentação".
- Mecanismo: procurar o texto literal de cada título dentro do próprio
  comando (`grep -F`), o mesmo texto que `gh pr create --body "..."`
  já carrega — sem abrir nenhum arquivo à parte, e sem interpretar o
  conteúdo de dentro de cada seção (isso continua checagem manual, é
  julgamento, não fato mecânico).
- Alternativa descartada: ler o arquivo de descrição quando o comando
  usa `--body-file` em vez de `--body` direto — mais completo, mas
  exigiria abrir um arquivo cujo caminho pode ser relativo a um
  diretório diferente do que o gancho já resolve sozinho hoje;
  registrado como limite conhecido, não resolvido nesta ADR.
- Alternativa descartada: exigir o modelo inteiro, incluindo os
  comentários guia (`<!-- descreva... -->`) — rejeitada porque o
  próprio modelo espera que esses comentários sejam substituídos pelo
  texto real, then a ausência deles não é problema, é o esperado.

## Consequências

- Checagem só de fato mecânico (título de seção existe, sim ou não) —
  não decide se o conteúdo de cada seção está completo ou correto,
  isso continua exigindo julgamento humano.
- Limite conhecido: comando `gh pr create --body-file <caminho>` não é
  conferido por esta trava — só `--body` com o texto direto no próprio
  comando.
