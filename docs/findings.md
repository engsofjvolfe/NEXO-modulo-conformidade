# Findings — Conformidade

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Findings |
| Versão | 0.12.0 |
| Data | 04-09-2026 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

> Achados confirmados (por leitura de código, teste ao vivo, ou os dois)
> sobre este módulo — cada entrada datada.
>
> Checa se o código já existente bate com o requisito que `concept.md`
> já descreve -- nunca o contrário: um achado aqui não muda o que
> `concept.md` diz que deveria existir, só revela onde o código diverge
> disso (a divergência vira pendência em `tasks.md`). Pode acontecer a
> qualquer momento: antes de `architecture.md` existir, ou depois,
> quando a implementação revela algo não previsto no desenho.
>
> Um achado, uma vez escrito, não é apagado nem reescrito se deixar de
> valer depois (mudança real de código, por exemplo) — ganha uma entrada
> nova, datada, dizendo o que mudou. Igual ADR: acrescenta, não
> reescreve por cima.
>
> Cada entrada segue [a regra de escrita geral](../CONVENCOES.md#como-escrever):
> âncora explícita, campo `Confirmado por` com valor fixo, resumo
> simples, depois detalhe técnico.

## Índice
- [Achados](#achados)
- [Controle de versão](#controle-de-versão)

## Achados

### 2026-09-04-worktree-nova-nunca-via-agentes-hooks-nem-modulo-conformidade

**Confirmado por:** teste ao vivo.

*Em resumo:* uma worktree nova, criada do jeito que todo o resto do
projeto exige (`EnterWorktree`), nunca enxergava `.claude/agents`,
`.claude/hooks` nem `modulos/conformidade` -- as três pastas ficam de
propósito fora do controle de versão, e `git worktree add` só traz
conteúdo já versionado. Corrigido -- ver
[decisions/0021](<../decisions/0021-atalho-de-pasta-liga-material-local-em-toda-worktree.md>).

*Em detalhe técnico:*
- Achado dentro de uma tarefa do módulo `motor`, sessão nova, worktree
  nova: os quatro agentes de revisão de PR não apareciam na lista de
  agentes disponíveis da sessão; `.claude/agents`, `.claude/hooks` e
  `modulos/conformidade` não existiam no disco daquela worktree.
- Ao mesmo tempo, confirmado que os ganchos do evento `Stop`
  (`.claude/settings.json`, só existe na pasta principal) disparavam
  normalmente de dentro dessa mesma worktree -- um deles citou o
  horário exato do último commit, conferido contra `git log` real e
  batendo com exatidão. Ou seja, `${CLAUDE_PROJECT_DIR}` já resolvia
  certo; o problema era mais estreito (caminho relativo sem esse
  prefixo dentro de texto de gancho, e a lista de agentes nomeados,
  que parece carregar da pasta atual da sessão, não de
  `${CLAUDE_PROJECT_DIR}`).
- Raciocínio completo, alternativas descartadas e teste da correção em
  si: [decisions/0021](<../decisions/0021-atalho-de-pasta-liga-material-local-em-toda-worktree.md>).

### 2026-08-27-funcoes-novas-testadas-isoladamente

**Confirmado por:** teste ao vivo.

*Em resumo:* as três funções/lógicas novas escritas para as ADRs 0001,
0002 e 0003 funcionam como desenhado, testadas fora do fluxo real de
um gancho (sem simular uma chamada de ferramenta), rodando o código
direto contra casos concretos.

*Em detalhe técnico:*
- `first_unread_mandatory_doc` (já existente, reaproveitada pela ADR
  0001): registro vazio devolve o primeiro documento da lista;
  registro com os seis documentos devolve vazio. Testado numa pasta de
  rascunho isolada, com `CLAUDE_PROJECT_DIR` apontando pra lá, sem
  tocar no estado real da sessão.
- `paths_equal` (ADR 0002): três casos -- mesma pasta com letra de
  unidade em caixa diferente (`H:/...` vs `h:/...`, considerados
  iguais); pastas realmente diferentes (consideradas diferentes);
  barra invertida do Windows de um lado só (considerado igual ao
  caminho com barra normal). Os três bateram o esperado.
- Heurística de esquema embutido (ADR 0003, bloco `awk` dentro de
  `pre_commit_hygiene.sh`): bloco com `description` dentro de um
  esquema válido (`type`+`required`+`properties`) detectado; o mesmo
  bloco sem `description` não gerou alarme falso.

### 2026-08-27-sintaxe-e-json-validos

**Confirmado por:** teste ao vivo.

*Em resumo:* os quatro scripts alterados/criados hoje (`lib/common.sh`,
`pre_mandatory_reading_guard.sh`, `pre_commit_hygiene.sh`,
`stop_fact_check.sh`) têm sintaxe de shell válida, e `settings.json`
continua um JSON válido depois da edição.

*Em detalhe técnico:* `bash -n <arquivo>` (checagem de sintaxe sem
executar) rodado nos quatro, um de cada vez -- os quatro devolveram
código de saída 0. `jq empty settings.json` confirmou JSON bem
formado.

### 2026-08-27-restricao-de-read-testada-isoladamente

**Confirmado por:** teste ao vivo.

*Em resumo:* a correção do loophole de `Read` em
`pre_mandatory_reading_guard.sh` ([decisions/0006](<../decisions/0006-read-so-libera-os-seis-documentos-obrigatorios-enquanto-faltar-algum.md>))
funciona como desenhado, testada fora do fluxo real de um gancho (JSON
de entrada fabricado, via stdin, contra uma cópia isolada dos
scripts).

*Em detalhe técnico:* três casos, numa pasta de rascunho isolada, com
`CLAUDE_PROJECT_DIR` apontando pra lá (sem nenhum dos seis documentos
obrigatórios "lidos" ainda, `read-log.txt` vazio): `Read` de um arquivo
fora da lista de seis bloqueou (código de saída 2, mensagem nomeando o
documento faltante); `Read` de um dos seis (comparado pelo nome do
arquivo) passou (código de saída 0); `Bash` continuou bloqueado, igual
ao comportamento já existente antes desta correção -- sem regressão.
Sintaxe de todos os scripts alterados (`pre_mandatory_reading_guard.sh`,
`pre_bash_search_guard.sh`, `stop_fact_check.sh`) conferida com
`bash -n`; `.claude/settings.json` conferido com `jq empty` -- os
quatro sem erro.

### 2026-08-28-padrao-de-emoji-incluia-bloco-de-setas-tipograficas

**Confirmado por:** teste ao vivo.

*Em resumo:* o padrão de detecção de emoji continha o bloco Unicode
"Arrows" (`\x{2190}-\x{21FF}`), usado por caracteres tipográficos
comuns como "→" e "↔" -- não emoji. Esse bloco bloqueava, por engano,
qualquer commit tocando texto com essas setas, presentes o tempo todo
na prosa deste projeto (`MANUAL.md`, vários `docs/` de módulo).

*Em detalhe técnico:* achado tentando commitar o trabalho desta
sessão -- confirmado comparando o intervalo contra `emoji-data.txt` do
Unicode Consortium: `\x{2190}-\x{21FF}` é o bloco base "Arrows",
diferente de `\x{2B00}-\x{2BFF}` ("Miscellaneous Symbols and Arrows",
que inclui setas com apresentação de emoji por padrão). Padrão
corrigido em `lib/common.sh` (`EMOJI_PATTERN`): bloco de setas simples
removido, blocos de bandeira (`\x{1F1E6}-\x{1F1FF}`) e técnico diverso
(`\x{2300}-\x{23FF}`, relógio/ampulheta) acrescentados -- cobertura
mais completa, sem incluir blocos que também são pontuação comum
("Geometric Shapes", `©`/`®`/`™`). Testado isoladamente: seta simples
não aciona mais o bloqueio; emoji real, bandeira de país e símbolo de
relógio continuam acionando.

### 2026-08-28-checagens-de-emoji-esquema-licenca-e-antes-depois-no-momento-da-edicao

**Confirmado por:** teste ao vivo.

*Em resumo:* as regras "nunca usar emoji", "esquema de dado é dado
puro", "tabela de cabeçalho carrega linha de Licença" e "documento
nunca versionado não usa linguagem de antes-e-depois" (CLAUDE.md,
Regras gerais) só tinham checagem mecânica no momento do commit
(`pre_commit_hygiene.sh`) -- movidas agora pro momento da própria
edição (`pre_edit_safety.sh`, itens 9 a 12), mesmo padrão já aplicado
antes a outras seis regras nesta sessão.

*Em detalhe técnico:* quatro casos positivos (deve bloquear) e três
casos negativos (não deve bloquear), todos com JSON de entrada
fabricado via stdin, fora do fluxo real de um gancho, numa pasta de
rascunho isolada (`CLAUDE_PROJECT_DIR` apontando pra lá, síntese
pré-populada com os seis documentos obrigatórios "lidos"):
- Emoji num texto novo: bloqueou (código de saída 2). Texto sem emoji:
  passou (código de saída 0).
- Bloco `\`\`\`yaml` embutido com `required`+`type`+`description`:
  bloqueou. Esquema puro (`schemas/*.json` sem `description`/
  `example`): passou.
- Tabela `Campo | Valor` sem linha de Licença: bloqueou. A mesma
  tabela com linha de Licença: passou.
- Texto com "era assim, ficou assim" num arquivo `.md` sem nenhum
  commit no histórico (`git log` vazio pro caminho): bloqueou, citando
  o caminho do arquivo e a regra do CLAUDE.md.

### 2026-08-28-autoportao-de-pre-commit-hygiene-testado-isoladamente

**Confirmado por:** teste ao vivo.

*Em resumo:* o auto-portão acrescentado em `pre_commit_hygiene.sh`
([decisions/0011](<../decisions/0011-auto-portao-contra-falha-aberta-do-filtro-if.md>))
sai (`exit 0`) de verdade quando o comando não contém `git commit`,
testado isoladamente (chamada direta do script via stdin, fora do
fluxo real de um gancho e fora de qualquer camada de segurança da
sessão).

*Em detalhe técnico:* comando fabricado sem `git commit` mas com um
emoji embutido (caso que, antes da correção, teria disparado a
checagem de emoji da mensagem de commit) -- devolveu código de saída 0
sem nenhuma mensagem, confirmando que o auto-portão intercepta antes
de qualquer checagem interna rodar. A instrução equivalente nos dois
ganchos `agent` (revisão de commit, revisão de preview) não pôde ser
testada da mesma forma -- ver
[pitfalls.md](<pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)
e a pendência em [tasks.md](tasks.md).

### 2026-08-28-sessionstart-sem-matcher-reseta-a-ficha-na-compactacao

**Confirmado por:** teste ao vivo.

*Em resumo:* o bloco de `SessionStart` que roda `session_start_reset.sh`
não tinha `matcher`, então disparava em todo sub-evento -- inclusive
`compact` (resumo automático do histórico numa conversa longa), não só
no início/retomada/limpeza de verdade da sessão. Como
`session_start_reset.sh` apaga o registro inteiro de leitura/edição da
sessão (a ficha, `synthesis.json`), isso apagava o progresso no meio
da conversa.

*Em detalhe técnico:* reproduzido ao vivo, na mesma sessão que
descobriu o defeito: a leitura manual obrigatória (os seis documentos
da cascata V-Model) reapareceu como bloqueio, repetidas vezes, depois
de já ter sido satisfeita e confirmada mais cedo na mesma conversa --
sem nenhuma ação do lado de quem estava conduzindo a sessão que
justificasse isso. Corrigido acrescentando `"matcher":
"startup|resume|clear"` ao bloco em `.claude/settings.json` -- o
segundo bloco do array `SessionStart`, que roda `session_start_reset.sh`
e `session_start_import_check.sh`. `jq empty .claude/settings.json`
confirmou JSON bem formado depois da mudança.

### 2026-08-28-corrupcao-e-perda-de-fato-na-ficha-por-escrita-concorrente

**Confirmado por:** teste ao vivo.

*Em resumo:* independente do achado acima, um lote de leituras em
paralelo (vários `Read` na mesma resposta) truncou a ficha
(`synthesis.json`) pra 0 bytes -- e, uma vez vazia, ela nunca se
recuperava sozinha, travando a leitura manual obrigatória de forma
permanente, mesmo depois de reler os seis documentos várias vezes.

*Em detalhe técnico:* `synthesis_bump`/`synthesis_set`
(`lib/common.sh`) escreviam sempre no mesmo nome de arquivo
intermediário fixo (`"${SYNTHESIS_FILE}.tmp"`) antes de mover por cima
do arquivo real -- duas chamadas concorrentes (cada `Read` em paralelo
dispara seu próprio `post_read_track.sh`) competem pelo mesmo arquivo
intermediário, podendo truncá-lo. Uma vez truncado, `synthesis_init`
(`[[ -f "$SYNTHESIS_FILE" ]]`) só checava existência, não conteúdo --
um arquivo vazio "existe", então nunca era reconstruído. E `jq`, por
padrão, trata entrada vazia como sucesso silencioso (zero valores de
saída, sem erro nenhum) -- toda leitura seguinte lia o vazio, escrevia
o vazio de novo, num ciclo que nunca se corrigia sozinho. Confirmado
ao vivo: `.claude/hooks/state/synthesis.json` com 0 bytes, enquanto o
diário bruto (`read-log.txt`) mostrava as leituras acontecendo
normalmente -- prova de que o defeito era na ficha, não na leitura em
si.

Correção completa, com duas partes: `synthesis_init` passa a validar
conteúdo (`jq empty`), não só existência, reconstruindo do zero se o
arquivo estiver vazio ou inválido; e cada leitura+escrita da ficha
(`synthesis_bump`, `synthesis_set`) passa a rodar dentro de uma trava
baseada em `mkdir` (criar uma pasta é atômico entre processos,
inclusive no Windows), com quebra automática depois de ~5 segundos se
a trava ficar presa. A trava é necessária porque nome de arquivo
temporário único, sozinho, evita a corrupção mas não evita perda de
fato: cada processo concorrente lê o estado atual antes de escrever, e
quem termina por último apaga o que os outros escreveram nesse
meio-tempo. Teste isolado (dez chamadas concorrentes de verdade,
`&`/`wait`, numa pasta de rascunho): antes da trava, só quatro dos dez
fatos sobreviviam, mesmo sem corrupção; com a trava, os dez
sobreviveram, JSON continuou válido. `bash -n lib/common.sh` sem erro.

### 2026-08-28-autorizo-trava-disparado-por-texto-de-exemplo-citado

**Confirmado por:** teste ao vivo.

*Em resumo:* colar, na conversa, o conteúdo de um arquivo deste
projeto que continha o texto de exemplo "AUTORIZO-TRAVA: <motivo>."
(mostrando como a autorização deveria ser usada) foi suficiente pra
`user_prompt_submit.sh` registrar uma autorização de verdade -- sem
nenhuma decisão real de quem estava conduzindo a sessão.

*Em detalhe técnico:* o gancho comparava só se a mensagem continha a
palavra "AUTORIZO-TRAVA:", sem checar se havia um motivo de fato
escrito depois dela. Corrigido: o texto imediatamente depois de
"AUTORIZO-TRAVA:" é comparado contra o início do padrão do placeholder
literal ("<motivo>") -- se o texto começar assim, a autorização não é
registrada, mesmo havendo mais alguma coisa escrita depois (o restante
da frase onde o exemplo apareceu citado). Checar só o início, não o
texto inteiro, importa aqui: o texto capturado depois de
"AUTORIZO-TRAVA:" quase sempre tem algo mais depois do placeholder (o
resto da frase citada) -- exigir que o texto inteiro fosse exatamente
"<motivo>" não bloqueava esse caso real. Testado isoladamente: mensagem
citando "AUTORIZO-TRAVA: <motivo>. valeu" não autoriza; mensagem com
motivo de fato escrito autoriza normalmente. `bash -n
user_prompt_submit.sh` sem erro.

### 2026-08-28-lacuna-de-trava-mecanica-em-pitfalls-findings-decisions

**Confirmado por:** teste ao vivo.

*Em resumo:* `pitfalls.md`, `findings.md` (este arquivo) e
`decisions/` só eram checados por julgamento de IA no momento do
commit (`pre_commit_hygiene.sh`), sem nenhuma trava mecânica no
momento da própria edição -- diferente do resto do fluxo de escrita
de documentação, já movido pra esse momento em rodadas anteriores
deste módulo.

*Em detalhe técnico:* `pre_edit_safety.sh` ganha os itens 13 (achado
sem registro) e 14/15 (escolha sem ADR), que sinalizam -- nunca
travam sozinhos, porque decidir se algo revelou um achado ou envolveu
escolha real entre alternativas é julgamento de quem desenvolve, não
fato mecânico -- e destravam por uma frase de confirmação específica
(`"nada a registrar, confirmado"` ou `"sem alternativas reais,
confirmado"`, mais estreitas que `AUTORIZO-TRAVA`, resolvem só aquele
item) ou por `AUTORIZO-TRAVA`. `post_edit_track.sh` passa a registrar
na ficha quando `findings.md`, `pitfalls.md` e `decisions/*` são
tocados, pros dois itens novos consultarem.

Testado isoladamente, JSON de entrada fabricado via stdin, fora do
fluxo real de um gancho: escrever código num módulo sem `pitfalls.md`
nem `findings.md` tocados bloqueou (item 13); com a frase "nada a
registrar, confirmado" registrada, a mesma edição passou. Escrever em
`schemas/` sem nenhuma ADR nova em `decisions/` bloqueou (item 14/15);
com a frase "sem alternativas reais, confirmado" registrada, a mesma
edição passou. `bash -n pre_edit_safety.sh` e `bash -n
post_edit_track.sh` sem erro. Ver
[decisions/0013](<../decisions/0013-frescor-uniforme-de-leitura-substitui-permanencia.md>)
pra decisão de desenho relacionada (frescor uniforme de leitura).

### 2026-08-28-cascata-do-item-5-perdia-alternativa-de-schemas

**Confirmado por:** teste ao vivo.

*Em resumo:* a checagem de código do item 5 (última etapa da cascata
`concept.md` → `architecture.md` → `schemas/` → implementação) só
aceitava `architecture.md` como leitura fresca válida -- perdendo a
alternativa de `schemas/` que a checagem antiga (por edição) já tinha.
Um módulo sem pasta `schemas/` (ex.: este módulo, `conformidade`)
ficaria bloqueado sem necessidade real.

*Em detalhe técnico:* corrigido com `synthesis_any_fresh_with_prefix`
(`lib/common.sh`) -- aceita qualquer fato de leitura cuja chave comece
com o caminho da pasta `schemas/` do módulo, já que arquivo de esquema
não tem nome fixo (`synthesis_fresh` sozinha só cobre chave exata).
Escrevendo o teste isolado dessa função, uma segunda causa apareceu:
`jq` neste ambiente devolve cada linha terminada em `\r\n`, e o `\r`
sobrava no fim da chave lida num laço `while read`, fazendo a
comparação falhar sempre -- ver
[pitfalls.md](<pitfalls.md#2026-08-28-jq-devolve-linha-com-retorno-de-carro-neste-ambiente>).

Bateria de teste isolado, casos positivo e negativo pra cada ponto,
fora do fluxo real de um gancho: limite exato da janela de frescor
(idade 20 conta como fresco, idade 21 não); implementação liberada com
`architecture.md` não fresco mas um arquivo de `schemas/` fresco;
implementação bloqueada com nem um nem outro fresco; fato de
`schemas/` de um módulo (`testmod20`) não satisfaz a checagem de outro
módulo com nome parecido (`testmod2`); item 6 -- `Write` sobrescrevendo
`handoff.md` já existente sem leitura fresca bloqueou, mesmo sem
passar pelo item 1 (que só cobre `Edit`); item 7 -- mesmo teste pra
`modulos/README.md`; item 8 -- mesmo teste pra `TASKS.md` (raiz); e um
caso de falso positivo da correção do placeholder de `AUTORIZO-TRAVA`
(mensagem "AUTORIZO-TRAVA: <verificação manual: já testei isso a
mão>" -- começa com `<` mas não é o texto de exemplo -- autorizou
normalmente, sem bloquear por engano). `bash -n lib/common.sh` e
`bash -n pre_edit_safety.sh` sem erro depois da correção.

### 2026-08-28-formato-de-resposta-errado-em-todo-gancho-agent-e-prompt

**Confirmado por:** leitura de código e teste ao vivo.

*Em resumo:* os sete pontos do sistema que usavam uma segunda
inteligência artificial (seis do tipo "agent", um do tipo "prompt",
mais simples) pediam a ela uma resposta no formato de um gancho comum
(`hookSpecificOutput.permissionDecision`/`decision`) -- formato que o
Claude Code não reconhece pra esse tipo de gancho, que só entende
`{"ok": true}` ou `{"ok": false, "reason": "..."}`. Na prática, nenhum
dos sete bloqueava de verdade, mesmo quando a segunda inteligência
artificial raciocinava certo.

*Em detalhe técnico:* confirmado lendo a documentação oficial do
Claude Code direto (Hooks reference, seções "Prompt-based hooks" e
"Agent-based hooks"), não resumida por outra fonte. Corrigido nos sete
pontos -- ver
[decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>).

### 2026-08-28-modo-automatico-da-sessao-nega-ferramenta-a-gancho-agent

**Confirmado por:** teste ao vivo.

*Em resumo:* mesmo depois de corrigido o formato de resposta acima,
um gancho do tipo "agent" continuou sem conseguir usar nenhuma
ferramenta (ler arquivo, rodar comando) enquanto a sessão principal
estava com o modo automático ligado -- reproduzido de forma
independente dentro desta mesma sessão, mais de uma vez, incluindo um
caso em que um comando de teste contendo um "git commit" real disparou
o gancho de revisão de commit (ainda ativo, rodando a partir da pasta
principal do repositório) e ele bloqueou alegando falta de acesso a
ferramenta.

*Em detalhe técnico:* a documentação oficial confirma que um gancho
"agent" herda o modo de permissão da sessão que o chamou, sem campo de
configuração pra escolher um modo próprio -- se a sessão está no modo
automático, o gancho também fica. Duas checagens do fim da resposta
continuaram retornando mensagem de "modo sem perguntar bloqueou acesso
necessário" mesmo depois da correção de formato, confirmando que o
defeito tem duas causas independentes, não uma só. Ver
[decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>);
pendência de confirmar o comportamento com o modo automático desligado
em [tasks.md](tasks.md).

### 2026-08-28-checagem-mecanica-de-documentacao-antes-do-teste-tinha-dois-defeitos

**Confirmado por:** teste ao vivo.

*Em resumo:* o script novo que substitui o gancho "agent" de revisão
de início do teste no preview (`pre_preview_check.sh`) tinha dois
defeitos, achados só ao testar o código novo: usava `git diff`, que não
lista arquivo nunca registrado no controle de versão (só modificado),
deixando passar um módulo inteiro novo sem documentação; e não excluía
`docs/`/`schemas/`/`decisions/` do que conta como "código", fazendo a
própria edição do documento de conceito de um módulo disparar a
checagem contra si mesma.

*Em detalhe técnico:* corrigido trocando `git diff --name-only` por
`git status --porcelain --untracked-files=all` (cobre modificado e
novo na mesma chamada) e acrescentando o mesmo filtro
`/docs/|/schemas/|/decisions/` que `IS_CODE`, em `pre_edit_safety.sh`
item 5, já usava. Testado isoladamente: módulo com código novo
(nunca registrado) e sem documentação bloqueou; o mesmo módulo com o
documento de conceito tocado na mesma sessão liberou; módulo só com o
documento de conceito alterado, sem nenhum código, não bloqueou (não
há código exigindo documentação).

### 2026-08-28-item-16-tinha-conflito-de-opcao-do-grep-e-problema-de-locale

**Confirmado por:** teste ao vivo.

*Em resumo:* a checagem mecânica nova de tom pessoal (`pre_edit_safety.sh`,
item 16) não disparava nunca, por dois motivos empilhados: a chamada
combinava as opções `-E` e `-P` do `grep` ao mesmo tempo (`grep` recusa
essa combinação com erro); corrigido para `-P` sozinho, o padrão com
caractere acentuado (`[aá]`) ainda falhava, porque `-P` exige um
ambiente de idioneo (`locale`) UTF-8, ausente neste ambiente.

*Em detalhe técnico:* corrigido trocando pra `grep -E` (sem `-P`),
suficiente pro padrão usado (não precisa de nenhum recurso exclusivo
de `-P`) -- mesma família de problema já registrada em
[pitfalls.md](<pitfalls.md#2026-08-28-grep-p-exige-locale-utf-8-neste-ambiente>).
Testado isoladamente depois da correção: frase com tom pessoal
bloqueou; a mesma frase, depois de confirmada, liberou; frase sem tom
pessoal não bloqueou.

### 2026-08-29-sessionstart-ainda-reseta-a-ficha-no-evento-resume

**Confirmado por:** teste ao vivo.

*Em resumo:* a correção de 28-08-2026 (ver
[findings.md](<#2026-08-28-sessionstart-sem-matcher-reseta-a-ficha-na-compactacao>))
tirou o evento `compact` do gatilho que apaga a ficha, mas deixou o
evento `resume` -- e esse evento dispara sozinho, várias vezes por
hora, neste ambiente (extensão de VSCode/Claude Agent SDK), sem
nenhuma ação deliberada de quem conduz a sessão. Efeito prático igual
ao defeito já corrigido: a leitura manual obrigatória, já satisfeita
minutos antes, reaparece como bloqueio no meio do trabalho.

*Em detalhe técnico:* reproduzido ao vivo, com hora exata: os seis
documentos manuais obrigatórios foram lidos por completo às 18:46:09
a 18:46:13 (29-08-2026); `.claude/hooks/state/arquivo/
20260829T184953Z-read-log.txt` (diário arquivado por
`session_start_reset.sh`) contém exatamente essas seis leituras,
arquivadas -- ou seja, removidas do registro ativo -- às 18:49:53, três
minutos depois, sem nenhum comando `/clear` nem reinício manual da
sessão nesse meio-tempo. A tentativa seguinte de usar qualquer
ferramenta (`EnterWorktree`) bloqueou, `pre_mandatory_reading_guard.sh`
apontando o primeiro documento como não lido. Consulta à documentação
oficial (`code.claude.com/docs/en/hooks`) descreve `resume` como
disparado só por retomada explícita (`--resume`/`--continue`), não
sozinho no meio de uma sessão -- não bate com o comportamento
observado neste ambiente específico (ver
[analysis.md](<analysis.md#2026-08-29-relatorio-de-outra-sessao-e-reset-da-ficha-no-evento-resume>)
pro raciocínio completo). Corrigido separando o evento `resume` do
bloco que roda `session_start_reset.sh` em `.claude/settings.json` --
`session_start_import_check.sh` (checagem que só lê, nunca apaga nada)
continua rodando em `resume`. Ver
[decisions/0015](<../decisions/0015-sessionstart-nao-reseta-mais-a-ficha-no-evento-resume-e-janela-de-frescor-maior.md>).

### 2026-08-29-autorizo-trava-disparado-por-reticencias-em-narrativa

**Confirmado por:** teste ao vivo.

*Em resumo:* a correção de 28-08-2026 contra citação do placeholder
`<motivo>` (ver
[findings.md](<#2026-08-28-autorizo-trava-disparado-por-texto-de-exemplo-citado>))
não cobria uma variante real: uma mensagem contando, em prosa, o que
aconteceu numa sessão anterior ("...só desbloqueou quando você mesmo
escreveu AUTORIZO-TRAVA: ....") também registrava autorização de
verdade -- o "motivo" capturado era só reticências, seguido do resto
da frase da própria narrativa, sem nenhuma decisão real de quem estava
conduzindo a sessão naquele momento.

*Em detalhe técnico:* reproduzido ao vivo -- uma mensagem legítima,
descrevendo um relato recebido de outra sessão, registrou autorização
sem intenção nenhuma de autorizar algo na hora. Corrigido em
`user_prompt_submit.sh`: o texto imediatamente depois de
"AUTORIZO-TRAVA:" também é rejeitado quando começa com duas ou mais
reticências (`..`), mesmo princípio já usado pro placeholder `<motivo>`
(checar só o início do texto capturado, não o texto inteiro -- o resto
da frase, contando a história, quase sempre tem conteúdo real, então
checar "existe alguma letra em algum lugar" não bastava; testado
isoladamente e confirmado que essa primeira tentativa passava batido
antes da correção final). Testado isoladamente, cinco casos: citação
com reticências não autoriza; placeholder `<motivo>` continua sem
autorizar (regressão); motivo real autoriza normalmente; motivo
começando com `<` mas com conteúdo real continua autorizando
(regressão do achado de 28-08-2026); um único ponto no início não
bloqueia por engano. Ver
[decisions/0016](<../decisions/0016-autorizo-trava-rejeita-reticencias-sem-motivo-real.md>).

### 2026-08-29-frase-de-confirmacao-exigia-pontuacao-exata

**Confirmado por:** teste ao vivo.

*Em resumo:* as cinco frases de confirmação pontual (ex.: "commit
revisado, confirmado") exigiam a vírgula exata pra bater com o texto
digitado -- uma tentativa real, sem essa vírgula, não destravava
nada, sem nenhum aviso do motivo.

*Em detalhe técnico:* reproduzido ao vivo -- corrigido em
`user_prompt_submit.sh`, decisão registrada em
[decisions/0018](<../decisions/0018-frases-de-confirmacao-toleram-virgula-opcional.md>).
Testado isoladamente: frase sem vírgula passa a confirmar; frase com
vírgula continua confirmando (regressão); frase totalmente diferente
continua sem confirmar; `AUTORIZO-TRAVA` continua exigindo o
dois-pontos, sem regressão.

### 2026-08-28-frase-de-confirmacao-cadastrada-mas-nunca-usada

**Confirmado por:** leitura de código.

*Em resumo:* a frase "preview pronto pra testar, confirmado" foi
cadastrada na tabela de confirmações de `user_prompt_submit.sh`, mas
nenhum script chegou a checá-la -- sobra de um desenho inicial trocado
no meio da implementação, sem efeito nenhum, achada só numa auditoria
pedida explicitamente sobre o próprio trabalho desta rodada.

*Em detalhe técnico:* removida a linha da tabela. As outras cinco
frases da mesma tabela (`no-finding`, `no-adr`, `tom-impessoal`,
`sem-duplicacao`, `commit-revisado`) confirmadas, uma a uma, como
realmente lidas por `confirmation_confirmed` em `pre_edit_safety.sh`
ou `pre_commit_hygiene.sh`.

### 2026-08-29-pre-commit-nunca-detectava-versao-subida-em-documento-so-com-changelog

**Confirmado por:** teste ao vivo.

*Em resumo:* o gancho nativo do git `scripts/hooks/pre-commit` --
fora de `.claude/hooks/`, escrito antes deste módulo existir -- nunca
reconhecia uma subida de versão de verdade em documento que não tem
tabela de cabeçalho "Campo | Valor" (caso de `MANUAL.md`), só a tabela
"Controle de versão". Um documento assim, mesmo subindo a versão
corretamente, ficava bloqueado pra sempre nesse gancho.

*Em detalhe técnico:* achado tentando commitar `MANUAL.md` e
`FRASES-DE-CONFIRMACAO.md` (documento novo) nesta mesma rodada.
Correção, alternativas descartadas e bateria de teste completas em
[decisions/0019](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>).

## Controle de versão

| Versão | Data | Alteração | Origem da alteração |
|---|---|---|---|
| 0.1.0 | 27-08-2026 | Criação inicial -- dois achados registrados. | Criação inicial do módulo |
| 0.2.0 | 27-08-2026 | Achado novo registrado (teste isolado da restrição de Read). | Segunda rodada de correção do sistema de conformidade |
| 0.3.0 | 28-08-2026 | Dois achados novos registrados (checagens de emoji/esquema/licença/antes-depois no momento da edição; auto-portão de pre_commit_hygiene.sh). | Correção da falha aberta do filtro `if` |
| 0.4.0 | 28-08-2026 | Achado novo registrado (teste isolado da ficha/síntese e de session_start_reset.sh), retroativo a trabalho já feito nesta sessão sem registro. | Fechamento da lacuna de documentação da ficha/síntese (decisions/0012) |
| 0.5.0 | 28-08-2026 | Achado novo registrado (padrão de emoji incluía bloco de setas tipográficas, bloqueando commit legítimo). | Correção do padrão de emoji em lib/common.sh |
| 0.6.0 | 28-08-2026 | Quatro achados novos registrados, todos testados isoladamente antes do commit: reset indevido da ficha na compactação, corrupção e perda de fato na ficha por escrita concorrente, AUTORIZO-TRAVA disparado por texto de exemplo citado, e a lacuna de trava mecânica em pitfalls/findings/decisions. | Correção do bloqueio real dos ganchos de conformidade |
| 0.7.0 | 28-08-2026 | Achado novo registrado (item 5 perdia a alternativa de `schemas/`, revelado numa segunda rodada de teste mais rigorosa, cobrindo limite exato da janela, isolamento entre módulos, itens 6/7/8 e falso positivo do placeholder). | Correção do bloqueio real dos ganchos de conformidade |
| 0.8.0 | 28-08-2026 | Cinco achados novos registrados: formato de resposta errado em todo gancho `agent`/`prompt`; modo automático da sessão nega ferramenta a gancho `agent`, mesmo com formato corrigido; dois defeitos reais na checagem nova de documentação-antes-do-teste; conflito de opção e problema de locale do `grep` na checagem nova de tom pessoal; frase de confirmação cadastrada mas nunca usada. | Resolução de [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>) |
| 0.9.0 | 29-08-2026 | Dois achados novos registrados: `SessionStart` ainda reseta a ficha no evento `resume` (correção de 28-08-2026 cobriu só `compact`); `AUTORIZO-TRAVA` disparado por reticências numa narrativa, variante não coberta pela correção de 28-08-2026 contra o placeholder `<motivo>`. | Correção de falsos bloqueios reportados de outra sessão + pedido de janela de frescor maior |
| 0.10.0 | 29-08-2026 | Achado novo registrado: frases de confirmação exigiam pontuação exata (vírgula), sem aviso de quase-acerto quando faltava. | Correção de falsos bloqueios reportados de outra sessão + pedido de janela de frescor maior |
| 0.11.0 | 29-08-2026 | Achado novo registrado: `scripts/hooks/pre-commit` nunca detectava subida de versão de verdade em documento só com a tabela "Controle de versão", sem tabela de cabeçalho. | Resolução de [decisions/0019](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>) |
| 0.12.0 | 04-09-2026 | Achado novo registrado: worktree nova nunca via `.claude/agents`, `.claude/hooks` nem `modulos/conformidade`, por ficarem fora do controle de versão. | Resolução de [decisions/0021](<../decisions/0021-atalho-de-pasta-liga-material-local-em-toda-worktree.md>) |
