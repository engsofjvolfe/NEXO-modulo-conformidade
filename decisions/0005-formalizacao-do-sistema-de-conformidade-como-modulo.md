# 0005 — Formalização do sistema de conformidade como módulo

O sistema de hooks que trava as regras do `CLAUDE.md` sempre viveu
como um documento único (`MANUAL.md`, na raiz), sem `decisions/`,
`tasks.md` ou `findings.md` próprios — diferente de todo o resto do
projeto, que segue o molde de módulo em `modulos/`. Esta decisão
formaliza esse sistema como módulo (`modulos/conformidade/`),
mantendo `MANUAL.md` como fonte normativa.

## Status

Aceito.

## Contexto

Achado direto, no meio do trabalho de fechar quatro lacunas reais
deste sistema (ver ADRs 0001 a 0004): nenhuma delas tinha lugar formal
onde registrar pendência ou decisão — não existia `tasks.md` nem
`decisions/` pra esse sistema, só `MANUAL.md` sozinho. Confirmado
também por um gancho já existente deste próprio sistema
(`pre_edit_safety.sh`, checagem de leitura obrigatória) recusando
editar código novo em `.claude/hooks/` sem `concept.md`/`architecture.md`
correspondentes -- o próprio mecanismo já cobrava essa estrutura, sem
ela existir ainda.

Alternativas reais consideradas:
- Manter como estava: `MANUAL.md` sozinho, fora da tabela de módulos
  (mesmo tratamento que `preview/` já recebe -- infraestrutura do
  projeto, não módulo de produto), acrescentando só uma seção
  "Pendências" e uma "Decisões" dentro dele mesmo, sem pasta
  `decisions/` separada -- descartada: quebra o padrão que todo o
  resto do projeto segue, e a divisão entre "escolha real entre
  alternativas" (ADR) e "narrativa datada" (achado) fica mais fraca
  dentro de um documento só.
- Virar módulo de verdade, com `MANUAL.md` migrando pro molde de
  `concept.md`/`architecture.md` inteiro, deixando de existir como
  documento único -- descartada: reescreveria um documento já extenso
  e já funcionando, só pra bater com uma forma -- risco de introduzir
  divergência sem necessidade real.
- Meio-termo: virar módulo, com `concept.md`/`architecture.md` curtos
  apontando pra `MANUAL.md` como fonte normativa (mesmo papel que a
  cascata VMODEL cumpre pro módulo `motor`, já um precedente direto
  neste projeto), e pasta `decisions/`/`tasks.md`/`findings.md`/
  `pitfalls.md`/`analysis.md` própria, cobrindo exatamente o que
  faltava -- escolhida.

## Decisão

`modulos/conformidade/` criado, copiando a estrutura do
`modulos/_template/`: `docs/concept.md` e `docs/architecture.md`
curtos, cada um apontando pra `MANUAL.md` como fonte normativa, sem
repetir o conteúdo dele; `decisions/` com as ADRs 0001 a 0004 (as
quatro escolhas técnicas da mesma sessão) mais esta; `docs/findings.md`,
`docs/pitfalls.md` e `docs/analysis.md` com o que essa mesma sessão já
tinha pra registrar; `docs/tasks.md` com as pendências que sobraram.
`MANUAL.md` continua exatamente onde estava, sem migrar conteúdo —
`modulos/README.md` ganha a linha do módulo novo na tabela.

## Consequências

- Decisões estruturais mais antigas deste sistema (por que os hooks
  nativos do git moram em `scripts-hooks/`, o desenho de
  `pre_bash_search_guard.sh`, a divisão de custo do evento `Stop`,
  entre outras já narradas em `MANUAL.md`, seção 9) continuam sem ADR
  própria — só as quatro decisões desta sessão (0001 a 0004) e esta
  (0005) entraram como ADR até agora. Formalizar as mais antigas fica
  como pendência própria, ver
  [tasks.md](<../docs/tasks.md#em-aberto>).
- `MANUAL.md` passa a ser citado, dentro de `modulos/`, do mesmo jeito
  que a cascata VMODEL já é citada por `modulos/motor/docs/concept.md`
  -- consistência confirmada por comparação direta entre os dois
  casos antes de escrever esta ADR.
