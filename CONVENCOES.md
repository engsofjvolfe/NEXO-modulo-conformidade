# Convenções de escrita e navegação — Conformidade

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Convenções |
| Licença | Todos os direitos reservados — ver [LICENSE](LICENSE) |

> Cópia, restrita a este módulo, da mesma convenção de escrita e
> navegação usada em projetos com mais de um módulo (lá, ela mora num
> índice compartilhado por todos). Como este repositório só tem um
> módulo, a convenção fica junto dele, num arquivo próprio, em vez de
> um índice pra vários.

## Como navegar

Este módulo nasce copiando o molde padrão (`docs/`, `decisions/`) e
segue, sempre, a mesma ordem de leitura e de escrita — nunca a ordem
inversa:

1. **`docs/concept.md`** — o que o módulo deve ser e como deve se
   comportar. Sempre o primeiro documento, com código já existente ou
   não.
2. **`docs/architecture.md`** — como construir, a partir do que
   `concept.md` já decidiu: layout de arquivos, pacotes, fronteiras.
   Nunca escrito a partir de código já existente.
3. **`schemas/`** — gerado do bloco YAML dentro de `concept.md`, para
   todo módulo que tenha uma fronteira de dado real. Nunca escrito à
   mão em paralelo ao YAML.
4. **Implementação** — o código em si, derivado de `architecture.md` e
   de `schemas/`, nunca o contrário. Se a implementação revela algo
   que o desenho não previu, isso vira entrada em `docs/findings.md`
   (achado) ou `docs/pitfalls.md` (armadilha de ferramenta), nunca uma
   reescrita silenciosa de `concept.md` ou `architecture.md` pra bater
   com o código.

Por que essa ordem, e não a inversa (escrever código e documentar
depois): documentar a partir do código já escrito registra o que o
código faz, não o que ele deveria fazer — qualquer erro de desenho
vira permanente, porque a documentação só concorda com ele. Descer
sempre de `concept.md` pra baixo mantém o documento como fonte da
verdade; o código é quem tem que bater com o documento, não o
contrário.

`docs/analysis.md` e `docs/findings.md` entram em qualquer ponto desse
fluxo em que existir código pra checar contra o desenho. `decisions/`
(ADR) nasce em qualquer um dos quatro passos acima, sempre que aparece
uma escolha real entre alternativas que precisa ficar registrada com o
contexto que a motivou. `docs/handoff.md` é sempre a última coisa
atualizada, depois de qualquer uma das outras mudar.

## Como escrever

- **Resumo simples primeiro, detalhe técnico depois.** Toda seção ou
  entrada começa com uma ou duas frases em linguagem comum — o que é,
  sem jargão — antes de qualquer detalhe técnico.
- **Tom impessoal.** Nunca "o proprietário pediu X" ou "decidimos Y" —
  sempre o fato observado, testado ou decidido, direto. Única exceção:
  `docs/analysis.md`, onde narrar o processo de investigação é o
  próprio propósito do arquivo.
- **Entrada datada, nunca reescrita.** Em `docs/analysis.md`,
  `docs/findings.md` e `docs/pitfalls.md`, cada entrada leva uma âncora
  no formato `AAAA-MM-DD-título-curto` e nunca é editada depois de
  escrita — se algo deixa de valer, ganha uma entrada nova, datada.
  Mesma lógica em `decisions/`: uma ADR aceita não é reescrita pra
  revisar a decisão em si — decisão que muda gera uma ADR nova.
- **Campos fixos por tipo de arquivo:** `docs/analysis.md` leva
  `Levou a`; `docs/findings.md` leva `Confirmado por` (`leitura de
  código` | `teste ao vivo` | `leitura de código e teste ao vivo`);
  toda ADR em `decisions/` leva um resumo em linguagem simples seguido
  de `Status`, `Contexto`, `Decisão`, `Consequências`, nessa ordem.
- **`docs/handoff.md` só aponta.** Link markdown de verdade mais uma
  frase curta — nunca uma descrição do que o conteúdo diz.
- **Pendência resolvida nunca é apagada.** Em `docs/tasks.md`, todo
  item riscado continua na seção "Resolvidas", apontando pro achado ou
  pra ADR que resolveu ele.
- **Esquema de dado é dado puro.** Qualquer esquema carrega só a
  estrutura em si — sem narrativa, sem exemplo de uso, sem explicação
  de por quê. Esse contexto mora no texto ao redor do esquema.
