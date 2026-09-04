# 0014 — Formato de resposta corrigido em todo gancho "agent"/"prompt"; dois removidos, quatro mantidos

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Decisions — 0014 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

*Em resumo:* os seis pontos do sistema que usavam uma segunda
inteligência artificial (chamada à parte, com acesso a ferramentas
como ler arquivo e buscar texto) pediam essa segunda inteligência pra
responder num formato que o Claude Code não reconhece pra esse tipo de
checagem — corrigido em todos os seis. Dois desses pontos (revisão de
commit, revisão de teste no preview) foram removidos por completo,
porque o que checavam já está coberto por script comum, sem
inteligência artificial nenhuma. Os outros quatro (revisão de edição
de documento, e as três checagens do fim da resposta) continuam
existindo, com o formato corrigido.

## Status

Aceito.

## Contexto

Quatro pontos do sistema usavam um gancho do tipo "agent" (edição de
documento, commit no git, início do teste no preview) e dois usavam o
mesmo tipo no evento de fim de resposta — uma segunda inteligência
artificial, chamada à parte, com acesso, em teoria, a ferramentas como
ler arquivo e buscar texto, pra julgar coisas que um script sozinho
não julga (tom pessoal, duplicação de conteúdo, significância do
trabalho pro documento de estado geral do projeto). Um sétimo ponto,
de tipo mais simples ("prompt", sem acesso a ferramenta nenhuma por
natureza), checava idioma e emoji no fim da resposta.

Uma sessão concorrente relatou essa segunda inteligência artificial
rodando sem acesso a nenhuma ferramenta, negando ou falhando de forma
inconsistente — bloqueando trabalho legítimo ou passando batido, sem
previsibilidade.

A documentação oficial do Claude Code, lida diretamente (não resumida
por outra fonte), confirma dois problemas reais por trás desse
sintoma, não só um:

1. O formato de resposta que todos os sete pontos pediam (um objeto
   com `permissionDecision` ou `decision` dentro de um campo de saída
   específico) é o formato de um gancho comum, não o formato que um
   gancho do tipo "agent" ou "prompt" realmente usa — que é só
   `{"ok": true}` pra liberar, ou `{"ok": false, "reason": "..."}` pra
   bloquear. Mesmo quando a segunda inteligência artificial raciocinava
   certo, a resposta dela nunca estava no formato que o Claude Code
   sabe interpretar pra esse tipo de gancho.
2. A mesma documentação confirma que, se a sessão principal está no
   modo automático (uma configuração do próprio Claude Code que decide
   sozinha, sem perguntar, se cada ação pode rodar), a segunda
   inteligência artificial herda esse modo, e a mesma decisão
   automática passa a valer pra ela — explicação plausível pro "sem
   acesso a ferramenta nenhuma" relatado pela sessão concorrente.

O mesmo efeito foi reproduzido de forma independente mais de uma vez
dentro desta própria sessão: mesmo depois de corrigido o formato de
resposta, os pontos do fim da resposta continuaram sem conseguir ler
nada, enquanto a sessão principal seguiu com o modo automático ligado
— confirmando que o problema tem duas causas separadas, e corrigir só
uma (o formato) não bastava sozinha nesse ambiente.

## Decisão

- Dois ganchos do tipo "agent" — revisão de commit e revisão de início
  do teste no preview — foram removidos por completo. O que cada um
  checava como fato objetivo (leitura obrigatória, ordem de escrita,
  achado ou decisão faltando, mensagem de commit narrativa,
  documentação escrita antes do teste) já está coberto por checagem
  mecânica pura, sem inteligência artificial nenhuma, testada e
  confirmada funcionando em qualquer configuração de permissão da
  sessão.
- Os quatro pontos restantes (revisão de edição de documento, as duas
  checagens do fim da resposta, e a checagem de idioma/emoji) tiveram
  só o formato de resposta corrigido — continuam existindo, com o
  mesmo papel de antes. A revisão de edição de documento roda como
  segunda camada, depois da checagem mecânica que já cobre boa parte
  do mesmo julgamento (tom pessoal, escolha sem decisão registrada) —
  seu papel passa a ser cobrir o que a checagem mecânica, por usar uma
  lista fixa de palavras ou um único documento de exemplo, deixa
  passar.
- Mecanismo de confirmação generalizado: em vez de um par arquivo mais
  função fixo por ponto de checagem mecânica, as funções compartilhadas
  ganharam uma pasta própria de confirmações e uma função genérica que
  qualquer ponto novo reaproveita, e o gancho que lê a mensagem do
  usuário passou a usar uma tabela (frase esperada → nome do arquivo)
  em vez de um bloco de código repetido por frase.
- Um arquivo novo, próprio pro teste no preview, substitui o gancho
  "agent" removido daquele ponto, reaproveitando a mesma ficha (resumo
  compacto do estado da sessão) que o resto do sistema já mantém.

## Consequências

- Achados registrados no arquivo de achados do módulo; comportamento
  novo confirmado por teste isolado, incluindo dois defeitos reais
  encontrados só ao testar o código novo: checar só arquivo já
  registrado no controle de versão não via um arquivo de código nunca
  registrado antes; e a checagem de "documentação antes do teste"
  disparava contra a própria edição do documento de conceito de um
  módulo.
- Mesmo corrigido o formato, os quatro pontos que continuam usando uma
  segunda inteligência artificial dependem de a sessão principal não
  estar no modo automático pra ter acesso real a ferramenta — limite
  registrado no documento de conceito deste módulo, seção de limites
  reconhecidos.
- A frequência com que as checagens do fim da resposta rodam (hoje, em
  toda resposta) fica como pendência própria, fora desta rodada.
