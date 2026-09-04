# Tasks — Conformidade

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Tasks |
| Versão | 0.13.0 |
| Data | 04-09-2026 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

> Lista mutável de pendências só deste módulo. Lida depois de
> `concept.md`/`architecture.md`, antes de mexer em qualquer coisa.
> Atualizada direto conforme resolve. Assim que uma pendência vira
> decisão de verdade, o item aqui vira só um ponteiro pra ADR em
> `decisions/` — nunca um resumo paralelo do que a decisão já diz.
> Pendência resolvida (com ou sem ADR) não é apagada — vira item
> riscado na seção `Resolvidas`.
>
> Cada item segue [a regra de escrita geral](../CONVENCOES.md#como-escrever):
> resumo simples primeiro, detalhe técnico depois.

## Índice
- [Em aberto](#em-aberto)
- [Resolvidas](#resolvidas)
- [Controle de versão](#controle-de-versão)

## Em aberto

- [ ] **Confirmar de ponta a ponta, numa sessão nova, que os cinco
      mecanismos corrigidos na segunda rodada de hoje bloqueiam de
      verdade.**

      *Resumo simples:* uma queixa direta -- "o sistema ainda deixa
      escolher se segue a trava ou não" -- revelou que boa parte do
      sistema nunca bloqueava de verdade: o formato de resposta que os
      ganchos revisados por IA usavam não é reconhecido pelo Claude
      Code como decisão de bloqueio, então eles só "avisavam". Cinco
      pontos corrigidos, mesma limitação da pendência acima (sessão
      que corrige não consegue confirmar o bloqueio ao vivo).

      *Detalhe técnico:* cinco pontos a confirmar: (1) o gancho `agent`
      de revisão de commit (`if: Bash(git commit *)`) bloqueia um
      commit de verdade quando encontra fato faltando, usando o formato
      `hookSpecificOutput.permissionDecision` (achado raiz, ver
      MANUAL.md 9.12); (2) o mesmo formato bloqueia o gancho de revisão
      de preview; (3) `pre_mandatory_reading_guard.sh` bloqueia `Read`
      de um arquivo fora da lista de seis, enquanto sobrar algum deles
      por ler (decisions/0006); (4) `stop_fact_check.sh` bloqueia a
      resposta de terminar (`exit 2`) quando encontra um dos três fatos
      mecânicos, e libera com `AUTORIZO-TRAVA` (decisions/0007); (5) os
      três ganchos de julgamento do evento `Stop` -- este quinto ponto
      é o de confiança mais baixa dos cinco: mesmo se `decision:
      "continue"` não bloquear (documentação marca como experimental,
      sem exemplo confirmado -- ver decisions/0008), os outros quatro
      continuam valendo.

      *Nota de acompanhamento, 28-08-2026:* pontos (1) e (2) não se
      aplicam mais -- os dois ganchos `agent` citados (revisão de
      commit, revisão de preview) foram removidos por completo, e o
      formato de resposta que os motivava foi corrigido em todo o
      resto do sistema. Ver
      [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>).
      Pontos (3), (4) e (5) continuam válidos e ainda sem confirmação.

- [ ] **Confirmar de ponta a ponta, numa sessão nova, que os quatro
      mecanismos criados hoje bloqueiam de verdade.**

      *Resumo simples:* tudo foi testado isolado (funções chamadas
      direto, fora do fluxo real de um gancho) — ver
      [findings.md](findings.md) — porque a mesma sessão que escreveu
      o código não consegue ver a correção valendo de verdade (ver
      [pitfalls.md](<pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)).
      Falta confirmar ao vivo, numa sessão que já carregue os arquivos
      corrigidos desde o início.

      *Detalhe técnico:* quatro pontos a confirmar: (1)
      `pre_mandatory_reading_guard.sh` bloqueia de verdade uma
      ferramenta como `Bash` antes da leitura obrigatória, e libera
      `Read`/`TodoWrite` (decisions/0001); (2) `stop_fact_check.sh` não
      lista mais a pasta principal como "worktree esquecida" por
      engano (decisions/0002); (3) um commit tocando um `.md` com
      esquema embutido contendo `description`/`example` é bloqueado de
      verdade (decisions/0003); (4) o gancho de `Stop` pergunta sobre
      instrução do usuário esquecida quando existir uma de verdade
      (decisions/0004).

- [ ] **Fazer a auditoria linha a linha do `CLAUDE.md`, com checklist
      visível, que ficou combinada pra depois.**

      *Resumo simples:* a varredura feita hoje comparou o `CLAUDE.md`
      contra a tabela de referência do `MANUAL.md` e achou quatro
      lacunas reais — mas não foi, ela mesma, uma releitura linha a
      linha com registro visível de cada regra conferida. Combinado
      explicitamente adiar essa auditoria mais rigorosa.

      *Detalhe técnico:* produzir um checklist -- cada linha do
      `CLAUDE.md` (ou cada regra identificável) contra o mecanismo que
      a cobre (ou a ausência de um), visível de verdade, não só a
      palavra do revisor. Sem desenho ainda.

- [ ] **Formalizar retroativamente, em `decisions/`, as escolhas
      estruturais já tomadas antes deste módulo existir como módulo.**

      *Resumo simples:* os quatro ADRs de hoje
      (decisions/0001 a 0004) cobrem só o trabalho desta sessão -- as
      decisões estruturais mais antigas (por que os hooks nativos do
      git moram em `scripts-hooks/`, não `.githooks/`; o desenho de
      `pre_bash_search_guard.sh`; a divisão de custo do evento `Stop`
      entre fato mecânico e pergunta de julgamento; entre outras) só
      existem narradas em `MANUAL.md`, seção 9 -- nunca como ADR
      própria deste módulo.

      *Detalhe técnico:* candidatas identificadas em `MANUAL.md`,
      seção 9: 9.4 (local dos hooks nativos do git), 9.5 (desenho do
      `pre_bash_search_guard.sh`), 9.6 (arquitetura de custo do
      `Stop`), 9.8 (onde a checagem de leitura obrigatória entra no
      fluxo). As demais entradas da seção 9 (9.1, 9.2, 9.3, 9.7, 9.9,
      9.10, 9.11) são conserto de bug ou erro factual, não escolha
      real entre alternativas -- não precisam de ADR.

- [x] **Investigar a causa raiz do "modo sem perguntar" que bloqueou o
      gancho de `Stop` durante parte desta sessão.**
      Resolvido -- ver
      [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>).

- [x] **Confirmar ao vivo, numa sessão nova, a ficha/síntese
      ([decisions/0012](<../decisions/0012-ficha-sintese-substitui-releitura-do-diario-a-cada-checagem.md>)).**
      Resolvido, embora não do jeito esperado -- ver
      [Resolvidas](#resolvidas).

- [x] **Confirmar ao vivo, numa sessão nova, o auto-portão contra
      falha aberta do filtro `if` nos dois ganchos `agent` (revisão de
      commit, revisão de preview).**
      Resolvido de outra forma -- os dois ganchos `agent` citados
      (revisão de commit, revisão de início do teste no preview) foram
      removidos por completo, substituídos por script comum
      (`pre_commit_hygiene.sh`, `pre_preview_check.sh`), cujo
      auto-portão já foi testado isoladamente de verdade, sem a
      limitação que motivou esta pendência. Ver
      [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>).

- [ ] **Confirmar ao vivo, com o modo automático da sessão desligado,
      que os quatro ganchos decididos por IA que ainda existem
      (revisão de edição de documento, duas checagens do fim da
      resposta, checagem de idioma/emoji) conseguem usar ferramenta de
      verdade.**

      *Resumo simples:* mesmo com o formato de resposta corrigido, os
      quatro continuaram sem conseguir ler nada enquanto o modo
      automático estava ligado -- confirmado ao vivo, mais de uma vez,
      nesta mesma sessão. O modo automático foi desligado no fim desta
      rodada, mas a confirmação de que isso resolve o problema de
      verdade ainda não aconteceu.

      *Detalhe técnico:* ver
      [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>)
      e o achado correspondente em
      [findings.md](<findings.md#2026-08-28-modo-automatico-da-sessao-nega-ferramenta-a-gancho-agent>).
      Confirmar numa resposta real, com o modo automático desligado,
      que pelo menos um dos quatro consegue rodar um comando (`cat`,
      `git status`) e usar o resultado na decisão -- não só imprimir o
      formato de resposta certo.

- [ ] **Confirmar de ponta a ponta, numa sessão nova, os mecanismos
      corrigidos nesta rodada (bloqueio real dos ganchos de
      conformidade).**

      *Resumo simples:* mesma limitação de toda esta lista -- a
      sessão que corrige não consegue ver a correção valendo de
      verdade, porque os ganchos rodam a partir da pasta principal do
      repositório, não da worktree onde a correção foi escrita. Cinco
      pontos corrigidos nesta rodada, ainda sem confirmação numa
      sessão limpa, que já carregue os arquivos corrigidos desde o
      início.

      *Detalhe técnico:* cinco pontos a confirmar: (1) `SessionStart`
      não apaga mais a ficha na compactação (só em
      início/retomada/limpeza de verdade); (2) a ficha se recupera
      sozinha de um estado corrompido (arquivo vazio ou JSON inválido),
      sem precisar de intervenção manual; (3) `AUTORIZO-TRAVA` não
      dispara mais por um texto de exemplo citado, só por um motivo de
      fato escrito; (4) a leitura manual obrigatória dos seis
      documentos expira depois de 20 ações, exigindo releitura; (5) os
      itens 13 (achado sem registro) e 14/15 (escolha sem ADR) de
      `pre_edit_safety.sh` sinalizam nos casos certos e destravam pelas
      frases de confirmação específicas. Ver
      [findings.md](<findings.md#2026-08-28-sessionstart-sem-matcher-reseta-a-ficha-na-compactacao>)
      em diante, e
      [decisions/0013](<../decisions/0013-frescor-uniforme-de-leitura-substitui-permanencia.md>).

- [ ] **Investigar `pre_git_rules.sh` bloqueando commit legítimo numa
      worktree de tarefa, achando que a branch ativa era `develop`.**
      Relato de outra sessão, não reproduzido ao vivo nesta rodada --
      ver [analysis.md](<analysis.md#2026-08-29-relatorio-de-outra-sessao-e-reset-da-ficha-no-evento-resume>),
      item 3.

- [ ] **Confirmar de ponta a ponta, numa sessão nova, os mecanismos
      corrigidos nesta rodada.** Ver
      [decisions/0015](<../decisions/0015-sessionstart-nao-reseta-mais-a-ficha-no-evento-resume-e-janela-de-frescor-maior.md>),
      [decisions/0016](<../decisions/0016-autorizo-trava-rejeita-reticencias-sem-motivo-real.md>),
      [decisions/0017](<../decisions/0017-comandos-git-gh-isentos-da-leitura-manual-obrigatoria.md>)
      e
      [decisions/0018](<../decisions/0018-frases-de-confirmacao-toleram-virgula-opcional.md>).

- [ ] **Confirmar ao vivo, numa sessão nova, os quatro revisores de PR,
      o comando que os chama juntos, e o gancho novo em `gh pr create`
      -- incluindo, agora, se isso vale de dentro de uma worktree, não
      só na pasta principal.**

      *Resumo simples:* os quatro assistentes de revisão de PR, o
      comando que os dispara juntos, e o gancho que confere se a
      revisão já rodou antes de abrir o PR foram escritos e conferidos
      por sintaxe, mas nenhum foi chamado de verdade ainda -- mesma
      limitação já registrada em
      [pitfalls.md](<pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>):
      a sessão que escreve uma mudança em `.claude/` não vê essa
      mudança valendo de verdade nela mesma.

      *Detalhe técnico:* ver
      [decisions/0020](<../decisions/0020-revisao-de-pr-por-assistentes-chamados-manualmente.md>).
      Confirmar, numa sessão nova: (1) cada um dos quatro assistentes
      roda quando chamado pelo nome; (2) o comando dispara os quatro em
      paralelo e junta o resultado; (3) `pre_pr_review_check.sh`
      bloqueia `gh pr create` quando não há revisão registrada, ou
      quando a última revisão é anterior à última edição, e libera
      quando a revisão está em dia.

      *Nota de acompanhamento, 03-09-2026:* todo o conteúdo de
      `.claude/agents/`, `.claude/hooks/`, `.claude/settings.json` e o
      resto do material retirado do remoto (ver `HANDOFF.md`, raiz)
      tinha sido apagado do disco por engano, não só retirado do
      controle de versão -- restaurado a partir do commit anterior à
      remoção (`git checkout <commit-pai> -- <caminhos>`, seguido de
      `git reset HEAD` pra tirar da área de stage, mantendo tudo fora
      do controle de versão como o `.gitignore` já previa). Na mesma
      sessão, tentativa de chamar os quatro revisores pelo nome
      (`subagent_type: revisor-testes`, etc.), de dentro de uma
      worktree de tarefa, falhou -- devolveu "Agent type 'revisor-testes'
      not found", listando só os tipos genéricos do Claude Code. Não é
      confirmação de que o problema é a worktree em si: essa mesma
      sessão tinha começado antes da restauração, e a configuração de
      agente/gancho só carrega uma vez, no início da sessão (mesmo
      limite já registrado em
      [pitfalls.md](<pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>))
      -- então o resultado pode ter sido só isso, não a worktree.
      Ponto novo que esta pendência precisa cobrir, além dos três já
      listados: (4) confirmar isso especificamente de dentro de uma
      worktree nova (`.claude/worktrees/<tarefa>/`), numa sessão que já
      comece depois da restauração -- não só na pasta principal, já que
      toda tarefa deste projeto roda numa worktree, nunca na pasta
      principal (CLAUDE.md, "Trabalho em múltiplas frentes"). Se não
      carregar de dentro da worktree, a causa mais provável é
      `${CLAUDE_PROJECT_DIR}`/a resolução de `.claude/settings.json` não
      alcançar a pasta principal a partir de um caminho de worktree --
      ainda sem confirmação nenhuma, nem a favor nem contra.

      *Nota de acompanhamento, 04-09-2026:* ponto (4) confirmado, numa
      worktree nova de tarefa do módulo `motor`, sessão começada depois
      da restauração: `${CLAUDE_PROJECT_DIR}` já resolve certo pra
      pasta principal (os ganchos do evento `Stop` disparavam
      normalmente dali, usando ferramenta de verdade) -- a causa real
      era mais estreita, e ficou totalmente diagnosticada e corrigida.
      Ver [decisions/0021](<../decisions/0021-atalho-de-pasta-liga-material-local-em-toda-worktree.md>)
      e o achado correspondente em
      [findings.md](<findings.md#2026-09-04-worktree-nova-nunca-via-agentes-hooks-nem-modulo-conformidade>).
      A parte que ainda falta desta pendência -- confirmar se os quatro
      agentes de revisão passam a aparecer na lista de agentes
      disponíveis de uma sessão nova, iniciada depois desta correção --
      continua em aberto: a correção de hoje não pôde ser testada nesse
      ponto específico dentro da própria sessão que a escreveu (mesmo
      limite já documentado em
      [pitfalls.md](<pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)).

- [ ] **Resolver de vez o gancho do evento `Stop` que exige resposta em
      formato de dado bruto (JSON), em vez de texto normal.**

      *Resumo simples:* uma das checagens automáticas que rodam no fim
      de cada resposta pede, de forma repetida, que a resposta inteira
      seja só um bloco de dado técnico (sem nenhuma frase em
      português) — o oposto da regra do próprio projeto, que exige
      toda resposta em português, explicando tudo em linguagem
      simples.

      *Detalhe técnico:* a checagem bloqueia de forma repetida (mais
      de dez vezes seguidas, num caso registrado), mesmo depois de a
      resposta já estar em conformidade com as outras regras (idioma,
      termo técnico explicado, sem emoji). A própria documentação
      oficial do Claude Code já marca esse tipo de gancho
      ("Prompt-based hooks", evento `Stop`) como experimental —
      pendência é confirmar se o formato de saída esperado por este
      gancho específico está de acordo com essa documentação, e
      corrigir o texto da instrução dele (ou trocar de mecanismo) pra
      parar de pedir um formato que contradiz a regra de idioma/
      linguagem simples do próprio projeto.

## Resolvidas

- [x] **Corrigir `scripts/hooks/pre-commit` nunca detectando subida de
      versão em documento só com a tabela "Controle de versão", sem
      tabela de cabeçalho.** Resolvido -- ver
      [decisions/0019](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>).

- [x] **Investigar a frase de confirmação "commit revisado, confirmado"
      não destravando `pre_commit_hygiene.sh`, relatado por outra
      sessão.** Resolvido -- ver
      [decisions/0018](<../decisions/0018-frases-de-confirmacao-toleram-virgula-opcional.md>).

- [x] **Confirmar ao vivo, numa sessão nova, a ficha/síntese
      ([decisions/0012](<../decisions/0012-ficha-sintese-substitui-releitura-do-diario-a-cada-checagem.md>)).**
      Resolvido, embora não do jeito planejado (nenhum teste isolado
      de propósito) -- a própria sessão que corrigiu o resto deste
      módulo ficou repetidamente bloqueada pela ficha travando de
      verdade (leitura manual obrigatória reaparecendo, mesmo depois
      de já satisfeita), confirmando ao vivo que o bloqueio funciona.
      Essa mesma experiência revelou dois defeitos novos na própria
      ficha, corrigidos na mesma rodada -- ver
      [findings.md](<findings.md#2026-08-28-sessionstart-sem-matcher-reseta-a-ficha-na-compactacao>)
      e
      [findings.md](<findings.md#2026-08-28-corrupcao-e-perda-de-fato-na-ficha-por-escrita-concorrente>).

## Controle de versão

| Versão | Data | Alteração | Origem da alteração |
|---|---|---|---|
| 0.1.0 | 27-08-2026 | Criação inicial -- quatro pendências registradas. | Criação inicial do módulo |
| 0.2.0 | 27-08-2026 | Pendência nova acrescentada: confirmação de ponta a ponta dos cinco mecanismos corrigidos na segunda rodada (decisions/0006 a 0008). | Correção do formato de bloqueio que nunca era reconhecido pelo Claude Code |
| 0.3.0 | 28-08-2026 | Pendência de investigação da causa raiz do "modo sem perguntar" atualizada com pista nova; pendência nova acrescentada (confirmação do auto-portão de decisions/0011 nos dois ganchos agent). | Correção da falha aberta do filtro `if` |
| 0.4.0 | 28-08-2026 | Pendência nova acrescentada (confirmação da ficha/síntese, decisions/0012, numa sessão nova). | Fechamento da lacuna de documentação da ficha/síntese |
| 0.5.0 | 28-08-2026 | Pendência de confirmação da ficha/síntese resolvida (confirmada ao vivo por acidente, revelando dois defeitos novos, corrigidos na mesma rodada); pendência nova acrescentada (confirmação de ponta a ponta dos mecanismos desta rodada). | Correção do bloqueio real dos ganchos de conformidade |
| 0.6.0 | 28-08-2026 | Duas pendências resolvidas (causa raiz do "modo sem perguntar"; auto-portão dos dois ganchos `agent` removidos); pendência nova acrescentada (confirmar os quatro ganchos de IA restantes com o modo automático desligado); nota de acompanhamento na pendência de confirmação da segunda rodada, precisando quais dos cinco pontos ainda se aplicam. | Resolução de [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>) |
| 0.7.0 | 29-08-2026 | Três pendências novas acrescentadas: dois relatos de outra sessão não reproduzidos nesta rodada (`pre_git_rules.sh`, frase de confirmação de commit); confirmação de ponta a ponta dos mecanismos corrigidos nesta rodada (decisions/0015 a 0017). | Correção de falsos bloqueios reportados de outra sessão + pedido de janela de frescor maior |
| 0.8.0 | 29-08-2026 | Pendência da frase de confirmação de commit resolvida -- ver decisions/0018. | Resolução de [decisions/0018](<../decisions/0018-frases-de-confirmacao-toleram-virgula-opcional.md>) |
| 0.9.0 | 29-08-2026 | Pendência nova resolvida na mesma rodada: `scripts/hooks/pre-commit` corrigido -- ver decisions/0019. | Resolução de [decisions/0019](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>) |
| 0.10.0 | 29-08-2026 | Pendência nova acrescentada: confirmação ao vivo dos quatro revisores de PR, do comando que os chama juntos, e do gancho novo em `gh pr create`. | Resolução de [decisions/0020](<../decisions/0020-revisao-de-pr-por-assistentes-chamados-manualmente.md>) |
| 0.11.0 | 03-09-2026 | Nota de acompanhamento na pendência de confirmação dos quatro revisores de PR: todo o conteúdo deste módulo e do resto do material local tinha sido apagado do disco por engano (não só retirado do controle de versão), já restaurado; ponto novo (4) acrescentado, sobre confirmar isso especificamente de dentro de uma worktree, não só na pasta principal -- tentativa nesta mesma sessão, de dentro de uma worktree, não achou os quatro revisores pelo nome, mas não é confirmação limpa (sessão começou antes da restauração). | Achado durante a tarefa "aviso-radio-desligado-tela-jogo" do módulo motor |
| 0.12.0 | 04-09-2026 | Nota de acompanhamento na pendência de confirmação dos quatro revisores de PR: ponto (4) diagnosticado por completo e corrigido -- ver decisions/0021; parte restante (revisores aparecerem numa sessão nova, depois da correção) segue em aberto. | Achado durante a tarefa "confirmar-visual-barra-titulo" do módulo motor; resolução de [decisions/0021](<../decisions/0021-atalho-de-pasta-liga-material-local-em-toda-worktree.md>) |
| 0.13.0 | 04-09-2026 | Pendência nova acrescentada, sobre o formato de resposta exigido pelo gancho do evento `Stop`. | Achado ao vivo durante a tarefa "confirmar-visual-barra-titulo" do módulo motor |
