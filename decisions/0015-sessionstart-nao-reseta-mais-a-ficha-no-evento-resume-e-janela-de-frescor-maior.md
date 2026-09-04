# ADR 0015 — SessionStart não reseta mais a ficha no evento resume, e janela de frescor da leitura obrigatória fica bem maior

*Em resumo:* o mecanismo que apaga o registro de leitura/edição da
sessão ("ficha") continuava disparando sozinho, no meio do trabalho,
mesmo depois da correção de 28-08-2026 -- só o gatilho errado tinha
mudado (de `compact` pra `resume`). Corrigido tirando `resume` do
gatilho de apagar também, e a validade de cada leitura dos seis
documentos manuais obrigatórios ficou bem mais longa, pra aguentar uma
sessão de trabalho inteira sem expirar à toa.

## Status

Aceito.

## Contexto

Investigação completa em
[analysis.md](<../docs/analysis.md#2026-08-29-relatorio-de-outra-sessao-e-reset-da-ficha-no-evento-resume>);
achado confirmado em
[findings.md](<../docs/findings.md#2026-08-29-sessionstart-ainda-reseta-a-ficha-no-evento-resume>).
Duas decisões distintas, tomadas juntas por resolverem o mesmo
sintoma: o gatilho de `resume`, deixado ativo pela correção anterior
([decisions/0013](<0013-frescor-uniforme-de-leitura-substitui-permanencia.md>)),
continua apagando a ficha fora do controle da sessão; e a janela de
frescor da leitura obrigatória (20 ações) é curta demais pra uma
sessão de trabalho real.

Alternativas reais consideradas pro gatilho de `resume`:

- **Manter `resume` no gatilho de apagar, e só alongar a janela de
  frescor** -- descartada: mesmo com janela grande, um `resume`
  disparando logo depois de uma leitura ainda zera o contador de ações
  da ficha inteira (não só das seis leituras), perdendo também
  qualquer outro registro (edições, achados, ADRs já confirmados
  nesta sessão) sem necessidade.
- **Remover `session_start_reset.sh` do evento `resume` por completo,
  sem rodar nada ali** -- descartada: `session_start_import_check.sh`
  (a segunda checagem do mesmo bloco, que só lê e confere se os 16
  documentos automáticos existem, nunca apaga nada) continua útil de
  rodar em qualquer recarregamento, sem custo nem risco.
- **Separar o bloco: `resume` roda só `session_start_import_check.sh`,
  `startup`/`clear` continuam rodando os dois** -- escolhida: resolve o
  reset indevido sem perder a checagem inofensiva.

Alternativas reais consideradas pra janela de frescor:

- **Manter a janela de 20 ações, compartilhada com a citação de
  documento** -- descartada: pouco pra uma sessão de trabalho real,
  com dezenas de leituras e edições entre a leitura dos seis
  documentos e o momento em que eles ainda precisam contar como
  lidos.
- **Janela sem limite (permanência, como era antes de
  decisions/0013)** -- descartada: contradiz o princípio já
  estabelecido ali ("nenhuma leitura vale pra sempre").
- **Janela própria, bem maior (500 ações), só pros seis documentos
  manuais, sem mexer na janela de citação de documento (ainda 20)** --
  escolhida: os dois julgamentos continuam diferentes (ver
  decisions/0013) -- citar um documento por nome é evento pontual, os
  seis documentos manuais são condição de fundo que precisa aguentar a
  sessão inteira.

## Decisão

Em `.claude/settings.json`, o bloco de `SessionStart` que rodava
`session_start_reset.sh` e `session_start_import_check.sh` juntos, sob
`"matcher": "startup|resume|clear"`, vira dois blocos: um com
`"matcher": "startup|clear"` rodando os dois scripts (igual antes,
menos `resume`), outro novo com `"matcher": "resume"` rodando só
`session_start_import_check.sh`.

Em `lib/common.sh`, `MANDATORY_READ_FRESHNESS_WINDOW` sobe de 20 pra
500 -- constante já era separada de `RECENCY_WINDOW`
(`pre_edit_safety.sh`, ainda 20, sem mudança), só o valor muda.

## Consequências

- Sintaxe de `lib/common.sh` conferida com `bash -n` -- sem erro;
  `.claude/settings.json` conferido com `jq empty` -- JSON válido.
- Nenhuma mudança de comportamento pra citação de documento nem pras
  outras checagens de `pre_edit_safety.sh` que usam `RECENCY_WINDOW`
  (ainda 20 ações) -- só a janela dos seis documentos manuais, e o
  gatilho de reset, mudaram.
- Confirmação de ponta a ponta, numa sessão nova que já carregue os
  arquivos corrigidos desde o início (mesma limitação já registrada
  pras rodadas anteriores deste módulo -- ver
  [pitfalls.md](<../docs/pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)),
  segue como pendência em [tasks.md](<../docs/tasks.md>).
