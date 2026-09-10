# ADR 0024 — Nega comandos de Bash que mostram conteúdo de arquivo

*Em resumo:* a ferramenta Read é a única forma de ler conteúdo de
arquivo que este sistema rastreia (registra na ficha, aplica a regra
de frescor). Comandos de terminal que também mostram conteúdo de
arquivo (`cat`, `head`, `tail`, `grep`, `sed`, `awk`) contornavam esse
rastreio por completo -- inclusive usados, ao vivo, nesta própria
sessão, especificamente porque a ferramenta Read estava bloqueada
naquele momento. Esses seis comandos passam a ser negados na
configuração de permissão do Claude Code, não detectados dentro de um
gancho -- uma negação nesse nível não depende de nenhuma lógica que dê
pra contornar trocando de comando.

## Status

Aceito.

## Contexto

Achado ao vivo nesta sessão: com a ferramenta Read bloqueada (leitura
obrigatória do projeto hospedeiro ainda pendente), o comando `cat` foi
usado repetidas vezes pra ler o mesmo conteúdo -- funciona pra mostrar
o texto, mas nenhum fato de "leitura completa" fica registrado, então
o mecanismo de frescor (`ADR 0023`) nunca sabe que aquela leitura
aconteceu.

Levantada a pergunta de até onde essa lacuna vai: qualquer programa
instalado numa máquina consegue abrir e mostrar o conteúdo de um
arquivo (Python, Node, PowerShell, e por aí em diante) -- um conjunto
sem fim, impossível de listar por completo.

A documentação oficial do Claude Code (seção "Configure permissions")
confirma dois fatos concretos:

- Claude Code já reconhece um conjunto fixo, documentado, de comandos
  de Bash como "somente leitura" (`ls`, `cat`, `echo`, `pwd`, `head`,
  `tail`, `grep`, `find`, `wc`, `which`, `stat`, `du`, `cd`, e formas
  de `git` que só leem) -- esses passam sem pedir confirmação, em
  qualquer modo, e a lista não é configurável em conteúdo (só é
  possível acrescentar uma regra de negação por comando).
- Fora desse conjunto fixo, um comando de Bash novo já pede
  confirmação por padrão (modo `default`/manual) -- ou seja, o
  problema real não é "qualquer programa passa sem confirmação", é só
  esse conjunto fixo, pequeno, já conhecido.

Sobre isolamento pelo sistema operacional (`sandbox`), também
pesquisado nesta sessão: existe, e funciona com WSL2 (disponível nesta
máquina), mas não resolve este problema específico -- ele restringe
*quais pastas* um comando pode tocar, nunca *qual ferramenta* foi
usada pra ler. Um `cat` dentro do isolamento continua mostrando
conteúdo normalmente, porque o isolamento não distingue "leitura que
deveria passar pela ferramenta Read" de "leitura que uma tarefa
legítima (rodar teste, conferir diferença entre versões de arquivo)
também precisa fazer.

Alternativas reais consideradas:

- **Detectar e bloquear dentro de um gancho** (script que confere
  antes da ação acontecer) — descartada como camada única: qualquer
  lista escrita dentro de um gancho pode ser trocada de lugar
  (reescrever o próprio gancho) antes de bloquear alguma coisa nova;
  a negação de permissão do Claude Code, ao contrário, é avaliada
  antes de qualquer gancho rodar.
- **Negar o Bash inteiro** — descartada: quebraria uso legítimo
  (`git`, `gh`, scripts de teste/build já usados neste projeto),
  atrito desnecessário sem ganho correspondente.
- **Negar todo o conjunto fixo de "somente leitura"** (incluindo `cd`,
  `git` que só lê, `ls`, `pwd`, etc.) — descartada: esses comandos não
  mostram conteúdo de arquivo, só metadado ou estado (nome de arquivo,
  pasta atual, existência) -- negar eles cria atrito sem reduzir o
  risco real.
- **Negar só os comandos do conjunto fixo que realmente mostram
  conteúdo** (`cat`, `head`, `tail`, `grep`), acrescentando `sed` e
  `awk` (mesma categoria, já pedem confirmação por padrão hoje, mas
  reforçados pela mesma razão) — escolhida: fecha o conjunto fixo,
  documentado, sem enumerar programa nenhum que não exista já listado
  por outra fonte (a própria documentação do Claude Code).
- **Isolamento pelo sistema operacional (`sandbox`, via WSL2)** —
  avaliada, mantida como proteção complementar, não como resposta a
  esta pergunta específica (ver Contexto acima) -- útil pra proteger
  um arquivo específico e já conhecido (ex.: o arquivo de autorização)
  contra qualquer programa, não pra decidir "qual ferramenta pode ler
  conteúdo em geral".

Sobre o conjunto sem fim (programa instalado depois, fora de qualquer
lista): decidido registrar, não tentar prever. Ver Decisão.

## Decisão

`.claude/settings.json` ganha, em `permissions.deny`:
`Bash(cat *)`, `Bash(head *)`, `Bash(tail *)`, `Bash(grep *)`,
`Bash(sed *)`, `Bash(awk *)` -- conjunto fechado, cada item já
documentado pelo próprio Claude Code como candidato a essa negação
(não inventado por este módulo).

Pro conjunto sem fim (qualquer outro programa que consiga mostrar
conteúdo de arquivo): como não dá pra negar o que não dá pra prever,
a resposta é tornar visível, não impedir de antemão -- todo comando de
Bash usado nesta sessão já fica registrado (mesmo mecanismo de log já
existente neste módulo), suficiente pra revisar depois e acrescentar
um novo item à negação acima se algum programa fora da lista aparecer
sendo usado dessa forma. Implementação do registro segue como
pendência em `tasks.md`, junto da regra absoluta correspondente no
documento de instruções do projeto hospedeiro (nunca usar programa
nenhum como substituto da ferramenta Read).

## Consequências

- `.claude/settings.json` conferido com `jq empty` depois da mudança.
- Teste ao vivo (tentar `cat`/`head`/`tail`/`grep`/`sed`/`awk` num
  arquivo do projeto, confirmando negação) segue como pendência em
  `tasks.md`.
- `cd` e as formas de `git` que só leem ficam de fora da negação, de
  propósito -- não mostram conteúdo de arquivo, e o projeto hospedeiro
  já exige conferir o histórico do git antes de reescrevê-lo.

*Nota de acompanhamento, 08-09-2026:* `cat`, `head` e `grep`
confirmados ao vivo, nesta mesma sessão, negados de verdade -- duas
tentativas de comando composto (`ls | grep ...`, `... | head -20`)
foram recusadas pelo próprio sistema de permissão por causa do
subcomando negado, mesmo dentro de um cano (`|`). `tail`, `sed` e
`awk` seguem sem teste ao vivo -- pendência ajustada em `tasks.md`
pra cobrir só esses três.
