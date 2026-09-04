# 0007 — Bloqueio real dos fatos mecânicos do evento `Stop`

`stop_fact_check.sh` já encontrava fatos mecânicos reais (worktree
mesclada e esquecida, `git status` sujo quando a resposta diz
"pronto", PR com base em `main`), mas só anexava um texto de contexto
— nunca travava a resposta de terminar. Esta decisão troca isso por um
bloqueio de verdade, com `AUTORIZO-TRAVA` como válvula de escape.

## Status

Aceito.

## Contexto

Pesquisa direta na documentação oficial do Claude Code confirmou:
`additionalContext` (usado antes neste script) não tem nenhum efeito
de bloqueio — é só texto que aparece, seguido ou ignorado por conta
própria. O único mecanismo de bloqueio confirmado, documentado e
citado literalmente pra qualquer evento (incluindo `Stop`), pra
qualquer tipo de gancho, é `exit 2` (a mensagem de bloqueio vem do
`stderr`). Como este script é do tipo `command` (um script comum, sem
IA envolvida) e os três fatos que ele confere são objetivos — não
julgamento —, usar `exit 2` aqui não tem a incerteza que cerca o
mesmo tipo de bloqueio em gancho `agent`/`prompt` (ver
[decisions/0008](<0008-formato-de-bloqueio-nos-ganchos-de-julgamento-do-stop.md>)).

Alternativas reais consideradas:
- Manter só `additionalContext` — descartada: é o comportamento que
  gerou a queixa que motivou toda esta rodada de correção (o sistema
  "avisa" mas nunca trava, cabe a quem está trabalhando decidir se
  corrige).
- `exit 2` sem nenhuma válvula de escape — descartada: um fato como
  "worktree já mesclada e não removida" pode ter uma exceção real (a
  worktree continua em uso de propósito por outra tarefa) — travar sem
  nenhuma saída trocaria "aviso ignorável" por "trava sem saída", os
  dois ruins, só em direções opostas.
- `exit 2` com checagem de `AUTORIZO-TRAVA` (mesmo mecanismo já usado
  em todo o resto do sistema de conformidade) — escolhida.

## Decisão

`stop_fact_check.sh` passa a chamar `is_authorized`/`log_override` no
início (mesmo padrão de todo outro gancho autorizável deste projeto —
essa checagem não existia nele antes). Encontrado qualquer um dos três
fatos, o script chama `block()` (função de `lib/common.sh`, que
imprime a mensagem no `stderr` e sai com código 2) em vez de imprimir
`additionalContext`. Sem autorização e sem fato encontrado, a resposta
termina normalmente.

## Consequências

- Os três fatos mecânicos do evento `Stop` (worktree esquecida, `git
  status` sujo com resposta de entrega, PR com base em `main`) passam
  a ser, de fato, impossíveis de ignorar em silêncio — response só
  termina depois de corrigidos ou de `AUTORIZO-TRAVA` explícito.
- Sintaxe conferida (`bash -n`); bloqueio de verdade, com uma chamada
  de ferramenta real dentro do fluxo do Claude Code, não confirmado
  nesta sessão (mesma limitação de
  [decisions/0001](<0001-cobertura-do-gancho-de-leitura-obrigatoria.md>)
  — configuração de gancho não recarrega na sessão que a edita). Ver
  pendência em [tasks.md](<../docs/tasks.md>).
- Risco reconhecido, não uma falha: um fato que se repete sessão após
  sessão (por exemplo, uma worktree deixada de propósito por mais
  tempo) passa a exigir `AUTORIZO-TRAVA` toda vez que aparecer — atrito
  aceito em troca de o sistema não poder mais ser ignorado em silêncio,
  que é o problema real que motivou esta correção.
