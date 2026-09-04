# Manual — checklist do CLAUDE.md contra os ganchos reais

Cada linha abaixo é uma faixa de linha real de `.claude/CLAUDE.md`
(não reorganizada por tema), na ordem em que o texto aparece. Checkbox
marcado significa: existe gancho real (`.claude/hooks/*.sh` +
`.claude/settings.json`, ou `scripts/hooks/*` pro git nativo) que
aplica aquele trecho, confirmado contra o código, não contra a
lembrança dele.

Guia de uso das frases que destravam um bloqueio (`AUTORIZO-TRAVA` e
as frases de confirmação pontual) é outro documento, com outro papel:
[FRASES-DE-CONFIRMACAO.md](FRASES-DE-CONFIRMACAO.md).

Princípio seguido nesta rodada: o momento certo de uma checagem é o
mais cedo possível -- no instante da própria edição (`pre_edit_safety.sh`,
evento `PreToolUse` em `Write`/`Edit`), nunca só no commit
(`pre_commit_hygiene.sh`), que é tarde demais (a sessão inteira já
pode ter ido pro caminho errado antes de alguém descobrir). O revisor
de commit continua existindo como segunda camada (reforço, não
substituto) só pra visão de conjunto do que o commit inteiro representa.

Toda checagem de julgamento (tipo `agent`/`prompt`, decidida por IA)
que bloqueia devolve dois campos diferentes: `permissionDecisionReason`
(explicação detalhada, mostrada só pra mim, o Claude) e `systemMessage`
(frase curta, mostrada direto pra você, na interface -- confirmado por
pesquisa direta na documentação oficial). Gancho tipo `command` (script
comum) já mostra a mensagem de bloqueio pra você por padrão, via
`stderr` -- não precisou de campo extra.

Dois reforços de infraestrutura, cruzando várias linhas abaixo, não
amarrados a uma única faixa do CLAUDE.md: (1) todo gancho que usa o
campo `if` do `settings.json` sobre o matcher `Bash` (`pre_commit_hygiene.sh`,
`pre_git_rules.sh`, os dois ganchos `agent`) agora confirma o próprio
padrão de novo, dentro do script/prompt -- a documentação oficial
confirma que `if` "falha aberto" (roda o gancho mesmo sem bater o
padrão) quando o comando não é parseável, achado ao vivo nesta rodada
(`modulos/conformidade/decisions/0011`); (2) as checagens de
`pre_edit_safety.sh` que precisam saber "isso já foi lido/editado
nesta sessão" consultam uma ficha compacta (estado atual, por ação),
não o diário inteiro a cada vez -- diário continua existindo do lado,
intacto; ficha reinicia a cada sessão nova
(`modulos/conformidade/decisions/0012`).

## Linhas 1-9

- [x] 1-4: título, frase de abertura -- não é regra.
- [x] 5-9: todo documento lido na íntegra, sem resumo, sem corte.
      `post_read_track.sh` separa completa de parcial;
      `pre_edit_safety.sh`/`pre_commit_hygiene.sh` exigem completa.

## Linhas 11-14

- [x] Não concluir a partir do que já chegou carregado -- confirmar
      antes de escrever a correção, não depois. Movido do revisor de
      commit (rodava tarde, só no fim) pro momento exato da escrita:
      `pre_edit_safety.sh` #4, roda em todo `Write`/`Edit`, bloqueio
      mecânico (sem IA) -- se o texto novo cita outro documento `.md`,
      exige leitura completa dele entre as vinte leituras mais
      recentes da sessão (não vale leitura antiga, possivelmente
      esquecida ou desatualizada na memória).
      Limite honesto, confirmado por pesquisa direta na documentação
      oficial do Claude Code: não existe mecanismo pra forçar uma
      ferramenta (`Read`) rodar automaticamente antes de outra
      (`Edit`/`Write`) -- o máximo real é bloquear até existir o
      registro da leitura, forçando a correção manual. A citação por
      nome de arquivo é uma aproximação (heurística) do que a regra
      pede de verdade (entendimento genuíno, não só o nome citado) --
      autorizável, mesmo limite epistêmico já reconhecido.

## Linhas 16-23

- [x] Seis documentos de leitura manual obrigatória, antes de qualquer
      outra coisa. `pre_mandatory_reading_guard.sh` (matcher `*`),
      `Read` restrito aos seis enquanto faltar algum
      (`modulos/conformidade/decisions/0006`).

## Linhas 25-41

- [x] Dezesseis importações `@caminho` -- carregam via mecanismo do
      Claude Code, não um gancho deste projeto; falham em silêncio se
      o caminho estiver errado (mesmo bug já confirmado nos seis
      documentos de nome com espaço). `session_start_import_check.sh`
      (evento `SessionStart`, sem matcher -- roda toda sessão),
      confere que os dezesseis caminhos existem de verdade.
- [x] 42: definição de "você"/"eu" -- não é regra.

## Linhas 44-48

- [x] "Todo módulo segue esta ordem, sem exceção... nenhuma entrega
      fecha (commit) sem ter passado por ele" -- moldura geral, coberta
      pela soma de cada nó abaixo.

## Linhas 50-81 (diagrama mermaid, nó por nó)

- [x] 52 (`B`): leitura obrigatória completa antes do resto -- mesmo
      gancho das linhas 16-23.
- [x] 53 (`F`): `concept.md` escrever/atualizar requisito -- revisor de
      commit, fato ("concept.md atualizado quando ha requisito novo").
- [x] 55 (`D`): `analysis.md` -- registrar como foi checado se código
      bate com requisito, quando módulo já tem código. Revisor de
      commit, fato ("analysis.md/findings.md se o modulo ja tinha
      codigo").
- [x] 56 (`E`): `findings.md` -- registrar divergências encontradas.
      Mesmo fato da linha 55.
- [x] 59 (`G`): `architecture.md` -- como construir. Revisor de commit,
      fato ("architecture.md atualizado se ha codigo novo").
- [x] 60 (`H`): `schemas/` gerado do bloco YAML do `concept.md`.
      Revisor de commit, fato ("schemas/ gerado do concept.md quando
      aplicavel").
- [x] 61 (`I`): implementação deriva de `architecture.md` + `schemas/`,
      nunca o contrário. `pre_edit_safety.sh` #5, no momento da própria
      edição (schema-antes-de-código, arquitetura-antes-de-código,
      arquitetura-antes-de-schema) -- `pre_commit_hygiene.sh` #5
      continua como segunda camada, no commit.
- [x] 63-66 (quatro setas pontilhadas `-. "escolha real..." .-> ADR`):
      `decisions/` nasce quando há escolha real entre alternativas, a
      partir de `concept.md`, `architecture.md`, `schemas/` ou
      implementação. Gancho `agent` novo em `.claude/settings.json`
      (`PreToolUse`, `Write`/`Edit`), roda no momento da própria edição
      de `concept.md`/`architecture.md`/`schemas/*.json` -- pergunta de
      julgamento no commit (revisor de commit) continua como segunda
      camada.
- [x] 68 (`J`): `pitfalls.md` -- armadilha de ferramenta encontrada na
      implementação. Revisor de commit, fato ("pitfalls.md se a
      implementacao revelou armadilha de ferramenta/ambiente").
- [x] 69 (`K`): `findings.md` -- achado novo revelado pela
      implementação. Gatilho **distinto** do da linha 56 (esse é sobre
      "módulo já tinha código"; este é sobre "implementação revelou
      algo", mesmo em código totalmente novo) -- fato próprio
      acrescentado nesta rodada no revisor de commit.
- [x] 71-73 (`ADR`/`J`/`K` → `L`): `tasks.md` atualizar pendências.
      Revisor de commit, fato ("tasks.md refletindo o estado atual").
- [x] 75 (`L`→`M`): `handoff.md` sempre a última coisa atualizada.
      `pre_edit_safety.sh` #6, no momento da própria edição --
      `pre_commit_hygiene.sh` #8 continua como segunda camada.
- [x] 76 (`M`→`P`): documentos gerais da raiz -- ver linhas 119-137
      abaixo, mesmo conteúdo detalhado ali.
- [x] 77-78 (`N`): "checagem mecânica passa?" -- não é regra nova, é o
      próprio conjunto de checagens deste documento.
- [~] 79-80 (`T`→`Z`): testar no preview isolado, entrega fechada.
      Limite reconhecido -- ver linhas 160-172.

## Linhas 83-86

- [x] Ponteiro pra seção "Testar uma tarefa antes do PR" -- não é regra
      nova, remete às linhas 160-172.

## Linhas 88-101 (lista "Pontos que o diagrama não consegue expressar")

- [x] 89-94: `concept.md` sempre primeiro, nunca reescrito pra bater
      com código -- mesmo fato da linha 53.
- [x] 95-101: `decisions/` nasce em qualquer ponto, gatilho no momento
      de marcar pendência resolvida em `tasks.md` -- mesma pergunta de
      julgamento das linhas 63-66.

## Linhas 102-110

- [x] 102-106 (primeira metade): "checagem mecânica tem ferramenta
      própria" -- descreve o próprio sistema de ganchos, não uma regra
      nova pra aplicar.
- [x] 106-110 (segunda metade): "o que não é fato mecânico continua
      checagem manual: reler cada arquivo tocado, por completo, contra
      a própria descrição no topo dele, antes de fechar a entrega" --
      não tinha gancho nenhum (só existia sob pedido, via
      `fiscal-claude-md`). Pergunta nova acrescentada nesta rodada no
      revisor do fim da resposta (evento `Stop`).

## Linhas 111-118

- [x] 111-112: `handoff.md` última coisa tocada, nunca a primeira --
      mesmo gancho da linha 75.
- [x] 113-118: tom impessoal, exceção `analysis.md`. Mesmo gancho
      `agent` das linhas 63-66 -- roda no momento da edição de
      qualquer `.md` (exceto `analysis.md`); revisor de commit
      continua como segunda camada.

## Linhas 119-137

- [x] 129-130: módulo novo → linha em `modulos/README.md`.
      `pre_edit_safety.sh` #7, no momento da própria edição --
      `pre_commit_hygiene.sh` #10 continua como segunda camada.
- [x] 131-133: `tasks.md` de módulo muda de vazio pra não-vazio (ou o
      contrário) → `TASKS.md` (raiz) acompanha. `pre_edit_safety.sh`
      #8, no momento da própria edição -- `pre_commit_hygiene.sh` #11
      continua como segunda camada.
- [x] 134-137: trabalho de hoje significativo pro `HANDOFF.md` (raiz)?
      Julgamento -- revisor do fim da resposta já pergunta.

## Linhas 139-143 (Commits)

- [x] 141: nunca `Co-Authored-By`. `pre_commit_hygiene.sh` +
      `commit-msg`.
- [x] 142: sempre português. Fato no revisor de commit.
- [x] 143: bullet points, nunca narrativa; título curto, imperativo,
      sem prefixo tipo `docs:`/`fix:` nem caminho de arquivo antes de
      dois-pontos. `commit-msg` -- as duas proibições do título
      checadas separadamente (a segunda, acrescentada nesta rodada,
      testada contra 50 commits reais sem falso positivo); corpo em
      bullet points checado à parte, mesmo arquivo.

## Linhas 145-149 (Histórico do git)

- [x] 147: reescrever é seguro (dono único) -- não é regra de bloqueio,
      é permissão; nada a travar.
- [x] 148: investigar antes de reescrever (`git log`/`reflog`/
      `ls-remote`/`fetch`). `pre_git_rules.sh` #4.
- [x] 149: `develop`/`main` nunca reescritas, sem exceção, mesmo já
      publicadas. `pre_git_rules.sh` #1 (incondicional, sem
      `AUTORIZO-TRAVA`) + `scripts/hooks/pre-rebase` + `pre-push`.

## Linhas 151-158 (Trabalho em múltiplas frentes)

- [x] 153: `develop` recebe tudo; `main` só por decisão explícita,
      nunca automático. Nenhum comando deste projeto promove pra
      `main` sozinho hoje -- nada a travar além do que as linhas
      abaixo já cobrem (merge sempre pede confirmação humana).
- [x] 154 (primeira metade): branch própria antes de começar tarefa
      nova, nunca direto em `develop`. `pre_git_rules.sh` #1b.
- [x] 154 (segunda metade): nunca commit/merge direto sem PR.
      `permissions.ask` (`Bash(git merge *)`) + `pre_git_rules.sh` #6
      (PR existente antes do merge em `develop`, acrescentado nesta
      rodada).
- [x] 155: nome de branch sozinho não protege -- justificativa, não
      regra de ação; a regra de ação é a linha 156.
- [x] 156: worktree própria obrigatória, nunca checkout na pasta
      principal. `pre_edit_safety.sh` #2, `pre_git_rules.sh` #5.
- [x] 157: remover worktree depois de mesclada, `git worktree list`
      sem sobra. `stop_fact_check.sh` (bloqueio real, `exit 2`; bug de
      falso positivo pra pasta principal corrigido nesta rodada).
- [x] 158: motivo da regra -- justificativa, não regra de ação nova.

## Linhas 160-172 (Testar uma tarefa antes do PR)

- [~] Limite reconhecido, não lacuna de gancho: a linha 166 ("Instruções
      aqui:") está em branco no próprio `CLAUDE.md` -- sem sinal de
      sucesso definido, não existe evidência pra nenhum gancho
      capturar. `post_preview_track.sh` registra subida/descida do
      ambiente (sinal fraco); revisor de commit pergunta explicitamente
      se foi testado de novo após mudança de código.

## Linhas 175-186 (Fluxo completo de uma tarefa, moldura)

- [x] Formato de portão -- moldura geral, coberta pela soma dos
      portões de cada passo abaixo.

## Linhas 188-200 (Passo 1)

- [x] 197-200 (portão): worktree existe de verdade, diretório atual,
      leitura obrigatória já feita antes de qualquer código.
      `pre_edit_safety.sh` #2 (worktree) e #3 (leitura obrigatória).

## Linhas 202-212 (Passo 2)

- [x] 208-212 (portão): fluxo de escrita e revisão completo, incluindo
      documentos gerais da raiz -- soma de todas as checagens das
      linhas 44-137 acima.

## Linhas 214-226 (Passo 3)

- [~] 226 (portão): teste real, ao vivo, confirmado, nunca presumido.
      Mesmo limite reconhecido das linhas 160-172.

## Linhas 228-242 (Passo 4)

- [x] 237: formato do commit -- mesmo gancho das linhas 139-143.
- [x] 241-242 (portão): `git status` limpo antes de dizer "pronto".
      `stop_fact_check.sh`.

## Linhas 244-259 (Passo 5)

- [x] 253: PR nunca pra `main`, sempre pra `develop`. `pre_git_rules.sh`
      #3 (bloqueia `--base main`) + `stop_fact_check.sh` (base do PR já
      aberto, fato objetivo via `gh pr view`).
- [x] 254: descrição clara do PR. `.github/pull_request_template.md`
      (estrutura obrigatória) + revisor do fim da resposta pergunta se
      está vaga.
- [x] 258-259 (portão): PR realmente aberto, não só "pronto pra abrir".
      Revisor do fim da resposta (`gh pr view`).

## Linhas 261-271 (Passo 6)

- [x] 270-271 (portão): aprovação explícita, em texto, nunca merge por
      iniciativa própria. `permissions.ask` (`Bash(git merge *)`).

## Linhas 273-287 (Passo 7)

- [x] 279: `--no-ff` no merge em `develop`. `pre_git_rules.sh` #2.
- [x] 285-287 (portão): checar se precisa ir pra produção agora, nunca
      presumir. Julgamento -- revisor do fim da resposta já pergunta.

## Linhas 289-309 (Passo 8)

- [x] 291-301: `gradlew --stop` antes de remover worktree com projeto
      Gradle. `pre_git_rules.sh` (caminho manual, `git worktree
      remove` digitado) + `worktree_remove_cleanup.sh` (evento nativo
      `WorktreeRemove`, reforço).
- [x] 305-309 (portão de fechamento): `git worktree list` sem sobra.
      Mesmo gancho da linha 157 (`stop_fact_check.sh`).

## Linhas 313-320 (Depois de mesclar: e a produção?)

- [x] 317-320: `git pull origin develop` sempre, depois de merge/push.
      `post_merge_reminder.sh` -- lembrete no turno seguinte (a ação já
      aconteceu, não dá pra bloquear retroativamente).

## Linhas 323-326 (Ferramentas)

- [x] 325: nunca `Agent`/`Grep`/`Glob`/`Explore` por iniciativa própria.
      `permissions.ask` (`Agent`, `Grep`, `Glob` -- `Explore` roda via
      `Agent`) + `pre_search_guard.sh` pro equivalente via qualquer
      ferramenta de comando livre (`Bash`, `PowerShell`, e qualquer
      outra futura) -- gancho único, `"matcher": "*"`, reconhece pela
      presença de `tool_input.command`, não por nome de ferramenta
      (`modulos/conformidade/decisions/0010`; valor `ask` corrigido
      nesta rodada, era `escalate`, que não existe).
- [x] 326: nunca `AskUserQuestion`. Bloqueio direto, incondicional,
      matcher dedicado em `.claude/settings.json`.

## Linhas 328-334 (Regras gerais)

- [x] 330: nunca emoji (código, docs, commits, chat). `pre_edit_safety.sh`
      #9, no momento da própria edição -- `pre_commit_hygiene.sh` (arquivo
      alterado + mensagem do commit) continua como segunda camada +
      revisor de tom (evento `Stop`, resposta de chat).
- [x] 331-332: não framear documento criado nesta sessão como "antes e
      depois". `pre_edit_safety.sh` #12, no momento da própria edição
      (checa se o arquivo tem histórico de commit de verdade, via
      `git log`) -- `pre_commit_hygiene.sh` #7 continua como segunda
      camada.
- [x] 333: linha de Licença em tabela de cabeçalho. `pre_edit_safety.sh`
      #11, no momento da própria edição -- `pre_commit_hygiene.sh` #6
      continua como segunda camada.
- [x] 334: esquema de dado é dado puro, em `schemas/*.json` ou
      embutido num documento. `pre_edit_safety.sh` #10, no momento da
      própria edição -- `pre_commit_hygiene.sh` #3 e #3b continuam como
      segunda camada.

## Linhas 336-338 (Versionamento)

- [x] 338: SemVer, sem `CHANGELOG.md` -- documentação dos módulos faz
      esse papel. `scripts/hooks/pre-commit` (já existia antes deste
      sistema, confere subida de versão).

## Linhas 340-343 (Respostas ao usuário)

- [x] 342: sempre português. Revisor de tom, evento `Stop`.
- [x] 343: termo técnico explicado em linguagem simples. Revisor de
      tom, evento `Stop`.

## Controle de versão

| Versão | Data | Alteração | Origem da alteração |
|---|---|---|---|
| 0.1.0 | 28-08-2026 | Criação -- checklist nascida da leitura linha a linha do CLAUDE.md (344 linhas) contra o código real dos ganchos, faixa de linha por faixa de linha, sem reorganizar por tema. | Correção do sistema de conformidade |
| 0.2.0 | 28-08-2026 | Seis checagens que só rodavam no commit movidas pro momento da própria edição (ordem completa, handoff.md por último, módulo novo, tasks.md vazio, ADR de escolha real, tom impessoal) -- revisor de commit mantido como segunda camada, não removido. Acrescentado systemMessage em toda checagem de julgamento que bloqueia, pra você ver uma frase curta na hora, não só eu. | Continuação da correção do sistema de conformidade |
| 0.3.0 | 28-08-2026 | Mais quatro checagens movidas pro momento da própria edição (nunca emoji, esquema é dado puro, linha de Licença, nunca "antes e depois" em documento nunca versionado) -- linhas 330-334 atualizadas. Nota nova sobre dois reforços de infraestrutura (auto-portão contra falha aberta do filtro `if`; ficha/síntese substituindo releitura do diário). Referência desatualizada, numa das checagens de julgamento, a uma "seção de achados do MANUAL.md" que não existe mais (MANUAL.md virou só checklist) corrigida pra apontar pro `findings.md`/`pitfalls.md` de cada módulo. | Correção da falha aberta do filtro `if`; checagens de emoji/esquema/licença/antes-depois movidas pro momento da edição |
| 0.4.0 | 29-08-2026 | Ponteiro novo, no topo, pro FRASES-DE-CONFIRMACAO.md -- documento separado, papel diferente deste checklist. | Criação do FRASES-DE-CONFIRMACAO.md |
