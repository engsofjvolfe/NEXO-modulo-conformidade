# Tasks — Conformidade

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Tasks |
| Versão | 0.24.0 |
| Data | 10-09-2026 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

> Lista mutável de pendências só deste módulo. Lida depois de
> `concept.md`/`architecture.md`, antes de mexer em qualquer coisa.
> Atualizada direto conforme resolve. Assim que uma pendência vira
> decisão de verdade, o item aqui vira só um ponteiro pra ADR em
> `decisions/` — nunca um resumo paralelo do que a decisão já diz.
> Pendência resolvida (com ou sem ADR) não é apagada — vira item
> riscado na seção `Resolvidas`. Pendência específica do projeto
> hospedeiro (não do código deste módulo em si) não entra aqui --
> este arquivo viaja pro repositório separado do módulo, que precisa
> servir qualquer projeto hospedeiro. Cada item usa data explícita
> (não "hoje", "esta sessão" ou "nesta rodada") -- entrada datada
> nunca é reescrita depois, então uma referência relativa ao tempo
> perde o sentido assim que alguém lê o item bem depois de escrito.
>
> Cada item segue [a regra de escrita geral](../CONVENCOES.md#como-escrever):
> resumo simples primeiro, detalhe técnico depois.

## Índice
- [Em aberto](#em-aberto)
- [Resolvidas](#resolvidas)
- [Controle de versão](#controle-de-versão)

## Em aberto

- [ ] **Confirmar de ponta a ponta, numa sessão nova, que os cinco
      mecanismos corrigidos em 27-08-2026 (segunda rodada daquele dia)
      bloqueiam de verdade.**

      *Resumo simples:* uma queixa direta -- "o sistema ainda deixa
      escolher se segue a trava ou não" -- revelou que boa parte do
      sistema nunca bloqueava de verdade: o formato de resposta que os
      ganchos revisados por IA usavam não é reconhecido pelo Claude
      Code como decisão de bloqueio, então eles só "avisavam". Cinco
      pontos corrigidos; a mesma sessão que corrige não consegue
      confirmar o bloqueio ao vivo (ver
      [pitfalls.md](<pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)).

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
      mecanismos criados em 27-08-2026 (criação do módulo) bloqueiam
      de verdade.**

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

- [ ] **Confirmar ao vivo, com o modo automático da sessão desligado
      (desligamento feito em 28-08-2026), que os quatro ganchos
      decididos por IA que ainda existem (revisão de edição de
      documento, duas checagens do fim da resposta, checagem de
      idioma/emoji) conseguem usar ferramenta de verdade.**

      *Resumo simples:* mesmo com o formato de resposta corrigido, os
      quatro continuaram sem conseguir ler nada enquanto o modo
      automático estava ligado -- confirmado ao vivo mais de uma vez,
      em 28-08-2026. O modo automático foi desligado no fim daquele
      dia, mas a confirmação de que isso resolve o problema de verdade
      ainda não aconteceu.

      *Detalhe técnico:* ver
      [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>)
      e o achado correspondente em
      [findings.md](<findings.md#2026-08-28-modo-automatico-da-sessao-nega-ferramenta-a-gancho-agent>).
      Confirmar numa resposta real, com o modo automático desligado,
      que pelo menos um dos quatro consegue rodar um comando (`cat`,
      `git status`) e usar o resultado na decisão -- não só imprimir o
      formato de resposta certo.

- [ ] **Confirmar de ponta a ponta, numa sessão nova, os mecanismos
      corrigidos em 28-08-2026 (bloqueio real dos ganchos de
      conformidade).**

      *Resumo simples:* a sessão que corrige não consegue ver a
      correção valendo de verdade, porque os ganchos rodam a partir da
      pasta principal do repositório, não da worktree onde a correção
      foi escrita. Cinco pontos corrigidos naquele dia, ainda sem
      confirmação numa sessão limpa, que já carregue os arquivos
      corrigidos desde o início.

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

- [ ] **Confirmar de ponta a ponta, numa sessão nova, os mecanismos
      corrigidos em 29-08-2026.** Ver
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
      por sintaxe, em 29-08-2026, mas nenhum foi chamado de verdade
      ainda -- mesma limitação já registrada em
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
      data, tentativa de chamar os quatro revisores pelo nome
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
      continua em aberto: a correção de 04-09-2026 não pôde ser testada
      nesse ponto específico dentro da própria sessão que a escreveu
      (mesmo limite já documentado em
      [pitfalls.md](<pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)).

- [ ] **Confirmar de ponta a ponta, numa sessão nova, que
      `pre_pr_description_check.sh` bloqueia de verdade um PR fora do
      modelo oficial.**

      *Resumo simples:* a trava foi escrita e ligada ao evento certo
      em 04-09-2026, mas ainda não foi vista bloqueando um PR de
      verdade, numa sessão que já carregue o arquivo desde o início.

      *Detalhe técnico:* mesma limitação já registrada nas pendências
      de confirmação acima -- a sessão que escreve o gancho não
      consegue ver a configuração de ganchos recarregar sozinha (ver
      [pitfalls.md](<pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)).

- [ ] **Confirmar ao vivo, numa sessão nova, os pontos corrigidos em
      08-09-2026 que ainda não foram vistos bloqueando de verdade.**

      *Resumo simples:* parte do que foi corrigido naquele dia já foi
      confirmado ao vivo dentro da própria sessão (negação de
      `cat`/`head`/`grep`; fluxo completo de leitura cheia seguida de
      edição; acesso ao material do módulo pela raiz através do atalho
      de pasta) -- essa parte virou nota de acompanhamento direto nas
      ADRs correspondentes, nunca item aqui, porque não faz sentido
      nascer pendência de algo que já foi visto funcionando. Os pontos
      abaixo são só o que ainda não foi visto, de verdade, bloqueando.

      *Detalhe técnico:* (1) leitura parcial (offset/limit) sem
      leitura cheia fresca antes bloqueando -- decisions/0023; (2)
      `Write` sobre arquivo já existente sem leitura fresca bloqueando
      -- mesma ADR; (3) `tail`, `sed` e `awk` negados (só
      `cat`/`head`/`grep` foram confirmados) -- decisions/0024; (4)
      editar diretamente a pasta de estado/autorização negado
      (`Edit(/.claude/hooks/state/**)`); (5) resposta com emoji de
      propósito bloqueando por `stop_emoji_check.sh` -- decisions/0026;
      (6) resposta com termo já explicado, mesmo resumido, não
      bloqueando mais por falso positivo.

- [ ] **Confirmar ao vivo, numa sessão nova, que o gancho de leitura
      obrigatória (`pre_mandatory_reading_guard.sh`) bloqueia e libera
      de verdade com a lista lida do `CLAUDE.md` (decisions/0028).**
      Ver [findings.md](<findings.md#2026-09-08-lista-de-leitura-obrigatoria-escrita-direto-no-codigo>)
      pro que já foi confirmado (a função que lê a lista, isolada, em
      08-09-2026); o gancho inteiro, dentro do fluxo real de uma
      ferramenta, ainda não foi visto bloqueando nem liberando.

- [ ] **Confirmar ao vivo, numa sessão nova, o caminho de worktree a
      ligar reaproveitando a lista de ferramenta interna
      (decisions/0029), e a checagem de autorização por Read nos três
      ganchos de IA (decisions/0030).**

      *Resumo simples:* as duas correções foram escritas e conferidas
      por sintaxe em 08-09-2026, mas não vistas ao vivo, numa sessão
      nova.

      *Detalhe técnico:* confirmar: (1) `ensure_worktree_links` liga as
      pastas certas numa worktree nova, lendo `internal_tooling_paths`
      em vez de lista fixa; (2) os três pontos que usam uma segunda
      inteligência artificial (revisão de edição, duas checagens do fim
      da resposta) conseguem checar `AUTORIZO-TRAVA` de verdade,
      usando a ferramenta Read em vez do comando negado `cat`.

- [ ] **Confirmar ao vivo, numa sessão nova, que um bloqueio do evento
      `Stop` cuja resposta só a pessoa resolve pergunta uma vez só,
      sem repetir sem fim (decisions/0033).**

      *Resumo simples:* a correção foi escrita e conferida por sintaxe
      em 09-09-2026, mas o próprio defeito só aparece de verdade numa
      sessão nova, que já carregue os arquivos corrigidos desde o
      início -- a sessão que escreveu a correção não consegue testar
      isso nela mesma.

      *Detalhe técnico:* confirmar, numa sessão nova: (1) um bloqueio
      de `stop_fact_check.sh` (ex.: `git status` sujo) aparece uma vez,
      depois libera a resposta terminar, sem aparecer de novo sem
      mensagem nova; (2) o mesmo comportamento nos três pontos que
      usam uma segunda inteligência artificial no evento `Stop`; (3)
      uma mensagem nova de verdade reabre a possibilidade de perguntar
      de novo, se a situação ainda pedir.

- [ ] **Confirmar ao vivo, numa sessão nova, a sincronização automática
      entre este projeto e o projeto hospedeiro (decisions/0034), o
      instalador de comando único com localização livre
      (`scripts/instalar.sh`, decisions/0036), e a isenção de leitura
      obrigatória pro `CLAUDE.md`/transcrição (decisions/0035).**

      *Resumo simples:* as correções foram escritas, testadas por
      sintaxe, e a sincronização já foi feita manualmente uma vez em
      10-09-2026 -- mas o comportamento automático (sozinho, no início
      de uma sessão nova) e o instalador completo (num projeto
      diferente, do zero, em caminho livre) ainda não foram vistos
      acontecendo de verdade.

      *Detalhe técnico:* confirmar, numa sessão nova: (1) alterar de
      propósito só a cópia local (qualquer um dos seis itens
      copiáveis, ex.: `modulos/conformidade/.claude/settings.json`) e,
      na sessão nova seguinte, ver o arquivo correspondente da raiz
      mudar sozinho, sem nenhuma cópia manual; (2) o vigia auditor do
      evento `Stop` conseguir ler o `CLAUDE.md` e a transcrição sem
      cair na cascata de leitura obrigatória; (3) `scripts/instalar.sh`
      rodado do zero, num projeto de teste separado, copiando a pasta
      pra um caminho qualquer (não `modulos/conformidade`) e rodando o
      comando da raiz -- confirma que o marcador é gravado certo, os
      dois atalhos de pasta e o restante são criados corretamente.

## Resolvidas

- [x] **Investigar a causa raiz do "modo sem perguntar" que bloqueou o
      gancho de `Stop` durante parte de uma sessão anterior.**
      Resolvido -- ver
      [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>).

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

- [x] **Resolver de vez o gancho do evento `Stop` que exige resposta
      em formato de dado bruto (JSON), em vez de texto normal, e que
      ficava insistindo em achado já explicado na resposta.** Resolvido
      -- checagem de emoji virou fato mecânico (`stop_emoji_check.sh`,
      sem IA), gancho de julgamento restante ficou só com a pergunta
      sobre termo técnico, instrução menos propensa a falso positivo.
      Ver [decisions/0026](<../decisions/0026-checagem-de-emoji-no-fim-da-resposta-vira-fato-mecanico.md>).

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

- [x] **Completar a lista de ganchos em `architecture.md` com
      `pre_pr_review_check.sh` e `worktree_create_setup.sh`, cada um
      com sua própria ADR retroativa.**
      Resolvido -- ver
      [decisions/0031](<../decisions/0031-revisao-de-pr-fica-desatualizada-e-fato-mecanico.md>)
      e
      [decisions/0032](<../decisions/0032-worktree-nova-liga-pastas-locais-por-atalho.md>).

- [x] **Auditar se `scripts/hooks/pre-commit` e `scripts/README.md`
      citam convenção específica do projeto onde este projeto foi
      usado pela primeira vez, fora do escopo genérico do resto deste
      código.**
      Resolvido -- a checagem em si já era genérica; comentários
      generalizados, sem citar caminho de projeto específico. Ver
      [decisions/0036](<../decisions/0036-localizacao-de-instalacao-livre-marcador-substitui-caminho-fixo.md>).

- [x] **Investigar `pre_git_rules.sh` bloqueando commit legítimo numa
      worktree de tarefa, achando que a branch ativa era `develop`.**
      Reproduzido ao vivo, de propósito, em 10-09-2026: `.cwd` (pasta
      atual que o Claude Code informa ao gancho) não acompanha um `cd`
      escrito dentro do próprio comando -- só a ferramenta
      `EnterWorktree` move a sessão de verdade. Sem correção de código
      -- comportamento correto do gancho, dado um jeito de trabalhar
      que este projeto já não recomenda. Ver
      [pitfalls.md](<pitfalls.md#2026-09-10-cwd-do-gancho-nao-acompanha-cd-dentro-do-proprio-comando>).

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
| 0.14.0 | 04-09-2026 | Duas pendências novas acrescentadas. | Resolução de [decisions/0022](<../decisions/0022-checagem-do-corpo-do-pr-contra-o-modelo-oficial.md>) |
| 0.15.0 | 08-09-2026 | Pendência do formato de resposta em JSON do gancho `Stop` movida pra Resolvidas (decisions/0026); pendência nova sobre confirmação ao vivo dos pontos desta rodada, só com o que ainda não foi visto funcionando (o que já foi confirmado virou nota de acompanhamento direto nas ADRs, nunca item aqui); pendência nova sobre a regra absoluta no documento de instruções do projeto hospedeiro (decisions/0024), bloqueada até decisão sobre a leitura dos seis documentos obrigatórios do projeto hospedeiro. | Fechamento da rodada de frescor por tokens, negação de comando de Bash, atalho de pasta e checagem de emoji |
| 0.16.0 | 08-09-2026 | Pendência nova acrescentada: confirmação ao vivo do gancho de leitura obrigatória inteiro, com a lista lida do `CLAUDE.md` (decisions/0028). | Resolução de [decisions/0028](<../decisions/0028-lista-de-leitura-obrigatoria-lida-do-arquivo-de-instrucoes.md>) e [decisions/0027](<../decisions/0027-leitura-obrigatoria-ignora-ferramenta-sem-alvo-de-arquivo.md>) |
| 0.17.0 | 08-09-2026 | Três pendências já marcadas como feitas, mas ainda em "Em aberto" (causa raiz do "modo sem perguntar", auto-portão, ficha/síntese), movidas pra "Resolvidas" -- a de ficha/síntese era cópia duplicada de uma entrada que já existia lá; pendência nova acrescentada sobre confirmação ao vivo de decisions/0029 e 0030. | Resolução de [decisions/0029](<../decisions/0029-caminho-de-worktree-a-ligar-reaproveita-ferramenta-interna.md>) e [decisions/0030](<../decisions/0030-ganchos-de-ia-usam-read-em-vez-de-cat-pra-checar-autorizacao.md>) |
| 0.18.0 | 08-09-2026 | Três pendências específicas do projeto hospedeiro (não do módulo) removidas: auditoria linha a linha do `CLAUDE.md` do projeto hospedeiro; formalização retroativa apoiada num documento específico do projeto hospedeiro (`MANUAL.md`, seção 9); regra absoluta a acrescentar no arquivo de instruções do projeto hospedeiro. Nota da pendência de `architecture.md` ajustada, sem mais apontar pra pendência removida. | Correção de agnosticismo -- pendência específica de projeto não pertence ao repositório do módulo |
| 0.19.0 | 09-09-2026 | Toda referência a "hoje", "esta sessão" ou "nesta rodada" trocada por data explícita, em todo item -- entrada datada nunca é reescrita depois, então referência relativa ao tempo perde o sentido lida bem depois de escrita. Pendência do `architecture.md` (`pre_pr_review_check.sh`, `worktree_create_setup.sh`) resolvida, movida pra "Resolvidas". | Pedido explícito de reescrita atemporal; resolução de [decisions/0031](<../decisions/0031-revisao-de-pr-fica-desatualizada-e-fato-mecanico.md>) e [decisions/0032](<../decisions/0032-worktree-nova-liga-pastas-locais-por-atalho.md>) |
| 0.20.0 | 09-09-2026 | Pendência nova acrescentada: confirmação ao vivo, numa sessão nova, de que um bloqueio do evento `Stop` cuja resposta só a pessoa resolve pergunta uma vez só, sem repetir sem fim. | Resolução de [decisions/0033](<../decisions/0033-bloqueio-que-so-a-pessoa-resolve-pergunta-uma-vez-so.md>) |
| 0.21.0 | 10-09-2026 | Pendência nova acrescentada: confirmação ao vivo, numa sessão nova, da sincronização automática de `settings.json` e da isenção de leitura obrigatória pro `CLAUDE.md`/transcrição. | Resolução de [decisions/0034](<../decisions/0034-copia-de-settings-json-sincronizada-no-inicio-de-cada-sessao.md>) e [decisions/0035](<../decisions/0035-leitura-obrigatoria-libera-claude-md-e-transcricao-sempre.md>) |
| 0.22.0 | 10-09-2026 | Pendência de sincronização estendida (instalador de comando único, seis itens copiáveis, não só `settings.json`); pendência nova acrescentada: auditar se `scripts/hooks/pre-commit`/`scripts/README.md` citam convenção específica do projeto onde este módulo nasceu. | Instalação de um comando só (`scripts/instalar.sh`); remoção de `MANUAL.md` deste módulo, mantido só na raiz do projeto hospedeiro |
| 0.23.0 | 10-09-2026 | Pendência de confirmação ao vivo atualizada (localização de instalação livre, não mais caminho fixo); pendência de auditoria movida pra Resolvidas. | Resolução de [decisions/0036](<../decisions/0036-localizacao-de-instalacao-livre-marcador-substitui-caminho-fixo.md>) |
| 0.24.0 | 10-09-2026 | Pendência de `pre_git_rules.sh` (aberta desde 29-08-2026) movida pra Resolvidas, reproduzida ao vivo de propósito. | Fechamento de item pendente há mais tempo neste documento |
