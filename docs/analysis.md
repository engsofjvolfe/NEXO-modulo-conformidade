# Analysis — Conformidade

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Analysis |
| Versão | 0.4.0 |
| Data | 29-08-2026 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

> Registro datado de como uma investigação foi feita neste módulo — o
> que foi lido, o que foi checado, o raciocínio seguido. Acontece junto
> com `findings.md`, não numa etapa depois — é o relato de como se
> chegou a cada achado. É o único lugar onde narrativa de processo é
> esperada.
>
> Cada entrada segue [a regra de escrita geral](../CONVENCOES.md#como-escrever):
> âncora explícita, campo `Levou a` com link pro achado gerado (ou
> `ainda sem conclusão`), resumo simples, depois detalhe técnico.

## Índice
- [Investigações](#investigacoes)
- [Controle de versão](#controle-de-versão)

## Investigações

### 2026-08-29-relatorio-de-outra-sessao-e-reset-da-ficha-no-evento-resume

**Levou a:**
[decisions/0015](<../decisions/0015-sessionstart-nao-reseta-mais-a-ficha-no-evento-resume-e-janela-de-frescor-maior.md>),
[decisions/0016](<../decisions/0016-autorizo-trava-rejeita-reticencias-sem-motivo-real.md>),
[decisions/0017](<../decisions/0017-comandos-git-gh-isentos-da-leitura-manual-obrigatoria.md>),
[findings.md](findings.md).

*Em resumo:* uma sessão anterior relatou, em texto, três suspeitas de
falso bloqueio nos ganchos deste módulo (regra de `develop` disparando
fora de contexto; um gancho reagindo ao texto de um comando em vez de
sua execução real; a frase de confirmação nunca destravando). A
investigação desta rodada não conseguiu reproduzir as duas primeiras
ao vivo, mas reproduziu, ao vivo e por acidente, um problema real e
diferente: o próprio ato de investigar disparou de novo o defeito já
corrigido em 28-08-2026 (`session_start_reset.sh` apagando a ficha fora
de hora) -- prova de que a correção anterior era incompleta.

*Em detalhe técnico:*

1. Relato recebido, em texto, de outra sessão: (a) `pre_git_rules.sh`
   bloqueou um commit legítimo, numa worktree de tarefa, achando que a
   branch ativa era `develop` -- a outra sessão já tinha confirmado
   manualmente, com `git branch --show-current`, que a branch real
   era outra; causa exata não encontrada por ela; (b) um comando de
   diagnóstico sem nenhum `git commit` de verdade disparou
   `pre_commit_hygiene.sh` mesmo assim; (c) a frase de confirmação
   "commit revisado, confirmado" não destravou em três tentativas
   seguidas, só `AUTORIZO-TRAVA` resolveu.
2. Sobre (b): lendo o código atual de `pre_commit_hygiene.sh`, o
   auto-portão que intercepta exatamente esse caso já existe
   ([decisions/0011](<../decisions/0011-auto-portao-contra-falha-aberta-do-filtro-if.md>),
   28-08-2026) -- o relato da outra sessão provavelmente aconteceu
   antes dessa correção estar em vigor, ou numa execução em que o
   filtro `if` do Claude Code falhou aberto por outro motivo (mesma
   armadilha já documentada em
   [pitfalls.md](<pitfalls.md#2026-08-28-filtro-if-falha-aberto-em-comando-nao-parseavel>)).
   Sem evidência nova pra investigar mais fundo agora; nenhuma mudança
   de código feita neste ponto nesta rodada.
3. Sobre (a): sem reprodução ao vivo possível nesta rodada (a sessão
   estava, neste momento, na pasta principal, não numa worktree de
   tarefa, até o passo 6 abaixo) -- fica registrado como pendência,
   a testar de verdade no momento real de commitar o trabalho desta
   própria rodada (ver tasks.md).
4. Ao tentar ler os seis documentos manuais obrigatórios (primeiro
   passo desta sessão, exigido pelo `CLAUDE.md`), o gancho
   `pre_mandatory_reading_guard.sh` bloqueou `EnterWorktree` alegando
   que o primeiro documento não tinha sido lido -- mesmo os seis
   tendo acabado de ser lidos por completo, com conteúdo retornado.
   Confirmado, por leitura repetida do mesmo documento, que o
   problema não era esquecimento: o bloqueio persistia mesmo
   imediatamente depois de reler.
5. Inspeção direta do estado gravado em disco
   (`.claude/hooks/state/synthesis.json`, `read-log.txt`, e a pasta
   `arquivo/` de diários arquivados) confirmou a causa: um arquivo
   arquivado, `arquivo/20260829T184953Z-read-log.txt`, contém as seis
   leituras (18:46:09 a 18:46:13) que tinham acabado de acontecer --
   arquivadas (ou seja, apagadas do registro ativo) três minutos
   depois, às 18:49:53, por `session_start_reset.sh`. Isso só acontece
   quando o evento `SessionStart` dispara de novo com o `matcher`
   `startup`, `resume` ou `clear` -- e nenhum desses três foi uma ação
   deliberada, nem minha nem de quem conduz a sessão, no meio desta
   conversa.
6. Consulta direta à documentação oficial do Claude Code
   (`code.claude.com/docs/en/hooks`, via ferramenta de busca na
   internet) sobre o significado exato de cada valor de `matcher` do
   evento `SessionStart`: `resume` é descrito como disparando só
   quando alguém pede explicitamente pra retomar uma sessão salva
   (`--resume`/`--continue`), não sozinho no meio de uma sessão em
   andamento -- ao contrário do que a pasta `arquivo/` mostrou
   acontecendo de verdade, várias vezes, só nas últimas horas do dia
   29-08-2026. A documentação consultada cobre a ferramenta de linha
   de comando; este ambiente específico (extensão de VSCode, via
   Claude Agent SDK) tem seu próprio ciclo de vida de sessão, que pode
   recarregar/reconectar o processo por trás das cenas de um jeito que
   a documentação genérica não cobre em detalhe -- a evidência ao vivo
   (arquivo arquivado, com hora exata, e uma repetição do conteúdo
   completo do `CLAUDE.md` reaparecendo no meio da conversa, no mesmo
   formato de início de sessão) pesa mais, aqui, que a suposição de
   que "resume" só é manual.
7. Pedido explícito de quem conduz a sessão: manter a exigência de
   leitura obrigatória (não removê-la), mas alongar bastante a janela
   de validade dela, pra aguentar uma sessão longa sem expirar à toa;
   e, à parte, remover a exigência de leitura prévia especificamente
   nos comandos de `git`/`gh` (commit, push, pull, abrir PR, etc.) --
   com a ressalva de que qualquer liberação de bloqueio, fora dessa
   isenção permanente e já decidida em texto, continua exigindo
   `AUTORIZO-TRAVA` digitado pela própria pessoa, nunca decidido
   sozinho.
8. Enquanto testava a isenção de `git`/`gh` isoladamente (JSON de
   entrada fabricado, numa pasta de rascunho), o primeiro teste
   passou batido -- investigação revelou que a variável usada pra
   guardar o comando (`BASH_COMMAND`) tem o mesmo nome de uma variável
   especial do próprio Bash, atualizada sozinha a cada comando
   executado, que sobrescrevia o valor antes do `grep` seguinte rodar.
   Corrigido renomeando pra `COMMAND` (mesmo nome já usado nos outros
   dois ganchos de git deste módulo).
9. Enquanto testava a correção do `AUTORIZO-TRAVA` (item 7), uma
   primeira tentativa (exigir 4 letras em qualquer lugar do texto
   capturado) não bastou -- teste isolado confirmou que o resto da
   frase, contando a história de outra sessão, quase sempre tem letras
   de sobra, então quase nunca rejeitava nada de verdade. Corrigida
   pra checar só o início do texto capturado (reticências logo depois
   de "AUTORIZO-TRAVA:", antes de qualquer letra), mesmo princípio já
   usado pro placeholder `<motivo>`. As duas regressões conhecidas
   (placeholder `<motivo>`; motivo real começando com `<`, do achado de
   28-08-2026) testadas de novo depois da correção, sem quebrar.
10. Uma tentativa de editar `.claude/settings.json` (separar o evento
    `resume` do script que apaga a ficha) foi bloqueada por uma camada
    de segurança do próprio Claude Code (classificador de "modo
    automático"), que identificou a mudança como automodificação do
    próprio mecanismo de supervisão e pediu confirmação explícita de
    quem conduz a sessão antes de prosseguir -- pergunta feita, resposta
    ainda pendente no momento em que esta entrada foi escrita.

### 2026-08-27-cobertura-do-sistema-de-ganchos-contra-o-claude-md

**Levou a:**
[decisions/0001](<../decisions/0001-cobertura-do-gancho-de-leitura-obrigatoria.md>),
[decisions/0002](<../decisions/0002-comparacao-de-caminho-ignora-maiuscula-e-minuscula.md>),
[decisions/0003](<../decisions/0003-deteccao-de-esquema-embutido-em-documento.md>),
[decisions/0004](<../decisions/0004-checagem-de-instrucoes-do-usuario-no-gancho-de-stop-existente.md>),
[findings.md](findings.md),
[pitfalls.md](pitfalls.md).

*Em resumo:* uma sessão que começou investigando o estado de uma
worktree acabou revelando que a leitura manual obrigatória do
`CLAUDE.md` tinha sido pulada antes de qualquer outra ação -- gatilho
pra checar se o próprio sistema de ganchos deveria ter impedido isso.
Não deveria: o gancho existente só cobre "antes de código", não "antes
de qualquer outra coisa" (texto literal do `CLAUDE.md`). Investigação
ampliada, a pedido direto, pra cobrir o sistema inteiro: reler cada
gancho já existente (pra não duplicar nada), pesquisar a documentação
oficial do Claude Code sobre a sintaxe de `matcher`, e fechar as
lacunas encontradas.

*Em detalhe técnico:*

1. Sessão pedia "investigar o estado da worktree aberta" -- antes de
   qualquer investigação, os seis documentos de leitura manual
   obrigatória (cascata VMODEL + `prompt model.txt`) deveriam ter sido
   lidos; não foram. Apontado diretamente.
2. Os seis documentos lidos por completo. Pergunta seguinte, direta:
   por que nenhum gancho bloqueou a investigação antes dessa leitura?
3. Leitura completa de `MANUAL.md` e de todo script em
   `.claude/hooks/` (nove scripts + `lib/common.sh`), confirmando que
   nenhum duplicava o que seria escrito -- só depois disso, qualquer
   edição.
4. Achado: `first_unread_mandatory_doc` (a função que checa os seis
   documentos) só era chamada dentro de `pre_edit_safety.sh` (antes de
   escrever/editar) e `pre_commit_hygiene.sh` (antes do commit) --
   nunca antes de `Bash`, `Read` avulso, `Grep`, `Glob`, ou qualquer
   outra ferramenta de investigação.
5. Pesquisa direta na documentação oficial do Claude Code (não por
   suposição) sobre o campo `matcher` de um gancho `PreToolUse`:
   confirmado que `"*"`/vazio/omitido cobre toda ferramenta, que
   `tool_name` sempre chega no JSON de entrada independente do
   matcher, que múltiplos ganchos coexistem no mesmo evento, e que não
   existe sintaxe de negação (`"todas menos X"`) -- a forma correta é
   matcher amplo + filtro dentro do próprio script, o mesmo padrão que
   os ganchos já existentes deste projeto já usavam.
6. Gancho novo (`pre_mandatory_reading_guard.sh`) desenhado e escrito
   com essa base -- ver decisions/0001.
7. Durante essa varredura, três lacunas a mais encontradas por leitura
   direta: bug de comparação de caminho maiúscula/minúscula em
   `stop_fact_check.sh` (achado ao ver, na própria resposta do gancho,
   a pasta principal listada por engano como "worktree esquecida");
   checagem de esquema puro nunca cobrindo esquema embutido em
   documento fora de `schemas/*.json` (achado relendo a regra geral do
   `CLAUDE.md` contra o código real da checagem); e nenhum mecanismo
   conferindo se instrução do usuário, dada numa tarefa detalhada,
   ficou sem atender (pedido direto). As três viraram decisions/0002,
   0003 e 0004.
8. Tentativa de testar os ganchos simulando uma chamada de ferramenta
   (JSON fabricado, imitando `PreToolUse`) foi barrada por uma camada
   de supervisão própria desta sessão, tratando esse tipo de simulação
   como caso que merece mais cautela. Ajuste de método: testar a
   lógica interna direto (funções de `lib/common.sh`, chamadas de
   dentro de uma pasta de rascunho isolada, sem simular entrada de
   ferramenta) -- resultado em `findings.md`. Confirmação de ponta a
   ponta, com o gancho de verdade bloqueando uma chamada real, não foi
   possível dentro da mesma sessão -- ver pitfalls.md.
9. Pergunta levantada, no meio do trabalho: onde esse sistema deveria
   morar na documentação do projeto? Não havia módulo formal em
   `modulos/` pra ele -- só `MANUAL.md`, solto na raiz, sem
   `decisions/`, `tasks.md` ou `findings.md` próprios. Três caminhos
   apresentados; escolhido formalizar como módulo (`modulos/conformidade/`),
   com `MANUAL.md` continuando como fonte normativa (mesmo papel que a
   cascata VMODEL cumpre pro módulo `motor`), e as quatro decisões
   acima registradas retroativamente como as primeiras ADRs do módulo
   novo.

### 2026-08-28-falha-aberta-do-filtro-if-e-ganchos-que-nunca-parecem-rodar

**Levou a:**
[decisions/0011](<../decisions/0011-auto-portao-contra-falha-aberta-do-filtro-if.md>),
[findings.md](findings.md),
[pitfalls.md](pitfalls.md).

*Em resumo:* testando a checagem de emoji recém-movida pro momento da
edição, um comando de teste (sem nenhum "git commit") disparou o
bloqueio de emoji de `pre_commit_hygiene.sh` -- gancho que só deveria
rodar em `git commit`. Investigação disso revelou um mecanismo real,
oficial, e corrigível (a falha aberta do filtro `if`), e separou dele
uma segunda observação, mais incerta, sobre ganchos que parecem nunca
executar de verdade nesta sessão.

*Em detalhe técnico:*

1. Reprodução isolada, fora do fluxo real de um gancho: um comando
   Bash trivial, de uma linha, sem emoji e sem `git commit`, não
   disparou nada -- comportamento correto. O mesmo comando com um
   emoji, ainda sem `git commit`, também não disparou nada quando
   testado como comando trivial de uma linha. Só um comando composto,
   de múltiplas linhas, com aspas aninhadas (construindo um JSON de
   teste), disparou o bloqueio de `pre_commit_hygiene.sh` de forma
   repetível.
2. Consulta direta à documentação oficial
   (`code.claude.com/docs/en/hooks`) sobre o campo `if`: confirma que
   ele usa a mesma sintaxe de regra de permissão, e que "the filter
   also fails open, running your hook regardless of pattern, when the
   Bash command can't be parsed" -- exatamente o padrão reproduzido no
   passo 1 (comando composto, aspas aninhadas, difícil de parsear).
3. Corrigido via [decisions/0011](<../decisions/0011-auto-portao-contra-falha-aberta-do-filtro-if.md>):
   auto-portão dentro do próprio script/prompt de cada gancho que usa
   `if` sobre o matcher `Bash`, checando o padrão de novo, sem
   depender só do `if`.
4. Tentativa de confirmar a correção ao vivo (mesmo comando de teste,
   depois da correção salva em disco) reproduziu o mesmo bloqueio,
   com a mesma mensagem exata de antes da correção -- o que não bate
   com "o `if` falhou aberto e o script rodou até o fim", porque o
   script corrigido deveria ter saído mais cedo. Teste decisivo: um
   marcador de diagnóstico (uma linha `echo` gravando num arquivo de
   log, sem bloquear nada) foi acrescentado no topo de
   `pre_commit_hygiene.sh`, e removido depois. Nenhuma chamada de
   ferramenta durante essa checagem -- nem as que supostamente
   dispararam o bloqueio -- deixou esse marcador no arquivo de log.
5. Checagem adicional: `edit-order.log`, escrito por
   `post_edit_track.sh` (gancho `PostToolUse`, matcher `Write|Edit`,
   sem `if` nenhum -- não sujeito à falha do passo 2) a cada edição
   real, não existe em disco, apesar de dezenas de edições reais nesta
   mesma sessão.
6. Conclusão possível, mas não certeza: os dois achados acima (nenhum
   marcador de diagnóstico gravado, `edit-order.log` nunca criado)
   sugerem que os ganchos configurados em `settings.json` podem não
   ter rodado de verdade em nenhum momento desta sessão -- reforçando,
   com uma evidência mais direta, a armadilha já registrada em
   [pitfalls.md](<pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)
   (configuração de gancho não recarrega na mesma sessão que a edita).
   As mensagens de bloqueio recebidas ao vivo durante esta sessão
   (formato "PreToolUse:Bash hook error: [...]", e também "Agent hook
   condition was not met: ...") não puderam, portanto, ser atribuídas
   com certeza aos scripts reais deste módulo -- podem vir de uma
   camada de segurança separada (o classificador do "Auto Mode",
   mencionado em erro à parte nesta mesma sessão: "claude-sonnet-5 is
   temporarily unavailable, so auto mode cannot determine the
   safety..."), que aparenta ler o conteúdo dos scripts de gancho (as
   mensagens citam texto real de `block()`) sem necessariamente
   executá-los. Sem fonte oficial que confirme isso por escrito --
   registrado só pela observação direta, ao vivo, nesta sessão, com a
   incerteza explícita. Não muda a correção do item 3 (o auto-portão é
   correto e vale independente da causa exata do sintoma que motivou
   procurá-lo), só a certeza sobre O QUE, exatamente, bloqueou os
   comandos de teste vistos ao vivo nesta sessão.

### 2026-08-29-varredura-de-documentos-sem-tabela-de-cabecalho-com-versao

**Levou a:**
[decisions/0019](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>),
[findings.md](findings.md).

*Em resumo:* depois de corrigir o ponto cego de `scripts/hooks/pre-commit`
achado em `MANUAL.md`, checado se algum outro documento do projeto
tinha o mesmo problema -- pedido direto de quem conduz a sessão.

*Em detalhe técnico:* busca por `## Controle de versão` no projeto
inteiro (`*.md`) devolveu 29 documentos. Busca seguinte, por
`\| Versão \|` nos mesmos arquivos, bateu nos 29 -- resultado esperado
e inútil por si só, já que essa string aparece igual na linha de
título da própria tabela de changelog (`| Versão | Data | Alteração |
Origem da alteração |`), presente em todo documento com essa tabela,
tenha ele tabela de cabeçalho ou não. Distinção real feita por leitura
direta de cada candidato restante depois de descartar os já conhecidos
pelo padrão do molde (`modulos/_template/`): documento nascido desse
molde, e todo documento da cascata VMODEL, tem uma tabela de
cabeçalho própria ("Campo | Valor") com uma linha de dois campos
`| Versão | X.Y.Z |` -- essa linha muda de valor a cada subida de
versão, e por isso já era detectada pela condição original do gancho.
Só `MANUAL.md` (sem tabela de cabeçalho nenhuma) e
`FRASES-DE-CONFIRMACAO.md` (tabela de cabeçalho existe, mas só com a
linha de Licença, sem campo "Versão") dependiam exclusivamente da
tabela de changelog -- os dois já cobertos pela correção de
[decisions/0019](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>).

## Controle de versão

| Versão | Data | Alteração | Origem da alteração |
|---|---|---|---|
| 0.1.0 | 27-08-2026 | Criação inicial -- uma investigação registrada. | Criação inicial do módulo |
| 0.2.0 | 28-08-2026 | Investigação nova registrada (falha aberta do filtro `if`, e observação separada sobre ganchos que parecem nunca rodar nesta sessão). | Teste isolado das checagens de emoji/esquema/licença/antes-e-depois movidas pro momento da edição |
| 0.3.0 | 29-08-2026 | Investigação nova registrada (relato de outra sessão sobre falsos bloqueios; reprodução ao vivo do reset indevido da ficha no evento `resume`, com evidência em disco; correção da leitura obrigatória e do `AUTORIZO-TRAVA`; isenção de comandos `git`/`gh`). | Correção de falsos bloqueios reportados de outra sessão + pedido de janela de frescor maior |
| 0.4.0 | 29-08-2026 | Investigação nova registrada (varredura dos 29 documentos do projeto com tabela "Controle de versão", pra achar quais dependiam do mesmo ponto cego do `pre-commit` achado em `MANUAL.md`). | Resolução de [decisions/0019](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>) |
