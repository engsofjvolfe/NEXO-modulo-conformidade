# 0021 — Atalho de pasta liga o material local do módulo em toda worktree nova

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Decisions — 0021 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

*Em resumo:* toda worktree nova passa a enxergar, automaticamente, as
três pastas deste módulo que só existem na pasta principal (definição
dos quatro agentes de revisão, os scripts de gancho e sua própria
documentação) — por um atalho de pasta criado sozinho, sem tirar nada
do controle de versão.

## Status

Aceito.

## Contexto

Achado ao vivo, numa sessão de tarefa do módulo `motor`, dentro de uma
worktree nova: os quatro agentes de revisão de PR não apareciam na
lista de agentes disponíveis, e `modulos/conformidade` não existia no
disco daquela worktree. Investigação confirmou a causa raiz: as três
pastas -- `.claude/agents`, `.claude/hooks` e `modulos/conformidade` --
ficam de propósito fora do controle de versão (`.gitignore`, ver
`HANDOFF.md` da raiz), e `git worktree add` só traz conteúdo já
versionado. Uma worktree nova nunca teve, e nunca teria sozinha, essas
três pastas.

Ao mesmo tempo, ficou confirmado que os ganchos do evento `Stop`
(configurados em `.claude/settings.json`, que só existe na pasta
principal) disparavam normalmente de dentro dessa mesma worktree, sem
nenhuma das três pastas presentes -- inclusive usando ferramenta de
verdade (um dos ganchos citou o horário exato do último commit, e esse
horário bateu com `git log` real). Isso mostra que
`${CLAUDE_PROJECT_DIR}` já resolve pra pasta principal em qualquer
worktree -- o problema não é esse. O problema é mais estreito: (1) um
trecho de instrução de gancho que usa caminho relativo sem esse
prefixo (ex.: `cat .claude/hooks/state/current-authorization`) aponta
pro lugar errado quando a pasta atual é uma worktree; (2) a lista de
agentes nomeados que o Claude Code carrega parece olhar pra pasta
atual da sessão, não pra `${CLAUDE_PROJECT_DIR}` -- por isso os quatro
revisores de PR não apareciam.

Pendência já registrada em `tasks.md` antes deste achado ("Confirmar
ao vivo... se isso vale de dentro de uma worktree, não só na pasta
principal") pedia exatamente essa confirmação, numa sessão nova,
depois de uma restauração anterior de arquivo apagado por engano --
condição batida por esta mesma sessão.

## Decisão

- Cada worktree nova ganha, sozinha, um atalho de pasta (*junction* do
  Windows -- ao contrário de link simbólico, não exige privilégio de
  administrador nem Modo desenvolvedor) pra cada uma das três pastas
  locais, apontando pra pasta real da pasta principal:
  `.claude/agents`, `.claude/hooks`, `modulos/conformidade`.
- Duas camadas, mesmo padrão de dupla cobertura já usado em
  `WorktreeRemove`/`pre_git_rules.sh`
  (`worktree_remove_cleanup.sh`, comentário de topo):
  1. Gancho novo (`worktree_create_setup.sh`), evento nativo
     `WorktreeCreate` -- cobre o caminho principal (ferramenta
     `EnterWorktree`), mas pode não disparar quando a worktree nasce de
     `git worktree add` digitado à mão.
  2. Reforço dentro de `pre_mandatory_reading_guard.sh` (já roda em
     toda ferramenta, em qualquer worktree) -- cobre o caminho manual,
     idempotente e barato o bastante pra rodar sempre.
- Mecanismo, em `ensure_worktree_links` (`lib/common.sh`): não faz
  nada se a pasta informada já é a pasta principal, se o atalho (ou uma
  pasta de verdade com esse nome) já existe ali, ou se a pasta de
  origem nem existe. Caminho convertido pra absoluto do Windows
  (`cygpath -w`) antes de chamar o PowerShell (`New-Item -ItemType
  Junction`) -- confirmado ao vivo que passar caminho estilo Git Bash
  direto pro PowerShell resolve errado (interpreta relativo à raiz do
  disco, não à pasta pretendida, porque PowerShell é outro processo,
  fora do ambiente MSYS).
- Alternativas descartadas: copiar o conteúdo pra cada worktree nova
  (duplicaria arquivo, sem nenhum ganho sobre o atalho, e desatualiza
  sozinho a cada mudança feita só na pasta principal); variável de
  ambiente redirecionando cada caminho (exigiria reescrever toda
  referência já existente nos scripts, ao contrário do atalho, que não
  muda nenhum script que já funcionava); link simbólico (exige
  privilégio que este computador não tem configurado, confirmado
  informalmente antes de optar pelo *junction*).

## Consequências

- Testado ao vivo, de ponta a ponta, nesta mesma sessão: as três pastas
  criadas por atalho numa worktree real (`.claude/worktrees/
  confirmar-visual-barra-titulo`), conteúdo de dentro do atalho
  conferido (arquivos dos quatro agentes, scripts de gancho,
  documentação do módulo), atalho removido e recriado chamando a
  própria função de produção (não uma cópia de teste à parte),
  idempotência confirmada (rodar de novo não duplica nem falha), e o
  caso de passar a própria pasta principal como argumento confirmado
  como no-op. Origem nunca tocada -- remoção de atalho testada sem
  `-Recurse`/sem apagar conteúdo real.
- Ainda sem confirmação, fora do escopo desta ADR: se os quatro
  agentes de revisão passam a aparecer na *lista de agentes
  disponíveis* de uma sessão nova, depois deste atalho já existir desde
  o início dela -- essa parte específica só se confirma numa sessão
  que comece depois desta correção, igual o restante da pendência
  já registrada (ver nota de acompanhamento em `tasks.md`).
- Evento nativo `WorktreeCreate` (camada 1) carrega o mesmo limite já
  documentado pra `WorktreeRemove`: sem confirmação de que dispara de
  verdade neste ambiente -- a camada 2 (reforço em
  `pre_mandatory_reading_guard.sh`) existe justamente por causa dessa
  incerteza, não como redundância desnecessária.

### Nota de acompanhamento — 04-09-2026

*Em resumo:* o teste já registrado acima só conferiu que nada de
errado acontece quando o mecanismo roda direto na pasta principal do
projeto. Nunca foi testado o que acontece quando ele roda numa pasta
que fica *dentro* da pasta principal (por exemplo, ao entrar numa
pasta pra rodar um comando de lá) -- e, nesse caso, o mecanismo
enganava a si mesmo, achando que essa pasta comum era uma worktree
nova, e criava um atalho dentro dela por engano. Isso foi encontrado
de verdade, em mais de um lugar, numa sessão real de trabalho.

*Em detalhe técnico:* corrigido em `lib/common.sh` -- a função só
prossegue quando o caminho recebido bate exatamente com o padrão
`.../.claude/worktrees/<nome>`, sem nenhuma subpasta depois do nome.
Efeito colateral concreto do bug, encontrado na mesma sessão: como o
atalho aponta pra dentro da própria pasta que já continha o atalho,
uma cópia (`cp -r`) que usasse esse atalho como destino aninhava o
conteúdo copiado um nível a mais dentro da pasta canônica de verdade,
criando ali uma subpasta real e duplicada com o mesmo nome
(`.claude/agents/agents/`, `.claude/hooks/hooks/`) -- removida
manualmente depois da correção, sem perda de dado (o `state/`
duplicado nunca era atualizado, porque `STATE_DIR` sempre aponta pra
`${CLAUDE_PROJECT_DIR}`, não pro caminho relativo do script). Todos os
atalhos espúrios (`.claude/.claude/`, `.claude/modulos/`,
`modulos/conformidade/.claude/`, `modulos/conformidade/modulos/`, e os
equivalentes dentro de `modulos/motor` numa worktree real) removidos;
os três atalhos corretos (raiz de cada worktree) conferidos, intactos.
