# ADR 0016 — AUTORIZO-TRAVA rejeita reticências sem motivo real

*Em resumo:* uma mensagem que só cita a frase "AUTORIZO-TRAVA:", sem
intenção de autorizar nada agora, continuava liberando bloqueios de
verdade quando o texto citado depois dos dois-pontos era só
reticências ("...."). Corrigido: reticências logo no início do texto
capturado também não contam como motivo real, mesmo padrão já usado
pro placeholder `<motivo>`.

## Status

Aceito.

## Contexto

Achado e investigação completos em
[findings.md](<../docs/findings.md#2026-08-29-autorizo-trava-disparado-por-reticencias-em-narrativa>)
e
[analysis.md](<../docs/analysis.md#2026-08-29-relatorio-de-outra-sessao-e-reset-da-ficha-no-evento-resume>),
item 9. Alternativas reais, cada uma com um critério diferente pra
distinguir "motivo real" de "citação vazia":

- **Checar se existe letra suficiente em qualquer ponto do texto
  capturado** -- descartada: falha porque o resto do texto capturado é
  normalmente prosa alheia ao motivo em si.
- **Exigir que o texto capturado comece com letra** -- descartada:
  quebra um caso já aceito ([findings.md, 28-08-2026](<../docs/findings.md#2026-08-28-cascata-do-item-5-perdia-alternativa-de-schemas>)),
  motivo real começando com `<`.
- **Reticências no início do texto capturado tratadas como "sem motivo
  real", mesmo padrão do placeholder** -- escolhida: mira o padrão
  observado sem exigir nada do texto seguinte.

## Decisão

Em `user_prompt_submit.sh`, a checagem que já rejeitava o placeholder
`<motivo>` no início do texto capturado (`RAZAO_LIMPA`) passa a
rejeitar também texto começando com duas ou mais reticências (`^\.{2,}`).

## Consequências

- Sintaxe conferida com `bash -n` -- sem erro.
- Cinco casos testados isoladamente, sem regressão nos dois já aceitos
  antes (placeholder `<motivo>`; motivo começando com `<` mas com
  conteúdo real) -- ver
  [analysis.md](<../docs/analysis.md#2026-08-29-relatorio-de-outra-sessao-e-reset-da-ficha-no-evento-resume>),
  item 9.
