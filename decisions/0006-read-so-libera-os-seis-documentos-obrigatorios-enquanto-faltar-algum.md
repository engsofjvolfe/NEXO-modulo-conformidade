# 0006 — `Read` só libera os seis documentos obrigatórios enquanto faltar algum

Até aqui, `pre_mandatory_reading_guard.sh` liberava qualquer uso da
ferramenta `Read`, não só a leitura dos seis documentos obrigatórios —
confirmado ao vivo, na sessão que motivou esta ADR: outros arquivos
(`MANUAL.md`, scripts de gancho) foram lidos antes da leitura
obrigatória, sem nada travar. Esta decisão faz `Read` só passar, nesse
período, quando o arquivo pedido é um dos seis da lista.

## Status

Aceito.

## Contexto

`CLAUDE.md`, seção "Leitura obrigatória, fonte da verdade": os seis
documentos valem "antes de qualquer outra coisa". `Read` precisa
continuar liberado durante esse período — é o único jeito de cumprir a
exigência (bloquear `Read` por completo impediria de sempre satisfazer
a própria checagem, um impasse sem saída). Mas liberar `Read` de
qualquer arquivo, sem olhar qual, deixa margem pra ler o que for antes
dos seis obrigatórios, sem violar a letra do script (a ferramenta usada
continua sendo `Read`) mas violando a intenção do `CLAUDE.md`.

Alternativas reais consideradas:
- Manter como estava (`Read` sempre livre) — descartada: é exatamente
  o comportamento que gerou o achado que motivou esta ADR.
- Bloquear `Read` por completo até a leitura obrigatória terminar —
  descartada: impossível de cumprir, porque a própria leitura
  obrigatória acontece via `Read`.
- Restringir `Read`, enquanto sobrar item da lista, ao nome exato de um
  dos seis documentos (comparando só o nome do arquivo, não o caminho
  inteiro — o link do `CLAUDE.md` é relativo, e pode ser referenciado
  de mais de um caminho relativo dependendo de onde a leitura começa)
  — escolhida.

## Decisão

Dentro de `pre_mandatory_reading_guard.sh`, quando a ferramenta é
`Read` e ainda sobra documento não lido: o caminho pedido tem o nome
comparado contra os seis nomes de `MANUAL_MANDATORY_DOCS`
(`lib/common.sh`); bate com um deles, passa; não bate, bloqueia com a
mesma mensagem de erro já usada pras demais ferramentas. Assim que os
seis documentos completam a leitura, essa restrição para de existir —
`Read` de qualquer arquivo volta a ser livre, sem checagem extra.

## Consequências

- Fecha o caminho que deixava a leitura obrigatória ser adiada
  indefinidamente por leituras de outros arquivos primeiro, sem violar
  a letra do gancho.
- Sintaxe do script conferida (`bash -n`); lógica não testada com uma
  chamada de ferramenta real dentro desta mesma sessão — mesma
  limitação já registrada em
  [decisions/0001](<0001-cobertura-do-gancho-de-leitura-obrigatoria.md>)
  (configuração de gancho não recarrega na sessão que a edita, ver
  [pitfalls.md](<../docs/pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)).
  Confirmação ao vivo fica pendente pra uma sessão nova — ver
  [tasks.md](<../docs/tasks.md>).
