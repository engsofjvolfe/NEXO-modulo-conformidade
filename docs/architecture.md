# Architecture — Conformidade

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Architecture |
| Versão | 0.9.0 |
| Data | 10-09-2026 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

> Descreve como o módulo é construído por dentro — layout de arquivos,
> pacote, fronteiras, fluxo de dados técnico. É o "como" que corresponde
> ao "o quê" do `concept.md`; lido logo em seguida, quando existir.
>
> Implementação de código deriva sempre daqui e do contrato em
> `schemas/` — nunca o contrário. Este módulo não tem `schemas/`: a
> fronteira de dado real que ele consome (o JSON que o Claude Code
> entrega a cada gancho -- `tool_name`, `tool_input`, `cwd`, etc.) é
> definida pela documentação oficial do Claude Code, não por este
> projeto -- não há contrato pra gerar aqui.
>
> Cada seção segue [a regra de escrita geral](../CONVENCOES.md#como-escrever):
> resumo simples primeiro, detalhe técnico depois.

## Índice
- [Layout](#layout)
- [Controle de versão](#controle-de-versão)

## Layout

*Em resumo:* cada gancho é o próprio documento de si mesmo -- o
comentário no topo de cada arquivo explica o que ele faz e qual regra
do `CLAUDE.md` aplica. Nenhum índice à parte, dentro deste módulo,
repete essa relação -- um projeto hospedeiro pode manter o próprio
checklist, do lado de fora (ver
[`COMO-USAR.md`, Prática recomendada](<../COMO-USAR.md#prática-recomendada-fora-do-que-o-módulo-checa-sozinho>)).

*Em detalhe técnico:*

- `.claude/settings.json` -- liga cada gancho a um evento do Claude
  Code (`UserPromptSubmit`, `SessionStart`, `PreToolUse`,
  `PostToolUse`, `WorktreeRemove`, `Stop`). Diferente de
  `.claude/hooks/` e `.claude/agents/` (atalho de pasta de verdade,
  mesmo conteúdo físico dos dois lados -- ver
  [decisions/0025](<../decisions/0025-atalho-de-pasta-liga-hooks-e-agents-da-raiz-ao-clone.md>)),
  este arquivo (junto de `.claude/skills/revisar-pr`,
  `.github/pull_request_template.md`, `.vale.ini`/`.vale/styles` e
  `scripts/`) é cópia física separada entre este projeto e o projeto
  hospedeiro, sincronizada automaticamente por
  `session_start_sync_modulo.sh` a cada início de sessão, nunca à mão
  -- ver
  [decisions/0034](<../decisions/0034-copia-de-settings-json-sincronizada-no-inicio-de-cada-sessao.md>).
  `pre_mandatory_reading_guard.sh` libera a leitura do `CLAUDE.md` e da
  transcrição da sessão sempre, mesmo com leitura obrigatória pendente
  -- ver
  [decisions/0035](<../decisions/0035-leitura-obrigatoria-libera-claude-md-e-transcricao-sempre.md>).
  A localização onde este projeto foi copiado, dentro do projeto
  hospedeiro, é livre (nenhum caminho fixo exigido) -- gravada por
  `scripts/instalar.sh` em `.claude/conformidade-caminho`, arquivo que
  `session_start_sync_modulo.sh` lê pra saber de onde sincronizar -- ver
  [decisions/0036](<../decisions/0036-localizacao-de-instalacao-livre-marcador-substitui-caminho-fixo.md>).
- `.claude/hooks/*.sh` -- um script por responsabilidade:
  `user_prompt_submit.sh` (`AUTORIZO-TRAVA`), `session_start_reset.sh`
  (arquiva os diários da sessão anterior e reinicia a ficha/síntese,
  sempre no início de toda sessão), `session_start_sync_modulo.sh`
  (copia `.claude/settings.json` e o restante do que não pode ser
  atalho de pasta -- ver acima -- deste módulo por cima do projeto
  hospedeiro quando os dois divergem),
  `session_start_import_check.sh`
  (confere se os dezesseis documentos de importação automática do
  `CLAUDE.md` existem de verdade), `pre_mandatory_reading_guard.sh`,
  `pre_edit_safety.sh`, `pre_commit_hygiene.sh`, `pre_git_rules.sh`,
  `pre_preview_check.sh` (documentação antes do teste no preview,
  substitui gancho `agent` removido -- ver
  [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>)),
  `pre_search_guard.sh` (guarda de busca ampla genérica, por formato de
  chamada -- qualquer ferramenta com `tool_input.command` -- não por
  nome de ferramenta), `pre_pr_description_check.sh` (confere se o
  corpo do PR segue o modelo oficial -- ver
  [decisions/0022](<../decisions/0022-checagem-do-corpo-do-pr-contra-o-modelo-oficial.md>)),
  `post_edit_track.sh`, `post_read_track.sh`,
  `post_preview_track.sh`, `post_merge_reminder.sh`,
  `stop_fact_check.sh`, `worktree_remove_cleanup.sh`, `statusline.sh`,
  `pre_pr_review_check.sh` (confere se a revisão de PR está em dia --
  ver [decisions/0031](<../decisions/0031-revisao-de-pr-fica-desatualizada-e-fato-mecanico.md>)),
  `worktree_create_setup.sh` (liga pastas locais numa worktree nova,
  no próprio evento de criação -- ver
  [decisions/0032](<../decisions/0032-worktree-nova-liga-pastas-locais-por-atalho.md>)).
- `.claude/hooks/lib/common.sh` -- funções compartilhadas (leitura do
  JSON de entrada, `AUTORIZO-TRAVA`, normalização de caminho, detecção
  de emoji e de esquema impuro, e a ficha/síntese: um resumo compacto
  do estado atual da sessão -- "isto já foi lido/editado, há quantas
  ações" -- mantido incrementalmente, pra checagens não precisarem
  reler o diário completo a cada chamada; o diário completo continua
  existindo do lado, como prova bruta).
- `scripts/hooks/` -- hooks nativos do git (`commit-msg`, `pre-push`,
  `pre-rebase`, ao lado do `pre-commit` já existente antes deste
  sistema) -- rodam pra qualquer ferramenta, não só o Claude Code.
- `scripts/instalar.sh` -- instalação completa num projeto hospedeiro
  novo, um comando só: cria os atalhos de pasta possíveis
  (`.claude/hooks`, `.claude/agents`), copia o restante (ver
  `.claude/settings.json` acima), liga os vigias nativos do git -- ver
  [decisions/0034](<../decisions/0034-copia-de-settings-json-sincronizada-no-inicio-de-cada-sessao.md>).
  `scripts/instalar-hooks.sh` faz só a última parte (`core.hooksPath`),
  mantido à parte pra religar sozinho, sem repetir o resto, se algum
  dia só isso precisar rodar de novo.
- `scripts/instalar.sh` -- instalação completa num projeto hospedeiro
  novo, um comando só: cria os atalhos de pasta possíveis
  (`.claude/hooks`, `.claude/agents`), copia o restante (ver
  `.claude/settings.json` acima), liga os vigias nativos do git -- ver
  [decisions/0034](<../decisions/0034-copia-de-settings-json-sincronizada-no-inicio-de-cada-sessao.md>).
  `scripts/instalar-hooks.sh` faz só a última parte (`core.hooksPath`),
  mantido à parte pra religar sozinho, sem repetir o resto, se algum
  dia só isso precisar rodar de novo.
- `.github/pull_request_template.md`, `.vale.ini`/`.vale/` -- camadas
  auxiliares (estrutura de PR, estilo de prosa opcional).
- `modulos/conformidade/decisions/` — uma ADR por escolha real entre
  alternativas feita neste módulo (matcher de gancho, forma de
  comparar caminho, heurística de detecção, onde uma checagem nova
  entra). Pendência de formalizar, aqui, decisões estruturais já
  tomadas antes deste módulo existir como módulo — ver
  [`tasks.md`](tasks.md).
- `.claude/agents/` -- um assistente por assunto que depende de
  julgamento, chamado manualmente (ver
  [decisions/0020](<../decisions/0020-revisao-de-pr-por-assistentes-chamados-manualmente.md>)):
  `revisor-referencias-cruzadas.md`, `revisor-testes.md`,
  `revisor-visao-de-conjunto.md`, `revisor-valores-fixos.md` -- o que
  cada um olha está descrito no próprio arquivo dele, fonte única.
  `fiscal-claude-md.md`, já existente antes desta rodada, cobre outro
  papel (retrato do meio de uma tarefa, não revisão de PR).
- `.claude/skills/revisar-pr/` -- comando que chama os quatro
  revisores acima de uma vez, em paralelo. Cada um também pode ser
  chamado sozinho, pelo nome, numa conversa normal.

## Controle de versão

| Versão | Data | Alteração | Origem da alteração |
|---|---|---|---|
| 0.1.0 | 27-08-2026 | Criação inicial -- aponta pro layout já descrito em `MANUAL.md`, acrescenta só a pasta `decisions/` própria do módulo. | Criação inicial do módulo |
| 0.2.0 | 28-08-2026 | Layout reescrito direto (sem apontar pras seções antigas de MANUAL.md, que virou um índice por faixa de linha do CLAUDE.md, não mais numerado por seção) -- lista completa dos arquivos reais, incluindo session_start_import_check.sh, novo nesta rodada. | Segunda rodada de correção do sistema de conformidade |
| 0.4.0 | 28-08-2026 | Acrescentado `pre_preview_check.sh` à lista de arquivos. | Resolução de [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>) |
| 0.5.0 | 29-08-2026 | Acrescentados os quatro revisores de PR (`.claude/agents/`) e o comando que os chama juntos (`.claude/skills/revisar-pr/`). | Resolução de [decisions/0020](<../decisions/0020-revisao-de-pr-por-assistentes-chamados-manualmente.md>) |
| 0.6.0 | 04-09-2026 | Acrescentado `pre_pr_description_check.sh`; nota sobre dois ganchos existentes (`pre_pr_review_check.sh`, `worktree_create_setup.sh`) ainda fora desta lista. | Resolução de [decisions/0022](<../decisions/0022-checagem-do-corpo-do-pr-contra-o-modelo-oficial.md>) |
| 0.7.0 | 09-09-2026 | Acrescentados `pre_pr_review_check.sh` e `worktree_create_setup.sh` à lista, cada um com ADR retroativa própria. | Resolução de [decisions/0031](<../decisions/0031-revisao-de-pr-fica-desatualizada-e-fato-mecanico.md>) e [decisions/0032](<../decisions/0032-worktree-nova-liga-pastas-locais-por-atalho.md>) |
| 0.8.0 | 10-09-2026 | Acrescentados `session_start_sync_modulo.sh` e `scripts/instalar.sh` à lista; nota sobre `.claude/settings.json`, `.claude/skills/revisar-pr`, `.github/pull_request_template.md`, `.vale.ini`/`.vale/styles` e `scripts/` serem cópia física separada (não atalho de pasta) sincronizada automaticamente; nota sobre a isenção de leitura obrigatória pro `CLAUDE.md`/transcrição em `pre_mandatory_reading_guard.sh`. | Resolução de [decisions/0034](<../decisions/0034-copia-de-settings-json-sincronizada-no-inicio-de-cada-sessao.md>) e [decisions/0035](<../decisions/0035-leitura-obrigatoria-libera-claude-md-e-transcricao-sempre.md>) |
| 0.9.0 | 10-09-2026 | Nota sobre a localização de instalação ser livre, sem caminho fixo, gravada em `.claude/conformidade-caminho`. | Resolução de [decisions/0036](<../decisions/0036-localizacao-de-instalacao-livre-marcador-substitui-caminho-fixo.md>) |
| 0.7.0 | 09-09-2026 | Acrescentados `pre_pr_review_check.sh` e `worktree_create_setup.sh` à lista, cada um com ADR retroativa própria. | Resolução de [decisions/0031](<../decisions/0031-revisao-de-pr-fica-desatualizada-e-fato-mecanico.md>) e [decisions/0032](<../decisions/0032-worktree-nova-liga-pastas-locais-por-atalho.md>) |
| 0.8.0 | 10-09-2026 | Acrescentados `session_start_sync_modulo.sh` e `scripts/instalar.sh` à lista; nota sobre `.claude/settings.json`, `.claude/skills/revisar-pr`, `.github/pull_request_template.md`, `.vale.ini`/`.vale/styles` e `scripts/` serem cópia física separada (não atalho de pasta) sincronizada automaticamente; nota sobre a isenção de leitura obrigatória pro `CLAUDE.md`/transcrição em `pre_mandatory_reading_guard.sh`. | Resolução de [decisions/0034](<../decisions/0034-copia-de-settings-json-sincronizada-no-inicio-de-cada-sessao.md>) e [decisions/0035](<../decisions/0035-leitura-obrigatoria-libera-claude-md-e-transcricao-sempre.md>) |
| 0.9.0 | 10-09-2026 | Nota sobre a localização de instalação ser livre, sem caminho fixo, gravada em `.claude/conformidade-caminho`. | Resolução de [decisions/0036](<../decisions/0036-localizacao-de-instalacao-livre-marcador-substitui-caminho-fixo.md>) |
