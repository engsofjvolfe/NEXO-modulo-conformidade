# ADR 0030 — Ganchos de IA usam Read em vez de `cat` pra checar autorização

*Em resumo:* os três pontos deste módulo que usam uma segunda
inteligência artificial pra julgar (revisão de edição, e os dois do
fim da resposta) tinham, na própria instrução, a ordem "rode `cat
.claude/hooks/state/current-authorization` pra checar se está
autorizado". A negação de `cat` (decisions/0024, na mesma sessão)
quebrou esse mecanismo por completo -- os três nunca mais conseguiam
checar autorização nenhuma, mesmo com `AUTORIZO-TRAVA` digitado de
verdade. Corrigido: os três passam a usar a ferramenta Read pra ler
esse arquivo, nunca `cat`.

## Status

Aceito.

## Contexto

Achado ao vivo: mesmo depois de `AUTORIZO-TRAVA` digitado, um dos três
pontos (revisão de edição, julgamento C -- conteúdo duplicado entre
documentos) continuou bloqueando edição de documento repetidas vezes.
Lendo o texto da instrução desse ponto, a causa apareceu: a primeira
ordem era rodar `cat` sobre o arquivo de autorização -- comando negado
pela permissão do Claude Code desde decisions/0024, decidida mais cedo
nesta mesma sessão. Sem conseguir rodar esse comando, o ponto nunca
sabe se existe autorização, e segue pro resto do julgamento como se
nunca houvesse uma.

Os outros dois pontos do mesmo tipo (as duas checagens do fim da
resposta) tinham a mesma instrução, mesma causa.

Alternativas reais consideradas:

- **Reabrir `cat` na permissão, só pra esses três pontos** -- descartada:
  não tem como restringir uma negação de permissão por quem está
  chamando o comando, só pelo comando em si -- reabrir `cat` de volta
  anularia o propósito inteiro de decisions/0024.
- **Trocar `cat` por Read (a ferramenta rastreada, não um comando de
  Bash)** -- escolhida: já é a ferramenta que este módulo espera que
  qualquer leitura de arquivo use, em qualquer contexto -- consistente
  com o resto do sistema, e não depende de nenhuma permissão negada.

## Decisão

Os três pontos (`.claude/settings.json`, evento `PreToolUse` matcher
`Write|Edit`, e os dois blocos do evento `Stop`, tipo `agent`) trocam
"Primeiro rode: cat .claude/hooks/state/current-authorization" por
"Primeiro, use a ferramenta Read... pra ler
.claude/hooks/state/current-authorization", com nota explícita "nunca
Bash/cat -- esse comando está negado na permissão deste projeto".

## Consequências

- `jq empty .claude/settings.json` sem erro depois da mudança.
- Teste ao vivo, numa sessão nova, ainda pendente -- ver `tasks.md`.
- Acha-se possível que esse mesmo defeito tenha causado boa parte dos
  bloqueios de julgamento (C) vistos ao longo desta sessão desde a
  negação de `cat` -- sem confirmação retroativa possível (a sessão
  não guarda registro de qual ponto exato bloqueou cada vez).
