# ADR 0034 — Instalação de um comando só, com cópia sincronizada no início de cada sessão

*Em resumo:* instalar este módulo num projeto qualquer é: copiar a
pasta `modulos/conformidade/` inteira pra dentro do projeto, e rodar
`modulos/conformidade/scripts/instalar.sh` uma única vez. Esse comando
cria os dois atalhos de pasta possíveis (`.claude/hooks`,
`.claude/agents` -- mesmo conteúdo físico dos dois lados, ver
[decisions/0025](<0025-atalho-de-pasta-liga-hooks-e-agents-da-raiz-ao-clone.md>))
e copia o resto (`.claude/settings.json`, `.claude/skills/revisar-pr`,
`.github/pull_request_template.md`, `.vale.ini`, `.vale/styles`,
`scripts/`) -- itens que não podem ser atalho de pasta, por serem
arquivo único ou por morarem dentro de uma pasta que o projeto
hospedeiro pode legitimamente querer usar pra outra coisa também
(`.github/`, `scripts/`). Depois dessa única execução, um gancho novo
(`session_start_sync_modulo.sh`) refaz essa cópia sozinho, a cada
início de sessão, sem exigir lembrar de rodar nada de novo.

## Status

Aceito.

## Contexto

Achado ao vivo: comparando `.claude/settings.json` da raiz do projeto
contra a cópia dentro de `modulos/conformidade/`, os dois estavam
diferentes -- várias correções deste módulo, feitas ao longo de uma
sessão inteira, nunca chegaram a valer de verdade, porque só a cópia
de dentro do módulo tinha sido editada. Investigando o alcance real do
problema, os mesmos dois arquivos divergentes apareceram em mais
quatro pontos (`.claude/skills/revisar-pr`, `.github/pull_request_template.md`,
`.vale.ini`/`.vale/styles`, `scripts/`) -- todos cópias físicas
separadas entre a raiz e o módulo, nenhum com sincronização automática
até este ponto.

Causa raiz de fundo: atalho de pasta do Windows (junction) só funciona
pra uma pasta inteira, nunca pra um arquivo único -- e mesmo onde a
pasta inteira poderia virar atalho (`.github/`, `scripts/`,
`.claude/skills/`), fazer isso obrigaria o projeto hospedeiro a nunca
ter conteúdo próprio dentro dessas pastas, fora do que este módulo
contribui.

Alternativas reais consideradas:

- **Link simbólico de arquivo** -- testado ao vivo, falhou: exige
  privilégio de administrador, indisponível neste ambiente (erro
  confirmado: `NewItemSymbolicLinkElevationRequired`).
- **Hard link** -- testado ao vivo, funcionou tecnicamente, descartado:
  como o módulo é controlado por um repositório git próprio, uma
  atualização desse repositório tipicamente recria o arquivo por
  completo (não edita por cima), quebrando o vínculo em silêncio, sem
  nenhum aviso.
- **Atalho de pasta inteira pra `.github/`, `scripts/`,
  `.claude/skills/`** -- descartada: tiraria do projeto hospedeiro a
  liberdade de ter conteúdo próprio dentro dessas pastas, sem relação
  com este módulo.
- **Só documentar a instrução de copiar à mão** -- descartada: exige
  lembrar de um passo manual toda vez que algo no módulo muda,
  contrário ao objetivo de instalação simples (`COMO-USAR.md`).
- **Cópia automática de cada item, refeita no início de cada sessão
  nova, mais um único comando de instalação inicial pros atalhos de
  pasta** -- escolhida: nenhum passo depende de privilégio especial
  além da criação de atalho de pasta (que não exige administrador,
  testado ao vivo), sobrevive a qualquer forma de atualização do
  módulo, e nunca chega tarde demais -- o início de uma sessão nova já
  é o único momento em que uma mudança de gancho pode de fato passar a
  valer (ver
  [pitfalls.md](<../docs/pitfalls.md#2026-08-27-configuracao-de-ganchos-nao-recarrega-na-mesma-sessao>)).

## Decisão

`scripts/instalar.sh` (novo, dentro do módulo): cria os dois atalhos de
pasta (`.claude/hooks`, `.claude/agents`) via `New-Item -ItemType
Junction`, copia os demais itens listados acima, e liga os vigias
nativos do git (`core.hooksPath`) -- tudo numa única execução, rodada
uma vez, na raiz do projeto hospedeiro.

`session_start_sync_modulo.sh` (substitui o que antes só cobria
`settings.json`): mesma lista de itens copiáveis, comparando (`cmp`)
antes de copiar por cima, registrado no evento `SessionStart`, matchers
`startup|clear` e `resume`.

## Consequências

- `bash -n` sem erro nos dois scripts; `jq empty` sem erro em
  `.claude/settings.json` do módulo.
- Sincronização manual feita uma vez, nesta mesma sessão, pra corrigir
  o atraso já acumulado nos seis itens -- todos idênticos entre módulo
  e raiz no momento desta decisão.
- Teste ao vivo do mecanismo automático (instalação do zero num projeto
  de teste; e o gancho de sessão corrigindo uma divergência criada de
  propósito), ainda pendente -- ver `tasks.md`.
- Risco aceito: a sincronização só acontece no início de sessão --
  dentro de uma sessão já aberta, uma edição no módulo continua sem
  valer no arquivo real até a próxima sessão nova, mesma limitação de
  fundo já documentada, nunca resolvida por este mecanismo (só evita o
  esquecimento, não muda o limite de quando uma mudança passa a
  valer).
- Achado à parte, fora do escopo desta decisão: `scripts/hooks/pre-commit`
  e `scripts/README.md` citam caminho específico do projeto onde este
  módulo nasceu (`modulos/_template/`, `docs/docs-VMODEL-visao-geral/`)
  -- pendência nova em `tasks.md` pra auditar se isso deveria ser
  genérico.
