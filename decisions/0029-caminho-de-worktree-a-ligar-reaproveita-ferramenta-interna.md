# ADR 0029 — Caminho de worktree a ligar reaproveita a lista de ferramenta interna

*Em resumo:* a lista de pastas que uma worktree nova precisa enxergar
por atalho (`ensure_worktree_links`) tinha um caminho escrito à mão
(`"modulos/conformidade"`) -- supunha que todo projeto hospedeiro
guarda o clone deste módulo exatamente nesse lugar. Corrigido pra
reaproveitar a mesma lista já lida do `.gitignore` do projeto
hospedeiro (`internal_tooling_paths`), sem lista própria nova.

## Status

Aceito.

## Contexto

`WORKTREE_LINK_PATHS` continha três entradas fixas: `.claude/agents`,
`.claude/hooks` (convenção do próprio Claude Code, não específica de
projeto) e `modulos/conformidade` (onde o projeto onde este módulo
nasceu decidiu guardar o clone dele -- escolha só desse projeto).

Esse terceiro item quebra o agnosticismo deste módulo -- outro projeto
que guardasse o clone em outro caminho (ou nem usasse pasta
`modulos/`) nunca teria essa pasta ligada numa worktree nova.

Alternativas reais consideradas:

- **Manter o caminho fixo, um item por projeto que vier a usar este
  módulo** -- descartada: mesmo problema já corrigido em
  decisions/0028, obrigaria editar o módulo pra cada projeto novo.
- **Nova variável de configuração, própria pra esse caminho** --
  descartada: já existe `internal_tooling_paths` (lib/common.sh), lida
  do mesmo bloco do `.gitignore` que já serve pra isenção de leitura
  obrigatória -- criar uma segunda fonte pro mesmo tipo de dado
  duplicaria configuração sem necessidade.
- **Reaproveitar `internal_tooling_paths`, filtrando só entradas que
  são pasta de verdade** -- escolhida: uma fonte só, sem lista fixa
  nova; o filtro por pasta é necessário porque atalho de pasta do
  Windows (junction) não serve pra um arquivo único (ex.:
  `.claude/settings.json`, também citado nesse bloco do `.gitignore`).

## Decisão

`WORKTREE_LINK_PATHS` removida. `ensure_worktree_links` passa a montar
a lista de caminhos a ligar chamando `internal_tooling_paths`, e
ligando só as entradas que já existem como pasta de verdade em disco
(`[[ -d ... ]]`).

## Consequências

- `bash -n lib/common.sh` sem erro depois da mudança.
- Projeto hospedeiro sem o bloco "Ferramentas internas de trabalho
  desta sessao" no `.gitignore`: nenhuma pasta é ligada -- mesmo
  comportamento de antes pra quem não usa esse recurso.
- Teste ao vivo, numa sessão nova (worktree criada de verdade), ainda
  pendente -- ver `tasks.md`.
