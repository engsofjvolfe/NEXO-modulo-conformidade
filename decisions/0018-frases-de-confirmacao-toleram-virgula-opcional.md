# ADR 0018 — Frases de confirmação toleram vírgula opcional

*Em resumo:* as cinco frases de confirmação pontual (ex.: "commit
revisado, confirmado") exigiam a vírgula exata pra bater com o texto
digitado -- uma tentativa real, sem essa vírgula, não destravava nada,
sem nenhum aviso do motivo. A vírgula de cada frase virou opcional na
comparação.

## Status

Aceito.

## Contexto

Achado e teste completos em
[findings.md](<../docs/findings.md#2026-08-29-frase-de-confirmacao-exigia-pontuacao-exata>).
Reproduzido ao vivo: uma tentativa real de digitar "commit revisado,
confirmado" chegou sem a vírgula, e a comparação por texto literal
(`grep -qi`) não reconheceu.

Alternativas reais consideradas:

- **Manter comparação de texto literal, exigindo a pontuação exata**
  -- descartada: mesmo problema de fundo já corrigido em
  [decisions/0016](<0016-autorizo-trava-rejeita-reticencias-sem-motivo-real.md>)
  pro `AUTORIZO-TRAVA`, agora reproduzido nas frases de confirmação --
  rigidez sem motivo real, já que a intenção da pessoa é clara mesmo
  sem a vírgula.
- **Trocar por comparação sem pontuação nenhuma (remover toda
  pontuação de ambos os lados antes de comparar)** -- descartada: mais
  código, mais um caminho de normalização pra manter -- desnecessário
  quando o problema real é só uma vírgula específica em cada frase.
- **Vírgula de cada frase vira opcional na comparação, via expressão
  regular** -- escolhida: mudança mínima, direto na tabela já
  existente, sem exigir reescrever a lógica do laço.

## Decisão

Em `user_prompt_submit.sh`, a comparação de cada frase de
`CONFIRMATION_PHRASES` passa de texto literal (`grep -qi "$frase"`)
pra expressão regular (`grep -qiE "$frase_regex"`), onde
`frase_regex` é a frase original com cada `, ` trocado por `,? *`.

## Consequências

- Sintaxe conferida com `bash -n` -- sem erro.
- Testado isoladamente: frase sem vírgula passa a confirmar; frase com
  vírgula continua confirmando (regressão); frase totalmente diferente
  continua sem confirmar; `AUTORIZO-TRAVA` (mecanismo separado, não
  tocado por esta ADR) continua exigindo o dois-pontos, sem regressão
  dos achados anteriores sobre ele.
