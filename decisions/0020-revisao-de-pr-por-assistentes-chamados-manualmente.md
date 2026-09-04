# 0020 — Revisão de PR por assistentes chamados manualmente

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Decisions — 0020 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

*Em resumo:* uma revisão de PR (a mudança de uma tarefa inteira,
pronta pra virar pedido de mesclagem em `develop`) é feita por
assistentes de IA, um por assunto, chamados manualmente, numa
conversa normal -- sozinhos, ou todos juntos por um comando único.

## Status

Aceito.

## Contexto

Julgar se um PR está completo, coerente, com teste sólido e sem valor
fixo indevido no código depende de entendimento e opinião -- não é
fato que um script sozinho confirma. Regra já registrada no
`concept.md` deste módulo, seção "Escopo": "qualquer regra que
dependa de entendimento ou opinião vira pergunta explícita, devolvida
a quem pediu a tarefa, nunca decidida sozinha."

## Decisão

- Quatro assuntos, cada um com um assistente próprio (arquivo dentro
  de `.claude/agents/`): conteúdo relacionado em qualquer lugar do
  repositório que deveria estar conectado por um link; qualidade de
  teste; coerência do PR inteiro, olhado de uma vez; valor fixo no
  código que deveria vir de configuração.
- Cada assistente é chamado explicitamente, numa conversa normal --
  sozinho, ou todos de uma vez, por um comando único (`/revisar-pr`),
  que dispara os quatro em paralelo e junta o resultado.
- Toda saída de cada assistente é pergunta em aberto, citando arquivo
  e trecho exato, pra quem revisa decidir. Nenhum corrige nada
  sozinho.

## Consequências

- Documentação de como usar cada assistente, sozinho ou em conjunto,
  registrada dentro do próprio módulo (`architecture.md`).
- Teste ao vivo de verdade (chamar cada assistente numa conversa real,
  ver o resultado) ainda não aconteceu nesta rodada -- pendência
  própria em [`tasks.md`](<../docs/tasks.md>).
