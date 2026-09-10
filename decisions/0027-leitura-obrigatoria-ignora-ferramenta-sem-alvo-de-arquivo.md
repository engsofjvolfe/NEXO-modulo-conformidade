# ADR 0027 — Leitura obrigatória ignora ferramenta sem alvo de arquivo

*Em resumo:* a checagem de leitura obrigatória barrava até ferramenta
que não toca em nenhum arquivo do projeto (uma que só organiza a
própria lista de tarefas da sessão, por exemplo) -- um efeito colateral
da rodada anterior, achado ao vivo. Corrigido pela mesma forma já
usada nesse gancho pra decidir o resto: olhar a forma da chamada
(tem ou não tem caminho de arquivo), nunca o nome da ferramenta.

## Status

Aceito.

## Contexto

Na mesma sessão em que `decisions/0023` unificou o frescor de leitura,
uma chamada de ferramenta sem nenhum campo de caminho de arquivo
(`file_path`, `command`, `path`, `pattern` todos vazios) foi barrada
pela leitura obrigatória do projeto hospedeiro -- mesmo sem ter como
tocar em nenhum documento. O gancho já tratava esse mesmo caso, antes,
só pra uma ferramenta específica (uma linha isolada checando o nome
dela), deixando qualquer outra do mesmo formato sem cobertura.

Alternativas reais consideradas:

- **Acrescentar a ferramenta nova à mesma linha isolada, por nome** —
  descartada: mesmo problema de antes (`decisions/0024`), só descoberto
  de novo -- qualquer ferramenta futura do mesmo formato ficaria de
  fora até alguém notar e adicionar à mão.
- **Decidir pela forma da chamada (tem campo de caminho de arquivo,
  ou não tem nenhum)** — escolhida: mesmo critério que já decide
  `IS_INTERNAL_TOOLING` duas linhas abaixo, sem lista própria.

## Decisão

`pre_mandatory_reading_guard.sh` sai cedo (`exit 0`) quando
`ALVO_FERRAMENTA` -- a mesma variável já calculada pra decidir
`IS_INTERNAL_TOOLING`, concatenação de `file_path`/`command`/`path`/
`pattern` -- vem vazia. A linha isolada anterior, específica de uma
ferramenta por nome, é removida (fica coberta pela regra geral).

## Consequências

- `bash -n` sem erro depois da mudança.
- Teste ao vivo (achado durante o próprio trabalho desta sessão,
  confirmando o bloqueio antes da correção) segue sem confirmação
  separada depois da correção -- mesma limitação já registrada em
  `tasks.md` pra qualquer mudança de gancho desta rodada.
