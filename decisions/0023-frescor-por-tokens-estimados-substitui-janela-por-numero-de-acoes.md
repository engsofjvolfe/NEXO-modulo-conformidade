# ADR 0023 — Frescor por tokens estimados substitui janela por número de ações

*Em resumo:* até esta rodada, "uma leitura ainda está fresca" era
medido contando quantas ações da sessão se passaram desde a última
leitura completa (`ADR 0013`, janela de 20 ações). Essa contagem foi
trocada por uma medida baseada em tokens estimados (pedaços de texto,
a unidade que o modelo processa) de conversa que se passaram desde a
leitura — uma medida única, igual pra qualquer arquivo do projeto
hospedeiro ou deste próprio módulo, incluindo os documentos que o
projeto hospedeiro define como obrigatórios.

## Status

Aceito. Substitui `ADR 0013` na parte de contagem de frescor (a
separação entre "quais documentos exigem isso" e "como frescor é
medido", que `ADR 0013` também decidiu, continua valendo).

## Contexto

A contagem por ações tem um problema real: ela não reflete quanto
*conteúdo de conversa* passou entre a leitura e o momento atual — uma
única ação pode ser separada da leitura por uma resposta longa, uma
investigação extensa, ou pela compactação nativa do Claude Code (o
resumo automático que a própria ferramenta gera quando a conversa
fica comprida demais pra caber na janela de contexto do modelo). Uma
leitura feita há poucas ações, mas depois de um volume enorme de
texto no meio do caminho, ainda contava como fresca — exatamente o
tipo de situação em que o conteúdo pode ter deixado de estar
garantido, palavra por palavra, na memória de trabalho do modelo.

Além disso, a regra até aqui só cobria uma exigência: reler antes de
editar (`pre_edit_safety.sh`, item 1) e citar documento (item 4), com
leitura *parcial* (só um pedaço do arquivo) de qualquer arquivo
liberada sem condição nenhuma. Isso abre uma brecha: nada impedia ler
só um pedaço de um documento nunca lido por inteiro, ou lido há muito
tempo, e seguir como se o conteúdo inteiro fosse conhecido.

Alternativas reais consideradas:

- **Manter a janela por número de ações** (status quo de `ADR 0013`)
  — descartada: não mede o que realmente importa (quantidade de
  conversa, não quantidade de eventos), e não cobre leitura parcial.
- **Frescor medido por tempo de relógio** (ex.: minutos desde a
  leitura) — descartada: sessões ficam pausadas ou lentas por motivos
  sem relação com quanto a conversa avançou; tempo de relógio não
  reflete volume de conteúdo processado.
- **Frescor medido por tokens estimados de conversa, com limite
  arbitrário** — descartada: um número escolhido sem base concreta é
  exatamente o tipo de "valor mágico" que este projeto evita em
  outras partes (ver `.gitignore`, isenção de ferramenta interna, lida
  dinamicamente em vez de listada à mão).
- **Frescor medido por tokens estimados, com limite baseado num fato
  documentado** — escolhida: o limite usado (150 mil tokens) é o
  gatilho padrão de compactação automática documentado pela Anthropic
  para a API da Claude — o ponto real em que o conteúdo de uma
  leitura anterior corre risco de ter virado resumo, não mais estar
  disponível palavra por palavra. Não é um número inventado por este
  módulo.

## Decisão

`lib/common.sh` ganha `CHARS_POR_TOKEN_ESTIMADO` (4, aproximação
padrão caractere-por-token), `LIMIAR_TOKENS_FRESCOR` (150000),
`transcript_chars()` (tamanho em bytes do arquivo de transcrição da
sessão), `synthesis_set_bytes()`/`synthesis_get_bytes()` (marca/lê o
tamanho da transcrição no momento de uma leitura completa, guardado
na mesma ficha que já existia, sob uma chave própria
`leitura_bytes.<caminho>`) e `synthesis_fresh_bytes()` (compara o
crescimento da transcrição desde a leitura contra o limiar).

Regra única, sem exceção de escopo: toda leitura completa de qualquer
arquivo grava esse fato; toda leitura parcial (offset/limit) exige
uma leitura completa fresca do mesmo arquivo antes, sem isso, bloqueio
— vale pra qualquer arquivo do projeto hospedeiro e deste próprio
módulo. Os documentos que o projeto hospedeiro define como obrigatórios
(ver `pre_mandatory_reading_guard.sh`) passam a usar a mesma medida.

Documentos que o próprio módulo de conformidade define como
obrigatórios pra edição dentro dele mesmo seguem a mesma regra, no
próprio escopo do módulo — nunca a lista de obrigatórios do projeto
hospedeiro, e vice-versa: cada escopo (projeto hospedeiro, módulo de
conformidade) tem sua própria exigência de leitura obrigatória,
nunca uma cobrindo a outra.

A janela por número de ações (`ADR 0013`) continua em uso nos pontos
que ainda não foram convertidos nesta rodada (`pre_edit_safety.sh`,
itens 5 a 8) — conversão completa segue como pendência em `tasks.md`.

## Consequências

- `lib/common.sh` e `pre_mandatory_reading_guard.sh` reescritos e
  conferidos com `bash -n` — sem erro de sintaxe.
- Isenção do gancho de leitura obrigatória corrigida no mesmo
  trabalho: comparava caminho sem normalizar barra invertida do
  Windows, nunca batendo pra Read/Write/Edit (só por acaso batia pra
  Bash) — achado ao vivo nesta sessão, registrado em `findings.md`.
- Teste isolado e ao vivo, e conversão completa dos itens 5 a 8 de
  `pre_edit_safety.sh` pra esta mesma medida, seguem como pendência em
  `tasks.md`.

*Nota de acompanhamento, 08-09-2026:* a conversão dos itens 5 a 8 de
`pre_edit_safety.sh` pra `synthesis_fresh_bytes`, citada acima como
pendência, já foi concluída na mesma rodada em que este ADR foi
escrito -- frase desatualizada no texto original. O fluxo completo
"leitura cheia grava o fato, edição em seguida lê o fato" foi
confirmado ao vivo: uma leitura repetida do mesmo arquivo, sinalizada
pelo sistema como "sem mudança desde a última leitura", ainda assim
liberou a edição seguinte -- prova de que o rastro gravado por
`post_read_track.sh` sobrevive a esse atalho. Dois pontos específicos
seguem sem teste ao vivo, ajustados em `tasks.md`: (1) leitura parcial
(offset/limit) sem leitura cheia fresca antes bloqueando de verdade;
(2) edição/escrita por cima de um arquivo já existente, sem leitura
fresca, bloqueando de verdade (extensão desta rodada pra cobrir também
`Write`).
