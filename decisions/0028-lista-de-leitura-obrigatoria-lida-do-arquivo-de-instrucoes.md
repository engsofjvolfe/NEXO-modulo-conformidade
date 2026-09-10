# ADR 0028 — Lista de leitura obrigatória lida do arquivo de instruções, não escrita no código

*Em resumo:* a lista de documentos que precisam de leitura manual
completa antes de qualquer trabalho estava escrita direto dentro do
código deste módulo, em dois lugares -- com o nome exato de cada
arquivo de um projeto específico. Um módulo pensado pra servir
qualquer projeto hospedeiro não pode carregar esse tipo de dado dentro
de si. Agora o módulo lê essa lista de dentro do próprio arquivo de
instruções do projeto hospedeiro (o arquivo padrão que o Claude Code já
reconhece em qualquer projeto), marcado por duas linhas fixas -- sem
marcação, a lista vem vazia e o mecanismo não exige nada.

## Status

Aceito.

## Contexto

Duas listas de nome de arquivo, escritas à mão dentro do código deste
módulo (`lib/common.sh`, `session_start_import_check.sh`), continham
dado específico de um projeto hospedeiro -- quebra direta do
agnosticismo que este módulo precisa ter pra servir qualquer outro
projeto sem precisar editar o próprio código dele.

Levantada a dúvida sobre se as duas listas (documentos que exigem
leitura manual de verdade, e documentos que o Claude Code importa
sozinho no início da sessão) precisavam de tratamento diferente. A
única forma mecânica cogitada pra confirmar que uma importação
automática realmente carregou conteúdo na conversa (procurar um trecho
do arquivo dentro da transcrição bruta da sessão) foi descartada por
não ser confiável -- pode dar falso positivo (o trecho aparece em outro
lugar da conversa, por coincidência) ou falso negativo (formatação
diferente do texto original). A simplificação real: toda a lista passa
a exigir a mesma prova, sempre -- uma chamada de verdade da ferramenta
Read, registrada. O mecanismo de importação automática do Claude Code
continua existindo e funcionando como sempre funcionou, mas nenhuma
trava deste módulo depende dele.

Durante a implementação, dois problemas novos apareceram:

- Rastrear cada documento só pelo nome do arquivo (sem a pasta) tem
  risco real de colisão: nada impede um projeto hospedeiro de ter mais
  de um arquivo com o mesmo nome, em pastas diferentes -- ler um deles
  contaria, por engano, como se todos tivessem sido lidos.
- Resolver o caminho relativo de cada item (o link aponta pra um
  arquivo relativo à pasta do próprio arquivo de instruções, não à
  raiz do projeto) usando `cd`/`pwd` produz, neste ambiente, um estilo
  de caminho diferente do resto do sistema (barra normal com letra de
  unidade virando pasta, ex. "/h/..." em vez de "H:/...") -- o mesmo
  lugar em disco, escrito de dois jeitos, nunca bate numa comparação de
  texto simples contra o caminho que a ferramenta Read realmente usa.

Alternativas reais consideradas:

- **Manter a lista escrita no código, uma por módulo/projeto que vier
  a usar este sistema** -- descartada: é o próprio problema que motivou
  esta ADR, obrigaria editar o módulo pra cada projeto novo.
- **Confirmar importação automática por trecho de texto na
  transcrição** -- descartada, sem confiabilidade suficiente pra virar
  trava (ver Contexto).
- **Toda leitura obrigatória exige a mesma prova (Read de verdade),
  lista lida de um trecho marcado no arquivo de instruções do projeto
  hospedeiro** -- escolhida: fecha a lacuna de verificação sem depender
  de heurística, e resolve o agnosticismo ao mesmo tempo.
- **Rastrear leitura só pelo nome do arquivo** -- descartada durante a
  implementação, depois do risco de colisão ficar claro; substituída
  por caminho completo como chave.
- **Resolver caminho relativo via `cd`/`pwd`** -- descartada, pelo
  motivo de estilo de caminho acima; substituída por resolução só de
  texto (`resolve_path_string`), sem invocar `cd`.

## Decisão

`lib/common.sh` ganha `CONFORMIDADE_LEITURA_MARCADOR_INICIO`/`_FIM`
(duas linhas fixas de comentário HTML que o projeto hospedeiro usa pra
marcar o trecho relevante do próprio arquivo de instruções),
`mandatory_reading_claude_md_path()` (acha o arquivo de instruções, na
raiz ou dentro de `.claude/`), `mandatory_reading_section()` (texto
entre as marcações), `resolve_path_string()` (resolve caminho relativo
só com manipulação de texto, sem `cd`/`pwd`/`realpath`) e
`mandatory_reading_doc_paths()` (caminho completo de cada item, usado
como chave única de frescor por toda checagem). `MANUAL_MANDATORY_DOCS`
e a lista fixa em `session_start_import_check.sh` removidas.

Dentro do trecho marcado, cada item é sempre um link markdown -- um
formato só, mesmo pros itens que também são importados automaticamente
(mesma exigência de prova pra todos, ver Contexto).

## Consequências

- `bash -n lib/common.sh`, `bash -n pre_mandatory_reading_guard.sh` e
  `bash -n session_start_import_check.sh` sem erro depois da mudança.
- Projeto hospedeiro sem essas duas marcações no arquivo de instruções:
  mecanismo não exige nada -- recurso opcional, nunca obrigatório.
- Teste ao vivo, numa sessão nova, ainda pendente (mesma limitação já
  registrada em outras pendências de confirmação deste módulo) -- ver
  `tasks.md`.
