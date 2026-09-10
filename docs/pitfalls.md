# Pitfalls — Conformidade

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Pitfalls |
| Versão | 0.7.0 |
| Data | 07-09-2026 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

> Comportamento não óbvio de ferramenta/mecanismo usado só neste módulo
> — pra não redescobrir o mesmo problema depois. Registrado conforme
> aparece, tipicamente durante a implementação (quando o código encontra
> o comportamento real de ferramenta/ambiente). Raramente muda; se mudar
> (versão nova de dependência, por exemplo), mesma regra de
> `findings.md`: entrada nova, não reescrita.
>
> Cada entrada segue [a regra de escrita geral](../CONVENCOES.md#como-escrever):
> âncora explícita, resumo simples, depois detalhe técnico.

## Índice
- [Armadilhas](#armadilhas)
- [Controle de versão](#controle-de-versão)

## Armadilhas

### 2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao

*Em resumo:* uma correção salva em disco, dentro de um script de
gancho, não passa a valer imediatamente pra sessão que está com esse
arquivo aberto -- a configuração de ganchos (`settings.json` e o
conteúdo dos scripts que ela liga) parece ser carregada uma vez, no
início da sessão, não recarregada a cada chamada de ferramenta.

*Em detalhe técnico:* depois de corrigir `stop_fact_check.sh` (ver
[decisions/0002](<../decisions/0002-comparacao-de-caminho-ignora-maiuscula-e-minuscula.md>))
numa worktree criada no meio da sessão, o aviso de "worktree já
mesclada" continuou aparecendo pra pasta principal no formato antigo
(sem a correção), em respostas seguintes da mesma sessão -- mesmo com
o arquivo corrigido já salvo em disco, no caminho que
`${CLAUDE_PROJECT_DIR}` deveria apontar. Consequência prática:
qualquer mudança em `.claude/hooks/`/`settings.json` só é confirmável
de ponta a ponta numa sessão nova, começada depois da mudança já estar
no lugar onde essa sessão nova vai rodar (por exemplo, depois do merge
em `develop`) -- nunca na mesma sessão que fez a mudança. Nenhuma fonte
oficial consultada confirma esse comportamento por escrito -- registrado
aqui só pela observação direta, ao vivo, nesta sessão.

### 2026-08-28-filtro-if-falha-aberto-em-comando-nao-parseavel

*Em resumo:* o campo `if` de um gancho `PreToolUse`/`PostToolUse`
sobre o matcher `Bash` (ex.: `"if": "Bash(git commit *)"`) não
restringe com garantia quando o comando é composto, com aspas
aninhadas ou heredoc -- nesses casos, documentação oficial confirma
que o filtro roda o gancho mesmo sem o padrão bater ("fails open").
Um teste envolvendo JSON fabricado com aspas aninhadas (padrão comum
ao testar os próprios ganchos deste módulo) é exatamente o tipo de
comando que dispara essa falha.

*Em detalhe técnico:* fonte oficial,
`code.claude.com/docs/en/hooks`: "the filter also fails open, running
your hook regardless of pattern, when the Bash command can't be
parsed". Mitigação adotada:
[decisions/0011](<../decisions/0011-auto-portao-contra-falha-aberta-do-filtro-if.md>)
-- cada gancho que depende de `if` sobre `Bash` confirma o próprio
padrão de novo, no início do script/prompt, sem depender só do `if`.

### 2026-08-28-mensagem-de-bloqueio-ao-vivo-nao-prova-execucao-real-do-gancho

*Em resumo:* uma mensagem de bloqueio recebida ao vivo, durante uma
chamada de ferramenta (formato "PreToolUse:Bash hook error: [...]" ou
"Agent hook condition was not met: ..."), mesmo citando o caminho de
um script real e um texto de `block()` que só existe nesse script, não
é prova, sozinha, de que aquele script rodou de verdade -- pode vir de
uma camada de segurança separada (o classificador do "Auto Mode") que
aparenta ler o conteúdo do script sem executá-lo. A forma de checar
com confiança: um marcador de gravação (log/arquivo de estado) que só
existe se o script realmente rodou até aquele ponto -- não a palavra
da mensagem em si.

*Em detalhe técnico:* achado ao investigar por que uma correção salva
em `pre_commit_hygiene.sh` não parecia valer, mesmo depois de
confirmada em disco -- ver
[analysis.md](<analysis.md#2026-08-28-falha-aberta-do-filtro-if-e-ganchos-que-nunca-parecem-rodar>).
Sem fonte oficial que confirme isso por escrito -- registrado só pela
observação direta, ao vivo, nesta sessão, com a incerteza sobre a
causa exata explícita na entrada de `analysis.md` correspondente.

### 2026-08-28-jq-devolve-linha-com-retorno-de-carro-neste-ambiente

*Em resumo:* `jq -r` (modo texto puro, sem aspas) devolve cada linha
terminada em `\r\n`, não só `\n`, neste ambiente (Windows/Git Bash) --
lida com `while IFS= read -r linha; do ...; done < <(jq ...)`, o `\r`
sobra no fim de `$linha`, comparação contra uma chave sem esse
caractere sempre falha (parecem iguais na tela, mas são strings
diferentes de verdade).

*Em detalhe técnico:* achado escrevendo `synthesis_any_fresh_with_prefix`
(`lib/common.sh`, decisions/0013) -- a chave lida dentro do laço nunca
batia contra `.fatos[$k]`, mesmo sendo visualmente idêntica à chave
gravada. `xxd` no valor confirmou o byte `0d` (`\r`) sobrando no fim.
`read -r` só corta o `\n` final, nunca um `\r` que sobrar antes dele.
Mitigação: cortar `\r` explicitamente depois do `read`
(`chave="${chave%$'\r'}"`) em qualquer laço que consome saída de `jq`
linha a linha neste projeto. Funções que só capturam um valor único
via `$(...)` (a maioria do resto de `lib/common.sh`) não são afetadas
-- o problema é específico de laço linha a linha sobre múltiplas
linhas de saída.

### 2026-08-28-grep-p-exige-locale-utf-8-neste-ambiente

*Em resumo:* `grep -P` (modo de expressão regular mais completo) falha
em silêncio -- ou com erro explícito de locale -- ao usar um caractere
fora do intervalo básico (ex.: `á`, `ó`) neste ambiente (Windows/Git
Bash), porque `-P` exige um ambiente de idioma (`locale`) UTF-8, que
não está configurado por padrão aqui. Também não é possível combinar
`-E` e `-P` na mesma chamada -- `grep` recusa com erro.

*Em detalhe técnico:* achado escrevendo a checagem de tom pessoal em
`pre_edit_safety.sh` (item 16) -- um padrão com `[aá]`/`[oó]` sob `-P`
devolvia "grep: -P supports only unibyte and UTF-8 locales" neste
ambiente. Mitigação: usar `-E` (expressão regular estendida, POSIX) em
vez de `-P` sempre que o padrão não precisar de nenhum recurso
exclusivo de `-P` (como os grupos de caractere acentuado usados aqui,
que `-E` já cobre sem problema) -- evita o problema de locale por
completo, em vez de forçar a variável de ambiente como já feito para
emoji (`LC_ALL=C.UTF-8`, ver `has_emoji` em `lib/common.sh`).

### 2026-08-29-nome-de-variavel-colide-com-variavel-especial-do-bash

*Em resumo:* uma variável chamada `BASH_COMMAND`, dentro de um script
de gancho, nunca guarda o valor atribuído a ela -- `BASH_COMMAND` é o
nome de uma variável especial do próprio Bash, atualizada sozinha, sem
aviso, a cada comando executado (existe pra uso em armadilhas de
depuração). Qualquer atribuição própria a esse nome é sobrescrita
assim que o próximo comando começa a rodar, inclusive o comando
seguinte que tentaria usar o valor atribuído.

*Em detalhe técnico:* achado escrevendo a isenção de leitura
obrigatória pra comandos `git`/`gh` em `pre_mandatory_reading_guard.sh`
-- `BASH_COMMAND=$(field '.tool_input.command')` seguido de
`echo "$BASH_COMMAND" | grep ...` nunca via o comando real; `bash -x`
confirmou que, no momento em que o `echo` roda, `$BASH_COMMAND` já
tinha sido reescrito pelo próprio Bash com o texto-fonte do comando
`echo` que estava prestes a rodar (efeito colateral autorreferente).
Mitigação: nunca nomear variável própria igual a uma variável especial
do Bash (`BASH_COMMAND`, `BASH_SUBSHELL`, `PIPESTATUS`, `RANDOM`, entre
outras) -- os demais ganchos de git deste módulo (`pre_git_rules.sh`,
`pre_commit_hygiene.sh`) já usavam o nome `COMMAND`, sem colisão;
mesmo nome adotado aqui.

### 2026-08-29-core-hookspath-aponta-pra-pasta-principal-nao-pra-worktree

*Em resumo:* este repositório configura `core.hooksPath` apontando
pra pasta principal (`scripts/hooks/` fora de qualquer worktree) --
editar um gancho nativo do git (`scripts/hooks/pre-commit`, por
exemplo) dentro de uma worktree de tarefa não muda o gancho que roda
de verdade ali. Um `git commit` real, na própria worktree, continua
usando a versão antiga, sem a correção, até a tarefa ser mesclada em
`develop` e a pasta principal atualizada.

*Em detalhe técnico:* confirmado com `git config --get core.hooksPath`
(devolveu o caminho absoluto da pasta principal) e
`git rev-parse --git-common-dir` (mesmo `.git` compartilhado entre
worktrees). Achado tentando confirmar ao vivo, com um `git commit` de
verdade, a correção de
[decisions/0019](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>)
-- o commit continuou bloqueado com a mensagem antiga, mesmo com a
correção já salva em disco na worktree, e com a mesma correção já
validada, momentos antes, num repositório de rascunho isolado.
Mitigação usada: `--no-verify` nesse commit específico, autorizado
explicitamente pelo usuário -- a validação de verdade, num repositório
de teste separado (fora da worktree e fora da pasta principal), é o
caminho que já funciona pra confirmar um gancho nativo de git antes de
ele estar disponível pra pasta principal de verdade.

### 2026-09-07-arquivos-do-modulo-somem-do-disco-junto-com-a-remocao-do-remoto

*Em resumo:* tirar este módulo do controle de versão remoto (commit
`3277638`, "Retira o modulo de conformidade e ferramentas internas do
repositorio remoto") não deixou os arquivos no disco, gitignorados --
apagou os 28 arquivos de verdade da árvore de trabalho, porque a
remoção foi feita como exclusão normal de arquivo rastreado (`git rm`
implícito num commit), não como "parar de rastrear, mantendo o
arquivo" (`git rm --cached`). Uma sessão que confia só no que existe
em disco, sem checar o histórico do git antes de concluir que um
arquivo "nunca existiu" ou "foi perdido de vez", recria do zero algo
que já existia por completo -- exatamente o que aconteceu com este
`tasks.md` (recriado na versão `0.1.0`, quando a versão real já estava
em `0.10.0`, com nove versões de pendências e resoluções perdidas até
a recuperação).

*Em detalhe técnico:* os 28 arquivos de `modulos/conformidade/` (sete
de `docs/`, vinte de `decisions/` mais o índice) confirmados ausentes
do disco por `Glob`/leitura direta, apesar de `HANDOFF.md` (raiz)
afirmar que esse material "segue existindo e funcionando só neste
computador". Recuperação: `git ls-tree -r --name-only
<commit-de-remocao>^ -- modulos/conformidade` pra listar o conteúdo
completo antes da remoção, seguido de `git show
<commit-de-remocao>^:<caminho> > <caminho>` por arquivo -- o blob
continua acessível no histórico do git independente de o arquivo ter
sido apagado do disco e adicionado ao `.gitignore` depois. Mitigação
geral: antes de recriar do zero qualquer arquivo deste módulo (ou de
qualquer material local-only citado como "existente" em documentação),
checar `git log --all -- <caminho>` primeiro -- reconstruir de memória
ou do zero descarta histórico real que ainda está recuperável.

### 2026-09-07-arquivos-do-modulo-somem-do-disco-junto-com-a-remocao-do-remoto

*Em resumo:* tirar este módulo do controle de versão remoto (commit
`3277638`, "Retira o modulo de conformidade e ferramentas internas do
repositorio remoto") não deixou os arquivos no disco, gitignorados --
apagou os 28 arquivos de verdade da árvore de trabalho, porque a
remoção foi feita como exclusão normal de arquivo rastreado (`git rm`
implícito num commit), não como "parar de rastrear, mantendo o
arquivo" (`git rm --cached`). Uma sessão que confia só no que existe
em disco, sem checar o histórico do git antes de concluir que um
arquivo "nunca existiu" ou "foi perdido de vez", recria do zero algo
que já existia por completo -- exatamente o que aconteceu com este
`tasks.md` (recriado na versão `0.1.0`, quando a versão real já estava
em `0.10.0`, com nove versões de pendências e resoluções perdidas até
a recuperação).

*Em detalhe técnico:* os 28 arquivos de `modulos/conformidade/` (sete
de `docs/`, vinte de `decisions/` mais o índice) confirmados ausentes
do disco por `Glob`/leitura direta, apesar de `HANDOFF.md` (raiz)
afirmar que esse material "segue existindo e funcionando só neste
computador". Recuperação: `git ls-tree -r --name-only
<commit-de-remocao>^ -- modulos/conformidade` pra listar o conteúdo
completo antes da remoção, seguido de `git show
<commit-de-remocao>^:<caminho> > <caminho>` por arquivo -- o blob
continua acessível no histórico do git independente de o arquivo ter
sido apagado do disco e adicionado ao `.gitignore` depois. Mitigação
geral: antes de recriar do zero qualquer arquivo deste módulo (ou de
qualquer material local-only citado como "existente" em documentação),
checar `git log --all -- <caminho>` primeiro -- reconstruir de memória
ou do zero descarta histórico real que ainda está recuperável.

## Controle de versão

| Versão | Data | Alteração | Origem da alteração |
|---|---|---|---|
| 0.1.0 | 27-08-2026 | Criação inicial -- uma armadilha registrada. | Criação inicial do módulo |
| 0.2.0 | 28-08-2026 | Duas armadilhas novas registradas (falha aberta do filtro `if`; mensagem de bloqueio ao vivo não prova execução real do gancho). | Investigação da checagem de emoji disparando fora de contexto |
| 0.3.0 | 28-08-2026 | Armadilha nova registrada (`jq` devolve `\r\n` neste ambiente, quebrando comparação de chave em laço linha a linha). | Correção do bloqueio real dos ganchos de conformidade |
| 0.4.0 | 28-08-2026 | Armadilha nova registrada (`grep -P` exige locale UTF-8 neste ambiente, e não pode ser combinado com `-E`). | Resolução de [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>) |
| 0.5.0 | 29-08-2026 | Armadilha nova registrada (nome de variável própria colidindo com variável especial do Bash, `BASH_COMMAND`). | Correção de falsos bloqueios reportados de outra sessão + pedido de janela de frescor maior |
| 0.6.0 | 29-08-2026 | Armadilha nova registrada (`core.hooksPath` aponta pra pasta principal, não pra worktree -- gancho nativo do git editado numa worktree só é validado ao vivo depois do merge). | Resolução de [decisions/0019](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>) |
| 0.7.0 | 10-09-2026 | Armadilha nova registrada (`.cwd` do gancho não acompanha `cd` escrito dentro do próprio comando -- só `EnterWorktree` move a sessão de verdade). | Reprodução ao vivo do relato de `pre_git_rules.sh` bloqueando commit legítimo numa worktree |
| 0.7.0 | 07-09-2026 | Armadilha nova registrada (remoção do módulo do remoto apagou os arquivos de verdade da árvore de trabalho, não só do controle de versão -- recuperados do histórico do git). | Recuperação do módulo, ausente do disco desde a remoção em `3277638` |
| 0.7.0 | 10-09-2026 | Armadilha nova registrada (`.cwd` do gancho não acompanha `cd` escrito dentro do próprio comando -- só `EnterWorktree` move a sessão de verdade). | Reprodução ao vivo do relato de `pre_git_rules.sh` bloqueando commit legítimo numa worktree |
| 0.7.0 | 07-09-2026 | Armadilha nova registrada (remoção do módulo do remoto apagou os arquivos de verdade da árvore de trabalho, não só do controle de versão -- recuperados do histórico do git). | Recuperação do módulo, ausente do disco desde a remoção em `3277638` |
