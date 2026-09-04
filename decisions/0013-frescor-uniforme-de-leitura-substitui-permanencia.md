# ADR 0013 — Frescor uniforme de leitura substitui permanência

*Em resumo:* até esta rodada, os seis documentos da leitura manual
obrigatória (a cascata V-Model numerada, mais o `prompt model.txt`)
eram tratados como "lidos pra sempre" dentro de uma sessão — bastava
ter lido uma vez, em qualquer ponto, não importa há quanto tempo. Essa
permanência foi trocada por frescor: nenhuma leitura vale pra sempre,
a pergunta é sempre "li de fresco o bastante pra confiar agora?" — o
mesmo princípio já usado só pra citação de documento num texto novo,
agora estendido aos seis documentos manuais.

## Status

Aceito.

## Contexto

O mecanismo de "ficha" (registro compacto do que já foi lido/editado
na sessão, em `.claude/hooks/state/synthesis.json`) guarda, pra cada
fato, o número da ação em que ele foi confirmado pela última vez.
`synthesis_fresh` já existia e já checava se essa distância (ação
atual menos ação registrada) cabia numa janela aceitável — mas só era
usado pra um caso: citar outro documento por nome dentro de um texto
novo (`pre_edit_safety.sh`, item 4). Pros seis documentos manuais, a
checagem (`first_unread_mandatory_doc`) usava `synthesis_age` sem
limite nenhum — uma leitura feita no primeiro minuto da sessão contava
como válida no último, mesmo depois de centenas de outras ações,
outras leituras, outras edições no meio do caminho.

O comentário que justificava essa permanência dizia que "leitura
obrigatória é sobre ORDEM ('antes de qualquer outra coisa'), não um
fato que precisa ficar sendo reconfirmado". Essa distinção não se
sustenta: o próprio `CLAUDE.md`, na abertura, já diz "não concluir o
desenho de uma mudança só a partir do que já chegou carregado" — um
princípio geral, sem exceção anunciada pros seis documentos manuais.
Tratar esses seis como um caso especial, permanente, contradiz esse
princípio geral que o resto do sistema já segue.

Alternativas reais consideradas:

- **Manter a permanência** (status quo) — descartada: contradiz o
  princípio geral já citado, e não tem justificativa própria além do
  comentário que este ADR já mostrou ser incorreto.
- **Frescor sem janela nenhuma — exigir leitura na ação imediatamente
  anterior** — descartada: rígida demais, forçaria reler os seis
  documentos entre praticamente toda ação da sessão, tornando o
  trabalho impraticável.
- **Frescor com janela própria, diferente da usada em citação de
  documento** — descartada: duas janelas diferentes pro mesmo tipo de
  julgamento ("isso ainda está fresco?") sem motivo concreto pra
  distinguir os dois casos -- mais uma constante pra manter sincronizada
  sem ganho real.
- **Frescor com a mesma janela já usada em citação de documento (20
  ações)** — escolhida: reaproveita um valor já em produção, testado,
  sem introduzir uma segunda constante arbitrária.

Sobre que documentos entram nessa exigência: o princípio de frescor
("nenhuma leitura vale pra sempre") vale pra qualquer documento do
projeto, sem exceção — mas isso não significa que todo documento
precisa do mesmo tipo de trava. Ver `Decisão` abaixo pra separação
entre os dois grupos.

## Decisão

`first_unread_mandatory_doc()` (`lib/common.sh`) passa a usar
`synthesis_fresh("leitura.<doc>", 20)` em vez de `synthesis_age`
sem limite, pros seis documentos da leitura manual obrigatória —
mesma janela (`RECENCY_WINDOW`, 20 ações) já usada pra citação de
documento. Comentário da função corrigido, removendo a justificativa
de permanência.

Os dezesseis documentos que carregam automaticamente (via `@caminho`
no `CLAUDE.md`) e o próprio `CLAUDE.md` não entram nessa mesma
checagem de bloqueio-antes-de-tudo — eles nunca passam por `Read`
explícito no fluxo normal, então não têm um fato de leitura pra
expirar. Continuam cobertos, como já eram, pelos itens genéricos de
`pre_edit_safety.sh` que se aplicam a qualquer arquivo do projeto: item
1 (reler de fresco antes de editar o próprio arquivo) e item 4 (reler
de fresco qualquer documento citado por nome num texto novo) — ambos
também levados pra frescor de 20 ações nesta mesma rodada. A checagem
exige leitura fresca no momento em que aquele documento específico
realmente importa pra uma decisão (editá-lo, ou citá-lo), não como uma
trava solta rodando o tempo todo sem relação com o que está sendo
feito.

O mesmo princípio se estende à ordem completa `concept.md` →
`architecture.md` → `schemas/` → implementação, já conferida em
`pre_edit_safety.sh` item 5: cada passo passa a exigir leitura fresca
do passo anterior (`leitura.concept.md` pra editar `architecture.md`,
`leitura.architecture.md` pra editar `schemas/`), em vez de só "o
passo anterior foi editado nesta sessão" (`edicao.*`). Escrever
implementação (código) aceita `architecture.md` **ou** qualquer
arquivo dentro de `schemas/` como leitura fresca válida -- nem todo
módulo tem pasta `schemas/` (ex.: este módulo, `conformidade`, sem
contrato de dado próprio), então exigir as duas coisas sempre
bloquearia um módulo assim sem necessidade; como arquivo de esquema
não tem nome fixo, essa checagem usa uma função nova,
`synthesis_any_fresh_with_prefix` (`lib/common.sh`), que aceita
qualquer fato de leitura cuja chave comece com o caminho da pasta
`schemas/` daquele módulo. Caso novo, sem equivalente na checagem
antiga: escrever uma ADR em `modulos/<mod>/decisions/*.md` exige
leitura fresca de `concept.md` **e** `architecture.md` desse módulo --
pulada se o módulo ainda não existir em disco (módulo novo, nada pra
reler ainda).

Achado colateral, resolvido no mesmo trabalho por depender do mesmo
arquivo (`synthesis.json`): escritas concorrentes na ficha podiam
truncá-la ou perder fatos — ver
[findings.md](<../docs/findings.md#2026-08-28-corrupcao-e-perda-de-fato-na-ficha-por-escrita-concorrente>)
pro achado completo. Segundo achado colateral, sem relação com o
primeiro: `jq` neste ambiente devolve linha terminada em `\r\n`,
quebrando a comparação de chave dentro de um laço -- ver
[pitfalls.md](<../docs/pitfalls.md#2026-08-28-jq-devolve-linha-com-retorno-de-carro-neste-ambiente>).

## Consequências

- Sintaxe de `lib/common.sh` e `pre_edit_safety.sh` conferida com
  `bash -n` — sem erro.
- Nenhuma mudança de comportamento pros itens que já usavam
  `synthesis_fresh` (citação de documento) — só a fonte de frescor dos
  seis documentos manuais, e do restante da cascata do item 5, mudou.
- Efeito prático esperado: numa sessão longa (a ponto de disparar
  resumo automático de contexto), é provável que a janela de 20 ações
  já tenha vencido de qualquer forma antes do resumo acontecer,
  cobrindo na prática a preocupação de "será que ainda lembro do
  conteúdo desses documentos" sem precisar de uma trava dedicada só ao
  momento da compactação. O apagamento indevido do registro inteiro
  nesse mesmo momento (defeito separado, não sobre frescor) está
  registrado em
  [findings.md](<../docs/findings.md#2026-08-28-sessionstart-sem-matcher-reseta-a-ficha-na-compactacao>)
  e corrigido em `.claude/settings.json`.
- Testado isoladamente antes do commit, casos positivos e negativos
  pra cada ponto -- ver
  [findings.md](<../docs/findings.md#2026-08-28-corrupcao-e-perda-de-fato-na-ficha-por-escrita-concorrente>)
  e
  [findings.md](<../docs/findings.md#2026-08-28-lacuna-de-trava-mecanica-em-pitfalls-findings-decisions>).
  Confirmação numa sessão nova de verdade (ganchos rodando a partir da
  pasta principal do repositório, não desta worktree) segue como
  pendência em `tasks.md` — mesma limitação já registrada pras rodadas
  anteriores deste módulo.
