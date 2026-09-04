# 0009 — Revisor de commit confere se o conteúdo foi pro documento certo

`modulos/README.md`, seção "Como escrever", define onde cada tipo de
conteúdo mora (narrativa de investigação só em `analysis.md`,
confirmação de teste só em `findings.md`, `handoff.md` só aponta, entre
outras regras) — mas nenhum gancho conferia isso. Esta decisão
acrescenta a checagem no revisor de commit, junto das demais checagens
de julgamento que ele já faz.

## Status

Aceito.

## Contexto

Confirmado ao vivo, na mesma sessão que motivou esta ADR: dois
documentos tocados (`findings.md` e `MANUAL.md`, ambos do módulo
`conformidade`) chegaram a ter a mesma explicação escrita duas vezes,
com palavras diferentes — sem nenhum gancho, velho ou já corrigido
nesta rodada, sinalizando isso. A correção só aconteceu porque foi
apontada diretamente. `modulos/README.md`, seção "Como escrever", já
define isso por escrito (esse arquivo entra no `CLAUDE.md` via
`@caminho`, carrega automaticamente em toda sessão): tom impessoal só
com exceção em `analysis.md`, `handoff.md` só aponta, ADR nunca
reescrita, entre outras regras que, na prática, significam "cada
conteúdo tem um dono, os outros documentos só apontam pra ele". Regra
já escrita, sem mecanismo que a aplicasse.

Alternativas reais consideradas:
- Deixar como estava (checagem só manual, quando alguém perceber) —
  descartada: é o próprio comportamento que motivou a correção.
- Checagem mecânica (script, sem IA), comparando trecho de texto entre
  documentos tocados — descartada: comparar se duas explicações "dizem
  a mesma coisa com palavras diferentes" exige entender o conteúdo, não
  só comparar caracteres; é julgamento, não fato mecânico (mesma
  categoria já usada pra tom impessoal, que também é checagem
  semântica do revisor de commit, nunca de um script).
- Acrescentar a checagem ao revisor de commit já existente (`type:
  agent`, evento `PreToolUse`, `if: Bash(git commit *)`), no mesmo
  lugar onde tom impessoal e esquema puro já são conferidos — escolhida.

## Decisão

O prompt do revisor de commit (`.claude/settings.json`) passa a
conferir, como fato, se todo conteúdo escrito foi pro documento que
`modulos/README.md` (seção "Como escrever") e o cabeçalho de cada
arquivo já definem como dono daquele tipo de conteúdo — nomeando os
casos mais concretos (narrativa de investigação, alternativas
descartadas, confirmação de teste, achado de bug de ferramenta,
`handoff.md`) e o sinal de alerta prático: a mesma explicação
aparecendo, reescrita, em mais de um documento tocado no mesmo commit.

## Consequências

- Fecha uma lacuna real, encontrada ao vivo durante a própria correção
  desta rodada -- confirma que o sistema de conformidade, mesmo depois
  de corrigido pra bloquear de verdade, ainda cobria só as regras que
  alguém já tinha lembrado de mecanizar, não o `CLAUDE.md` inteiro.
- Sintaxe do `settings.json` conferida (`jq empty`) depois da correção.
  Como é uma checagem de julgamento, dentro de um gancho `agent`, a
  mesma incerteza de bloqueio real do resto do revisor de commit se
  aplica aqui -- mas essa incerteza é sobre `Stop`
  ([decisions/0008](<0008-formato-de-bloqueio-nos-ganchos-de-julgamento-do-stop.md>)),
  não sobre `PreToolUse`: o formato usado
  (`hookSpecificOutput.permissionDecision`) já está confirmado, com
  certeza, como reconhecido pelo Claude Code.

**Nota de acompanhamento (28-08-2026):** a mesma checagem (conteúdo
duplicado entre documentos, quando deveria ser só ponteiro) só existia
no revisor de commit -- tarde demais, mesmo padrão de todas as outras
checagens de fluxo já movidas pro momento da edição nesta sessão. Um
terceiro julgamento (C) foi acrescentado ao gancho `agent` de
`PreToolUse` (matcher `Write|Edit`, o mesmo que já confere ADR-worthiness
e tom impessoal), pedindo que o revisor confira os outros arquivos do
mesmo módulo (`docs/`, `decisions/`) atrás do mesmo trecho ou ideia
central antes de decidir -- não é mecânico, continua exigindo o mesmo
julgamento semântico já registrado acima como razão de morar num
gancho `agent`, só que agora roda antes da escrita acontecer, não só
no commit. O revisor de commit continua com a checagem original, como
segunda conferência independente.
