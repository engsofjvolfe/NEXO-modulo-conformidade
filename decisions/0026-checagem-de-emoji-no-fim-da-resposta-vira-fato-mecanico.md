# ADR 0026 — Checagem de emoji no fim da resposta vira fato mecânico

*Em resumo:* a checagem de "nenhum emoji na resposta final" e a
checagem de "todo termo técnico está explicado" moravam juntas dentro
de um único gancho do tipo "prompt" (uma segunda inteligência
artificial menor, chamada a cada resposta). A primeira é fato puro --
mesma função (`has_emoji`) já usada em outro ponto do sistema --, sem
precisar de nenhuma IA; a segunda exige entendimento de verdade.
Separadas: emoji vira um script comum, sem IA; termo técnico continua
com a segunda IA, mas sozinho, com instrução mais curta e mais
tolerante a explicação já existente, mesmo que resumida.

## Status

Aceito.

## Contexto

Ao longo desta sessão, esse gancho bloqueou repetidas vezes por
"termo técnico não explicado" mesmo quando a resposta já trazia
alguma explicação ao lado do termo -- a própria instrução do gancho
mandava tratar qualquer dúvida como violação ("se estiver em dúvida
... trate como violação"), o que empurrava a segunda IA a marcar
como falha explicações já razoáveis, gerando ciclos de correção sem
ganho real. Pendência já registrada em `tasks.md` sobre esse mesmo
comportamento.

Questionado se fazia sentido usar uma segunda IA pra confirmar algo
que já podia ser conferido como fato puro -- resposta: pra emoji,
sim, já existe função pronta (`has_emoji`, `lib/common.sh`) que faz
exatamente essa checagem em texto, usada hoje em `pre_edit_safety.sh`
pra arquivo editado. A mensagem final da resposta é só texto; a mesma
função serve sem adaptação.

Alternativas reais consideradas:

- **Manter os dois junto, mesmo gancho** (status quo) — descartada:
  emoji não precisa de IA, e a instrução de "dúvida vira violação"
  prejudicava as duas checagens juntas.
- **Separar, mas manter os dois com IA** — descartada: emoji é fato
  puro, gastar uma chamada de modelo (custo, latência, risco de
  formato errado) pra confirmar um fato que um script confirma sozinho
  contradiz o princípio já registrado neste módulo (fato mecânico vira
  script, sem perguntar nada).
- **Separar: emoji vira script comum; termo técnico continua com IA,
  sozinho, instrução mais tolerante** — escolhida.

## Decisão

`stop_emoji_check.sh` criado -- gancho comum (`type: command`),
sem IA, roda `has_emoji` sobre `last_assistant_message` (mesmo campo
que `stop_fact_check.sh` já usa), bloqueia com `block()` se achar
emoji. Adicionado a `.claude/settings.json`, evento `Stop`, como
bloco próprio, antes do gancho de termo técnico.

Gancho `prompt` restante reescrito: só a pergunta sobre termo técnico
sem explicação nenhuma. Regra de "dúvida vira violação" removida --
substituída por "se já existe alguma explicação, mesmo curta ou
imperfeita, não conta como violação; só ausência total conta".

## Consequências

- `.claude/settings.json` conferido com `jq empty`; `stop_emoji_check.sh`
  conferido com `bash -n` -- os dois sem erro, clone e raiz idênticos
  (acessível pela raiz através do atalho de pasta, sem cópia manual).
- Pendência de `tasks.md` sobre formato de resposta em JSON resolvida
  -- ver `Resolvidas`.
- Teste ao vivo (resposta com emoji de propósito, confirmando bloqueio
  mecânico; resposta com termo já explicado de forma resumida,
  confirmando que não bloqueia mais por falso positivo) ainda pendente.
