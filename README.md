# Módulo de Conformidade

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow) ![Fase](https://img.shields.io/badge/fase-implementa%C3%A7%C3%A3o-blue) ![Licença](https://img.shields.io/badge/licença-todos%20os%20direitos%20reservados-red)

Uma tentativa de reduzir o risco de esquecer as regras escritas de um
projeto de software durante a própria construção dele.

Não é garantia de que isso nunca vai acontecer. E não é específico de
um projeto -- nenhum arquivo aqui dentro sabe o nome de nenhum projeto
que venha a usá-lo (ver [Sobre este projeto](#sobre-este-projeto)
e [`COMO-USAR.md`](COMO-USAR.md) pra instalar em outro projeto).

Feito especificamente pro Claude Code (a ferramenta de IA da
Anthropic) -- os mecanismos de trava usam o sistema de "ganchos" que
só essa ferramenta reconhece. Quem quiser adaptar pra outra ferramenta
de IA é livre pra fazer isso (ver Licença): os scripts em si são shell
comum, só o jeito de ligá-los a cada momento do trabalho
(`.claude/settings.json`) depende do Claude Code.

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

## Sobre onde este módulo nasceu

Este repositório é um recorte de um módulo do projeto NEXO -- é onde
ele foi criado e continua sendo usado, mas não é o único projeto que
pode usá-lo (ver [`COMO-USAR.md`](COMO-USAR.md)).

NEXO é um sistema que ensina processos com etapas — uma cirurgia, uma
reação química, um evento histórico. Quem aprende reconstrói a ordem
certa com as próprias mãos, em vez de só assistir a uma explicação.

Este módulo foi publicado à parte porque é uma ferramenta de apoio ao
*processo* de construir o NEXO. Não faz parte do sistema que a pessoa
final usa.

## Como usar em outro projeto

Ver [`COMO-USAR.md`](COMO-USAR.md) -- guia de instalação, o que cada
projeto precisa configurar (opcional), e o que fica de fora por
depender de dado específico de cada projeto.

## Como funciona, em linguagem simples

Este módulo trabalha junto de uma inteligência artificial durante a
própria construção do projeto que o usa -- no caso do Claude Code
(ver [Pré-requisito](<COMO-USAR.md#pré-requisito>)), o ambiente dá à
inteligência artificial acesso direto aos arquivos do projeto, ao
histórico de versões e à capacidade de rodar comandos.

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
