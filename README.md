# NEXO — Módulo de Conformidade

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow) ![Fase](https://img.shields.io/badge/fase-implementa%C3%A7%C3%A3o-blue) ![Licença](https://img.shields.io/badge/licença-todos%20os%20direitos%20reservados-red)

Uma tentativa de reduzir o risco de esquecer as regras do projeto NEXO
durante a própria construção dele.

Não é garantia de que isso nunca vai acontecer.

## Qual problema ele tenta reduzir

Um projeto de software tem regras sobre como o trabalho deve ser
feito. Em que ordem escrever a documentação, como organizar o
histórico do código, o que não pode faltar antes de considerar uma
tarefa pronta.

Essas regras, escritas só como texto, dependem de alguém lembrar delas
em toda tarefa. Texto que só "deveria ser lembrado" tende a ser
esquecido, cedo ou tarde.

Este módulo existe pra reduzir esse risco. Parte das regras vira
checagem automática, que tenta barrar uma ação errada antes dela
acontecer.

Isso não elimina o risco por completo. O próprio mecanismo já revelou,
mais de uma vez, falhas nele mesmo — registradas em `docs/findings.md`,
nunca escondidas.

Quem criou este módulo ainda está aprendendo como ele funciona por
dentro, de verdade. Cada correção registrada em `docs/findings.md` é
prova disso — não um sinal de que o módulo parou de evoluir.

## Sobre o projeto NEXO

Este repositório é um recorte de um módulo do projeto principal,
[NEXO](https://github.com/engsofjvolfe/NEXO-embriologia).

NEXO é um sistema que ensina processos com etapas — uma cirurgia, uma
reação química, um evento histórico. Quem aprende reconstrói a ordem
certa com as próprias mãos, em vez de só assistir a uma explicação.

Este módulo foi publicado à parte porque é uma ferramenta de apoio ao
*processo* de construir o NEXO. Não faz parte do sistema que a pessoa
final usa.

## Como usar dentro de um projeto

Quem tiver autorização de uso deste repositório (ver Licença, abaixo)
pode copiá-lo pra dentro de qualquer projeto que use o mesmo ambiente
de programação (VSCode com a extensão Claude Code).

O encaixe é direto: cada pasta daqui vai pro mesmo caminho, contando a
partir da raiz do outro projeto. `.claude/agents/` deste repositório
vira `.claude/agents/` lá; `.claude/hooks/` vira `.claude/hooks/`, e
assim por diante — sem precisar mudar nada dentro dos arquivos.

| Pasta ou arquivo aqui | O que é, em linguagem simples |
|---|---|
| `.claude/agents/` | Assistentes de revisão de código, chamados só quando pedido. |
| `.claude/hooks/` | As travas automáticas em si. |
| `.claude/settings.json` | Liga cada trava ao momento certo do trabalho. |
| `.claude/skills/` | Atalhos de comando, como `/revisar-pr`. |
| `scripts/` | As mesmas travas, do lado do `git` nativo. |
| `MANUAL.md` | Índice cruzando cada regra do projeto com a trava real que a aplica. |
| `.vale.ini`, `.vale/` | Configuração opcional de estilo de prosa. |

## Como funciona, em linguagem simples

O projeto NEXO conta com o apoio de uma inteligência artificial
durante a própria construção. No caso deste módulo, o ambiente VSCode
com a extensão Claude Code.

Essa extensão dá à inteligência artificial acesso direto aos arquivos
do projeto, ao histórico de versões e à capacidade de rodar comandos.

Quem desenvolve o projeto escreve a documentação e decide cada coisa.
A inteligência artificial entra depois, conferindo se cada regra foi
seguida — o tipo de checagem repetitiva que tomaria tempo se feita à
mão, toda vez.

Este módulo é essa camada de checagem automática: programas pequenos
chamados "ganchos", presos a um momento específico do trabalho (por
exemplo, "antes de salvar um arquivo").

Quando a resposta depende de opinião — não dá pra confirmar como fato
puro —, o mecanismo nunca decide sozinho. Sempre devolve a pergunta
pra pessoa decidir.

A responsabilidade pelo resultado final continua sempre da pessoa,
nunca da ferramenta.

## Licença

Todos os direitos reservados. Nada deste repositório pode ser
copiado, redistribuído, modificado ou usado sem autorização direta de
quem detém os direitos, concedida caso a caso. Ver [LICENSE](LICENSE).

## Créditos

Autoria assinada como **N. Denominado** — de propósito: o nome
verdadeiro por trás do projeto nunca foi decidido, e não vai ser,
aqui.
