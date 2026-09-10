# Como usar este módulo em outro projeto

Guia curto de instalação. Para o que o módulo faz e por que existe,
ver [README.md](README.md).

## Pré-requisito

Feito especificamente pro [Claude Code](https://claude.com/product/claude-code)
(CLI ou extensão VSCode/JetBrains) -- os scripts de trava são shell
comum (`bash`, `jq`), mas o jeito de ligá-los a cada momento do
trabalho (leitura de arquivo, edição, fim da resposta, etc.) usa o
sistema de "ganchos" (hooks) que só essa ferramenta reconhece. Adaptar
pra outra ferramenta de IA é possível em princípio -- os scripts em si
não dependem do Claude Code pra rodar -- mas não é testado nem
documentado aqui.

Precisa de `bash` e `jq` instalados e disponíveis no terminal.

`scripts/instalar.sh` (ver [Instalação](#instalação) abaixo) só foi
testado no Windows (usa PowerShell pra criar o atalho de pasta) --
funciona a partir do Git Bash. Em Linux/Mac, o mesmo resultado se
consegue trocando o comando de criação de atalho por `ln -s` (link
simbólico -- recurso equivalente, sem exigir privilégio especial nesses
sistemas), mas isso ainda não está automatizado neste script.

## Instalação

Dois passos, sem precisar editar nada dentro dos arquivos copiados:

1. Copiar este repositório inteiro pra dentro do projeto que vai
   usá-lo, em QUALQUER caminho -- não existe caminho fixo nem
   convenção obrigatória (não precisa, por exemplo, existir uma pasta
   `modulos/` no projeto de destino). O nome da pasta copiada também é
   livre.
2. Da RAIZ do projeto hospedeiro (não de dentro da pasta copiada),
   rodar, uma única vez, apontando pro script já copiado -- por
   exemplo, se copiado pra `ferramentas/conformidade/`:

   ```
   ferramentas/conformidade/scripts/instalar.sh
   ```

   Esse comando descobre e grava onde a pasta foi colocada (arquivo
   `.claude/conformidade-caminho`), cria dois atalhos de pasta na raiz
   do projeto (`.claude/hooks`, `.claude/agents`, apontando pro
   conteúdo real dentro da pasta copiada -- editar um edita o outro,
   sempre), copia o que não pode ser atalho de pasta
   (`.claude/settings.json`, `.claude/skills/revisar-pr`,
   `.github/pull_request_template.md`, `.vale.ini`/`.vale/styles`,
   `scripts/`), e liga os vigias nativos do git (`core.hooksPath`).
   Não precisa de privilégio de administrador.

Depois deste único comando, qualquer atualização (puxando uma versão
nova do repositório) passa a valer sozinha, a cada início de uma
sessão nova do Claude Code -- nunca precisa rodar o comando de novo,
nem copiar nada à mão outra vez. Mover a pasta de lugar depois exige
rodar `scripts/instalar.sh` de novo (o comando não substitui atalho de
pasta já existente apontando pro lugar antigo -- remova
`.claude/hooks`/`.claude/agents` à mão antes de instalar de novo, se
for esse o caso).

Nenhum arquivo deste módulo cita o nome de nenhum projeto específico --
tudo que precisa de dado próprio de cada projeto (ver próxima seção) é
lido de fora, nunca escrito dentro do código deste módulo.

## O que cada projeto precisa configurar, se quiser usar

Tudo abaixo é opcional -- sem configurar nada, o módulo já aplica as
regras que não dependem de dado nenhum específico do projeto (nunca
usar emoji, nunca commitar esquema de dado com exemplo embutido, entre
outras).

- **Lista de leitura manual obrigatória.** Se o projeto quiser que
  certos documentos sejam lidos por inteiro antes de qualquer trabalho
  começar, marque o trecho da lista, dentro do próprio arquivo de
  instruções do projeto (`CLAUDE.md`, na raiz ou dentro de `.claude/`),
  com estas duas linhas fixas, cada item entre elas como link markdown:

  ```markdown
  <!-- conformidade-leitura-obrigatoria-inicio -->
  - [nome-do-documento.md](caminho/pro/documento.md)
  - [outro-documento.md](caminho/pro/outro.md)
  <!-- conformidade-leitura-obrigatoria-fim -->
  ```

  Sem essas marcações, este mecanismo simplesmente não exige nada.

- **Ferramentas internas fora do controle de versão.** Se o projeto
  não quiser versionar este conteúdo junto do código do produto, crie
  um bloco no `.gitignore` do projeto, começando com a linha exata
  `# Ferramentas internas de trabalho desta sessao`, listando cada
  caminho (uma barra `/` no início, sem comentário na mesma linha do
  caminho). Sem esse bloco, os caminhos citados ali (`.claude/hooks`,
  `.claude/agents`, entre outros) contam sempre como parte comum do
  projeto -- não isentos de nenhuma regra. Bloco pronto pra copiar
  (cobre tudo que `scripts/instalar.sh` cria, copia ou grava --
  ajustar `<caminho-onde-copiei>` pro caminho real escolhido no passo
  1 da instalação):

  ```gitignore
  # Ferramentas internas de trabalho desta sessao
  /.claude/agents/
  /.claude/hooks/
  /.claude/settings.json
  /.claude/conformidade-caminho
  /.claude/skills/
  /.github/
  /.vale.ini
  /.vale/
  /scripts/
  /<caminho-onde-copiei>/
  ```

  Ajuste o caminho de `.github/` e `.vale.ini`/`.vale/` se o projeto já
  tiver conteúdo próprio nessas pastas, sem relação com este conteúdo
  -- nesse caso, versione a pasta normalmente e ignore só o arquivo
  específico que foi copiado.

- **Modelo de corpo de PR.** `pre_pr_description_check.sh` confere se
  o texto de `gh pr create --body "..."` contém as quatro seções que
  este módulo espera. Se o projeto usa outro modelo, edite os quatro
  títulos procurados dentro desse script.

## Prática recomendada, fora do que o módulo checa sozinho

Nem toda regra de um projeto dá pra virar checagem automática -- regra
que depende de entendimento ou opinião continua exigindo conferência
humana (ver [O que este módulo nunca decide sozinho](#o-que-este-módulo-nunca-decide-sozinho)
abaixo). Uma prática que ajuda a não perder essa parte de vista:
manter, no próprio projeto (nunca dentro deste módulo -- ver
[Instalação](#instalação) acima, nenhum arquivo daqui cita nome de
projeto nenhum), um documento-checklist cruzando cada regra do arquivo
de instruções do projeto (`CLAUDE.md`) contra o mecanismo real que a
aplica (gancho, ou "nenhum -- checagem manual"), servindo de prova de
cobertura, não de narrativa. Formato sugerido: uma linha por regra (ou
faixa de linhas) do `CLAUDE.md`, uma coluna com o script/gancho que a
aplica, uma coluna "checagem manual" pra regra sem solução automática
possível.

## O que este módulo nunca decide sozinho

Toda checagem que depende de julgamento (não dá pra confirmar como
fato puro) devolve uma pergunta explícita, nunca decide por conta
própria. A responsabilidade pelo resultado final continua sempre de
quem conduz o trabalho, nunca da ferramenta.

## Licença

Ver [README.md, Licença](README.md#licença).
