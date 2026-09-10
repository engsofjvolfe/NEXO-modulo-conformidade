# Contribuindo com este repositório

<!-- doc-type: readme -->

Regras de como uma mudança entra neste repositório -- este projeto usa,
nele mesmo, os vigias que ele fornece: as regras abaixo são checadas
mecanicamente por `pre_git_rules.sh` e `pre_commit_hygiene.sh`
(`.claude/hooks/`), não é só um combinado escrito sem garantia.

## Branch e mesclagem

- Nunca commitar direto em `main` -- toda mudança nasce numa branch de
  tarefa (`git checkout -b nome-da-tarefa main`), commitada lá, depois
  trazida de volta com `git merge --no-ff nome-da-tarefa`. Bloqueado
  mecanicamente, sem exceção possível (nem com `AUTORIZO-TRAVA`).
- Mensagem do commit de mesclagem: só `Mescla nome-da-branch`, nada
  além disso -- o detalhe completo já mora no(s) commit(s) de trabalho
  que a mesclagem traz junto, visíveis logo abaixo dela em `git log`.

## Mensagem de commit (de trabalho, não de mesclagem)

- Sempre em português.
- Título curto na primeira linha, no imperativo (ex.: "Corrige X",
  "Cria Y"), sem prefixo tipo `docs:`/`fix:`.
- Corpo, quando precisar de detalhe, como lista de itens objetivos
  (`- ...`) -- nunca narrativa em prosa corrida.
- Nunca conta a jornada de investigação ("descobrimos que...", "depois
  de tentar X, percebemos que...", "a causa acabou sendo...") --
  descreve o fato final. Bloqueado mecanicamente
  (`pre_commit_hygiene.sh`, item 12).
- **Nunca** leva a linha `Co-Authored-By: Claude ...` (ou similar) --
  omitida por completo, sempre. Bloqueado mecanicamente
  (`pre_commit_hygiene.sh`, item 1), sem exceção possível.
- Nunca emoji, nem na mensagem nem em nenhum arquivo do commit.
  Bloqueado mecanicamente (itens 2, 2b).

## Licença

Ver [README.md, Licença](README.md#licença).
