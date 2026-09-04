# Handoff — Conformidade

| Campo | Valor |
|---|---|
| Módulo | Conformidade |
| Documento | Handoff |
| Versão | 0.16.0 |
| Data | 04-09-2026 |
| Licença | Todos os direitos reservados — ver [LICENSE](../LICENSE) |

> Resumo curto de "onde este módulo está" e "o que fazer a seguir" nele.
> Última etapa do fluxo — atualizado depois de qualquer uma das outras
> mudar. Só ponteiro, nunca detalhe, nunca resumo — detalhe de verdade
> mora em `concept.md`, `tasks.md`, `findings.md` ou `decisions/`.
>
> Cada linha segue [a regra de escrita geral](../CONVENCOES.md#como-escrever):
> link markdown de verdade + uma frase curta, nunca uma descrição do
> que o conteúdo diz.

## Índice
- [Estado atual](#estado-atual)
- [Próximo passo](#proximo-passo)
- [Controle de versão](#controle-de-versão)

## Estado atual

- [concept.md](concept.md) — o que o módulo deve ser e como deve se
  comportar.
- [architecture.md](architecture.md) — como o módulo é construído por
  dentro.
- [`MANUAL.md`](../MANUAL.md) — fonte normativa direta deste
  módulo, na raiz do repositório.
- [decisions/0001-cobertura-do-gancho-de-leitura-obrigatoria.md](<../decisions/0001-cobertura-do-gancho-de-leitura-obrigatoria.md>) —
  gancho de leitura obrigatória passa a cobrir toda ferramenta, não só
  escrita.
- [decisions/0002-comparacao-de-caminho-ignora-maiuscula-e-minuscula.md](<../decisions/0002-comparacao-de-caminho-ignora-maiuscula-e-minuscula.md>) —
  comparação de caminho de worktree corrigida pro Windows.
- [decisions/0003-deteccao-de-esquema-embutido-em-documento.md](<../decisions/0003-deteccao-de-esquema-embutido-em-documento.md>) —
  checagem de esquema puro passa a cobrir esquema embutido em
  documento.
- [decisions/0004-checagem-de-instrucoes-do-usuario-no-gancho-de-stop-existente.md](<../decisions/0004-checagem-de-instrucoes-do-usuario-no-gancho-de-stop-existente.md>) —
  revisor do fim da resposta passa a conferir instrução do usuário não
  atendida.
- [decisions/0005-formalizacao-do-sistema-de-conformidade-como-modulo.md](<../decisions/0005-formalizacao-do-sistema-de-conformidade-como-modulo.md>) —
  por que este sistema virou módulo, com `MANUAL.md` continuando como
  fonte normativa.
- [decisions/0006-read-so-libera-os-seis-documentos-obrigatorios-enquanto-faltar-algum.md](<../decisions/0006-read-so-libera-os-seis-documentos-obrigatorios-enquanto-faltar-algum.md>) —
  brecha da leitura obrigatória (`Read` de qualquer arquivo) fechada.
- [decisions/0007-bloqueio-real-dos-fatos-mecanicos-do-evento-stop.md](<../decisions/0007-bloqueio-real-dos-fatos-mecanicos-do-evento-stop.md>) —
  `stop_fact_check.sh` passa a bloquear de verdade, não só avisar.
- [decisions/0008-formato-de-bloqueio-nos-ganchos-de-julgamento-do-stop.md](<../decisions/0008-formato-de-bloqueio-nos-ganchos-de-julgamento-do-stop.md>) —
  formato de bloqueio dos ganchos de julgamento do `Stop` trocado, com
  limite reconhecido.
- [decisions/0009-revisor-de-commit-confere-conteudo-no-documento-certo.md](<../decisions/0009-revisor-de-commit-confere-conteudo-no-documento-certo.md>) —
  revisor de commit passa a conferir se cada conteúdo foi pro
  documento certo.
- [decisions/0010-guarda-de-busca-ampla-generica-por-formato-nao-por-nome-de-ferramenta.md](<../decisions/0010-guarda-de-busca-ampla-generica-por-formato-nao-por-nome-de-ferramenta.md>) —
  guarda de busca ampla trocada de "um gancho por nome de ferramenta"
  pra "um gancho só, reconhecendo o formato da chamada".
- [decisions/0011-auto-portao-contra-falha-aberta-do-filtro-if.md](<../decisions/0011-auto-portao-contra-falha-aberta-do-filtro-if.md>) —
  cada gancho que usa `if` sobre o matcher `Bash` confirma o próprio
  padrão de novo, sem depender só do `if`.
- [decisions/0012-ficha-sintese-substitui-releitura-do-diario-a-cada-checagem.md](<../decisions/0012-ficha-sintese-substitui-releitura-do-diario-a-cada-checagem.md>) —
  ficha compacta (estado atual, por ação) substitui a releitura do
  diário inteiro a cada checagem; diário continua existindo, intacto,
  do lado; reinicia a cada sessão nova.
- [decisions/0013-frescor-uniforme-de-leitura-substitui-permanencia.md](<../decisions/0013-frescor-uniforme-de-leitura-substitui-permanencia.md>) —
  leitura permanente dos seis documentos manuais trocada por frescor
  uniforme (mesma janela já usada em citação de documento).
- [`MANUAL.md`](../MANUAL.md) — recriado como checklist: cada
  faixa de linha do `CLAUDE.md` (344 linhas) contra o gancho real que
  a aplica, montado enquanto a leitura acontecia, não depois -- seis
  checagens que só rodavam no commit movidas pro momento da própria
  edição (ordem completa, `handoff.md` por último, módulo novo,
  `tasks.md` vazio, ADR de escolha real, tom impessoal); toda checagem
  de julgamento que bloqueia agora devolve uma frase curta visível
  direto pra quem está lendo, não só pro Claude.
- Quatro checagens que só existiam no momento do commit
  (`pre_commit_hygiene.sh`) -- emoji, pureza de esquema, linha de
  Licença em tabela de cabeçalho, "antes e depois" em documento nunca
  versionado -- movidas também pro momento da própria edição
  (`pre_edit_safety.sh`, itens 9 a 12), mesmo padrão já aplicado antes
  a outras seis regras. O gancho `agent` de edição (`Write|Edit`) ganha
  um terceiro julgamento (C): conteúdo duplicado entre documentos do
  mesmo módulo, quando deveria ser só ponteiro -- ver nota de
  acompanhamento em
  [decisions/0009](<../decisions/0009-revisor-de-commit-confere-conteudo-no-documento-certo.md>).
- Bloqueio real dos ganchos de conformidade corrigido -- ver
  [findings.md](findings.md) e
  [decisions/0013](<../decisions/0013-frescor-uniforme-de-leitura-substitui-permanencia.md>)
  pro detalhe completo; gancho `agent` de edição ganha um quarto
  julgamento (D), sobre qual arquivo de `schemas/` é o relevante.
- Formato de resposta corrigido em todo gancho decidido por IA (seis
  do tipo `agent`, um do tipo `prompt`) -- estava no formato de um
  gancho comum, nunca reconhecido pra esse tipo. Dois desses ganchos
  (revisão de commit, revisão de início do teste no preview) removidos
  por completo, substituídos por script comum; os outros quatro
  (revisão de edição, duas checagens do fim da resposta, idioma/emoji)
  mantidos, só com o formato corrigido. Mecanismo de confirmação
  textual generalizado (tabela, não mais um par arquivo/função por
  ponto). Ver
  [decisions/0014](<../decisions/0014-remocao-dos-ganchos-tipo-agent-substituidos-por-script-mais-confirmacao.md>).
- [findings.md](findings.md) — achados confirmados até agora.
- [analysis.md](analysis.md) — registro de como cada investigação
  deste módulo foi feita.
- [pitfalls.md](pitfalls.md) — armadilhas de ferramenta já encontradas.
- [decisions/0015-sessionstart-nao-reseta-mais-a-ficha-no-evento-resume-e-janela-de-frescor-maior.md](<../decisions/0015-sessionstart-nao-reseta-mais-a-ficha-no-evento-resume-e-janela-de-frescor-maior.md>) —
  evento `resume` do `SessionStart` não apaga mais a ficha; janela de
  frescor da leitura obrigatória alongada.
- [decisions/0016-autorizo-trava-rejeita-reticencias-sem-motivo-real.md](<../decisions/0016-autorizo-trava-rejeita-reticencias-sem-motivo-real.md>) —
  `AUTORIZO-TRAVA` rejeita reticências sem motivo real, mesma família
  do achado do placeholder `<motivo>`.
- [decisions/0017-comandos-git-gh-isentos-da-leitura-manual-obrigatoria.md](<../decisions/0017-comandos-git-gh-isentos-da-leitura-manual-obrigatoria.md>) —
  comandos `git`/`gh` isentos da leitura manual obrigatória.
- [decisions/0018-frases-de-confirmacao-toleram-virgula-opcional.md](<../decisions/0018-frases-de-confirmacao-toleram-virgula-opcional.md>) —
  frases de confirmação toleram vírgula opcional.
- [decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>) —
  `scripts/hooks/pre-commit` passa a detectar versão subida em
  documento só com tabela de changelog, sem tabela de cabeçalho.
- [decisions/0020-revisao-de-pr-por-assistentes-chamados-manualmente.md](<../decisions/0020-revisao-de-pr-por-assistentes-chamados-manualmente.md>) —
  revisão de PR por quatro assistentes chamados manualmente, um por
  assunto sem checagem automática.
- [decisions/0021-atalho-de-pasta-liga-material-local-em-toda-worktree.md](<../decisions/0021-atalho-de-pasta-liga-material-local-em-toda-worktree.md>) —
  worktree nova passa a enxergar `.claude/agents`, `.claude/hooks` e
  `modulos/conformidade` sozinha, por atalho de pasta.
- [tasks.md, Em aberto](<tasks.md#em-aberto>) — pendências abertas.

## Próximo passo

- [tasks.md, Em aberto](<tasks.md#em-aberto>) — pendências abertas,
  incluindo confirmação de ponta a ponta, numa sessão nova, dos
  mecanismos corrigidos e acrescentados até aqui.

## Controle de versão

| Versão | Data | Alteração | Origem da alteração |
|---|---|---|---|
| 0.1.0 | 27-08-2026 | Criação inicial. | Criação inicial do módulo |
| 0.2.0 | 27-08-2026 | Acrescentados ponteiros para decisions/0006 a 0008. | Segunda rodada de correção: formato de resposta dos ganchos revisados por IA nunca era reconhecido como bloqueio pelo Claude Code |
| 0.3.0 | 28-08-2026 | Acrescentado ponteiro para decisions/0009 e para o MANUAL.md recriado como checklist. | Terceira rodada: auditoria linha a linha do CLAUDE.md contra o código real, seis checagens movidas do commit pro momento da edição, systemMessage acrescentado em toda checagem de julgamento |
| 0.4.0 | 28-08-2026 | Acrescentado ponteiro para decisions/0010. | Guarda de busca ampla trocada de gancho-por-ferramenta pra gancho único, genérico por formato de chamada |
| 0.5.0 | 28-08-2026 | Acrescentado ponteiro para decisions/0012 (ficha/síntese), retroativo a trabalho já feito nesta sessão sem registro. | Fechamento da lacuna de documentação da ficha/síntese |
| 0.6.0 | 28-08-2026 | Acrescentado ponteiro para decisions/0011; linha nova sobre as quatro checagens movidas pro momento da edição e o terceiro julgamento (C) de conteúdo duplicado. | Correção da falha aberta do filtro `if`; extensão da checagem de duplicação de conteúdo pro momento da edição |
| 0.7.0 | 28-08-2026 | Acrescentado ponteiro para decisions/0013; linha nova sobre a correção do bloqueio real dos ganchos (compactação, corrupção da ficha, AUTORIZO-TRAVA, itens 13/14-15). | Correção do bloqueio real dos ganchos de conformidade |
| 0.8.0 | 28-08-2026 | Acrescentado ponteiro para pitfalls.md, sem linha própria antes. | Correção do bloqueio real dos ganchos de conformidade -- fechamento |
| 0.9.0 | 28-08-2026 | Acrescentado ponteiro para decisions/0014; linha nova sobre a correção do formato de resposta em todo gancho de IA, e a remoção de dois deles. | Resolução de decisions/0014 |
| 0.10.0 | 29-08-2026 | Acrescentados ponteiros para decisions/0015 a 0017. | Correção de falsos bloqueios reportados de outra sessão + pedido de janela de frescor maior |
| 0.11.0 | 29-08-2026 | Acrescentado ponteiro para decisions/0018. | Resolução de [decisions/0018](<../decisions/0018-frases-de-confirmacao-toleram-virgula-opcional.md>) |
| 0.12.0 | 29-08-2026 | Acrescentado ponteiro para decisions/0019. | Resolução de [decisions/0019](<../decisions/0019-deteccao-de-versao-subida-em-documento-so-com-changelog.md>) |
| 0.13.0 | 29-08-2026 | Acrescentado ponteiro para decisions/0020. | Resolução de [decisions/0020](<../decisions/0020-revisao-de-pr-por-assistentes-chamados-manualmente.md>) |
| 0.14.0 | 03-09-2026 | Nenhum ponteiro novo (`tasks.md` já citado). Todo o conteúdo deste módulo (e do resto do material local -- `.claude/agents/`, `.claude/hooks/`, `.claude/settings.json`, `scripts/`, `MANUAL.md`, entre outros) tinha sido apagado do disco por engano num commit anterior que devia só retirar do controle de versão -- restaurado a partir do commit pai desse commit. Pendência de confirmação dos quatro revisores de PR ganha ponto novo: confirmar isso especificamente de dentro de uma worktree de tarefa, não só na pasta principal -- ainda sem confirmação, nem a favor nem contra. | Achado durante a tarefa "aviso-radio-desligado-tela-jogo" do módulo motor |
| 0.15.0 | 04-09-2026 | Acrescentado ponteiro para decisions/0021. | Resolução de [decisions/0021](<../decisions/0021-atalho-de-pasta-liga-material-local-em-toda-worktree.md>) |
| 0.16.0 | 04-09-2026 | Nenhum ponteiro novo (`decisions/0021` já citada). Os arquivos reais das ferramentas internas (`.claude/agents/`, `.claude/hooks/`, `.claude/settings.json`, `.claude/skills/`, `scripts/`, `MANUAL.md`, `FRASES-DE-CONFIRMACAO.md`, `configurar-protecao-branch.sh`, `.vale.ini`/`.vale/`, `.github/pull_request_template.md`, `.gitattributes`) passam a existir dentro deste mesmo repositório -- antes só existiam na pasta principal do NEXO. Os dois links pra `MANUAL.md`, escritos apontando pra fora do repositório desde a extração, corrigidos pra apontar pra dentro dele. | Nota de acompanhamento em [decisions/0021](<../decisions/0021-atalho-de-pasta-liga-material-local-em-toda-worktree.md>) |
