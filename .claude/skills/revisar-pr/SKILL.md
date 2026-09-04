---
description: Revisa o PR atual (mudanças desde develop) chamando quatro assistentes especializados em paralelo, e devolve os achados de cada um pra confirmação -- nunca corrige nada sozinho.
---

Quando este comando for chamado:

1. Descubra o intervalo de mudanças desta tarefa a partir do diretório
   atual (a worktree da tarefa): `git diff develop...HEAD --stat`.
2. Chame, na MESMA mensagem, em paralelo, os quatro assistentes de
   revisão de PR, cada um com o mesmo intervalo de mudanças
   identificado no passo 1: `revisor-referencias-cruzadas`,
   `revisor-testes`, `revisor-visao-de-conjunto`, `revisor-valores-fixos`.
3. Espere o resultado dos quatro. Apresente pra quem pediu a revisão,
   agrupado por assistente, exatamente o que cada um devolveu -- sem
   resumir, sem filtrar, sem decidir sozinho qual achado é relevante.
   Se um assistente não achou nada, diga isso também.
4. Depois de apresentar os quatro resultados, registre que a revisão
   rodou:
   ```bash
   echo "$(date -u +%FT%TZ) revisao-de-pr executada" >> .claude/hooks/state/pr-review-log.txt
   ```

Nunca corrija nada sozinho a partir do que os assistentes apontarem --
cada achado é uma pergunta em aberto, devolvida pra quem pediu a
revisão decidir.
