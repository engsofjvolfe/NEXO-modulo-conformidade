# 0012 — Ficha (síntese) substitui releitura do diário a cada checagem

*Em resumo:* os diários deste módulo (`edit-order.log`, `read-log.txt`)
só crescem, nunca resetam entre sessões, e cada checagem que precisa
saber "isso já aconteceu?" tinha que reler o arquivo inteiro toda vez.
Passa a existir, ao lado de cada diário (que continua existindo,
intacto, como prova bruta), uma ficha compacta -- um resumo do estado
atual, atualizado a cada ação -- que as checagens consultam em vez de
reler o diário. A ficha reinicia a cada sessão nova; o diário da
sessão anterior é arquivado, nunca apagado.

**Status:** aceito.

**Contexto:** o `CLAUDE.md` usa a expressão "nesta sessão" repetidas
vezes (leitura obrigatória, ordem de edição, etc.) -- mas os diários
persistiam entre reinícios de sessão, deixando uma leitura feita numa
sessão antiga contar, por engano, como "confirmada nesta sessão nova".
Fora isso, cada checagem de `pre_edit_safety.sh` que precisava saber
"o quê já foi tocado" (ordem `concept.md`→`architecture.md`→
`schemas/`→código, `handoff.md` por último, módulo novo, `tasks.md`
vazio↔não-vazio, citação de documento recém-lido) fazia `grep` no
diário inteiro a cada chamada -- código correto, mas que cresce em
custo conforme a sessão cresce, e nada além do próprio texto de cada
regra ("já foi lido/editado?") separa um fato permanente de um fato
que só vale enquanto "recente" (like a checagem de citação, que já
usava uma janela fixa das últimas 20 leituras, um caso isolado do
mesmo princípio).

Alternativas reais consideradas:
- Manter como estava (releitura do diário a cada checagem, diário
  nunca resetado) -- descartada: o bug de "nesta sessão" é real, e o
  custo de releitura cresce sem limite dentro de uma sessão longa.
- Resetar o diário a cada sessão, sem ficha nenhuma (só encolhe o
  arquivo que cada checagem relê) -- descartada: resolve o bug de
  sessão, mas não o custo de releitura repetida dentro da mesma
  sessão.
- Diário completo, intacto, para sempre (prova bruta, nunca some) +
  ficha separada, compacta, reiniciada a cada sessão, com cada fato
  carregando "há quantas ações foi confirmado" em vez de um booleano
  permanente -- escolhida, desenhada em conjunto (analogia da linha de
  montagem: o diário é cada peça sendo instalada, a ficha é o carro
  pronto sendo conferido contra a lista final).

**Decisão:** `.claude/hooks/lib/common.sh` ganha um arquivo JSON
próprio (`synthesis.json`, fora do diário) e seis funções
(`synthesis_init`, `synthesis_bump`, `synthesis_set`, `synthesis_age`,
`synthesis_fresh`, `synthesis_reset`). Cada fato guardado carrega o
número da ação (contador interno, não relógio) em que foi confirmado
pela última vez -- não um booleano fixo -- e cada checagem decide, na
hora, se essa distância ainda é aceitável pra aquela regra específica
(sem limite, pra fatos que só precisam "ter acontecido nesta sessão",
como leitura obrigatória e reread-before-edit; com limite, pra fatos
que precisam estar frescos, como a citação de documento -- generaliza
a janela de 20 leituras que já existia só pra esse caso). Produtores:
`post_read_track.sh` e `post_edit_track.sh`, que já gravavam o diário,
passam a também atualizar a ficha a cada ação real. Consumidores: as
sete checagens de `pre_edit_safety.sh` que antes faziam `grep` direto
no diário (reread-before-edit, citação-recência, ordem completa,
`handoff.md` por último, módulo novo, `tasks.md` vazio↔não-vazio) e
`first_unread_mandatory_doc` em `lib/common.sh`, todas convertidas pra
consultar a ficha. `session_start_reset.sh`, novo gancho `SessionStart`
sem matcher, arquiva (nunca apaga) os três diários da sessão anterior
em `.claude/hooks/state/arquivo/<carimbo>-<nome>` e reinicia a ficha
(`synthesis_reset`) toda vez que uma sessão nova começa.

**Consequências:**
- As seis funções da ficha testadas isoladamente (idade de um fato
  logo após confirmação, distância crescendo conforme outras ações
  acontecem, janela de frescor `synthesis_fresh` recusando um fato
  velho, fato nunca confirmado devolvendo vazio, reset zerando tudo) --
  ver [findings.md](<../docs/findings.md>).
- `session_start_reset.sh` testado isoladamente (diários com conteúdo
  arquivados com carimbo de data/hora, preservando o conteúdo original;
  ficha reiniciada) -- ver [findings.md](<../docs/findings.md>).
- As sete checagens de `pre_edit_safety.sh` convertidas, mais
  `first_unread_mandatory_doc`, sintaxe conferida (`bash -n`) em todos
  os arquivos tocados.
- Mesma limitação já registrada em
  [pitfalls.md](<../docs/pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>):
  a confirmação de ponta a ponta, com o gancho `SessionStart` real
  disparando no início de uma sessão nova, não é possível dentro desta
  mesma sessão -- pendência em [tasks.md](<../docs/tasks.md>).
- `pre_commit_hygiene.sh` (checagens redundantes, deliberadamente
  independentes, no momento do commit) continua relendo o diário via
  `git diff --cached` -- não foi convertido pra ficha, de propósito:
  serve como segunda conferência que não depende do mesmo cache que as
  checagens de edição usam.
