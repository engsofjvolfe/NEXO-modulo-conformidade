# ADR 0025 — Atalho de pasta liga hooks e agents da raiz ao clone

*Em resumo:* `.claude/hooks` e `.claude/agents`, na raiz do projeto
hospedeiro, eram cópias soltas do conteúdo deste módulo -- mantidas
sincronizadas à mão, arquivo por arquivo, toda vez que algo mudava.
Viraram atalhos de pasta (junction do Windows -- um apontador de
pasta que o sistema operacional trata como se fosse a pasta de
verdade, sem duplicar nenhum arquivo) apontando direto pra este
módulo, mesmo mecanismo já usado por `ensure_worktree_links` pra
ligar uma worktree nova a este material.

## Status

Aceito.

## Contexto

Ao longo desta sessão, toda correção precisou ser aplicada duas
vezes -- uma no clone (fonte de verdade, versionada), outra copiada
pra raiz (cópia que o projeto hospedeiro realmente usa) -- risco
concreto de as duas ficarem diferentes por esquecimento.

A pasta `.claude/hooks/state` (registros de sessão: autorizações, o
que já foi lido/editado) só existia na cópia da raiz -- nunca fez
parte do clone, porque é dado de execução, não parte do módulo em si.
Um atalho de pasta faz `.claude/hooks/state` (sempre resolvido a
partir da pasta do projeto hospedeiro, em `lib/common.sh`) passar a
existir fisicamente dentro do clone -- sem proteção, esses registros
arriscariam ser enviados por engano pro repositório remoto do módulo.

Alternativas reais consideradas:

- **Manter as duas cópias, sincronizadas à mão** (status quo) —
  descartada: já causou divergência real, mais de uma vez, nesta
  própria sessão.
- **Atalho de pasta sem proteger `state/` antes** — descartada: risco
  concreto de vazar registro de sessão (inclusive o motivo de uma
  autorização) pro repositório remoto.
- **Atalho de pasta, com `.gitignore` novo no clone protegendo
  `state/` primeiro** — escolhida: fecha a duplicação sem abrir o
  risco de vazamento.

## Decisão

Criado `modulos/conformidade/.gitignore`, com uma linha:
`.claude/hooks/state/`. Copiado o conteúdo de `state/` da raiz pro
clone (preserva o registro de sessão já existente). Removidas as
cópias soltas de `.claude/hooks` e `.claude/agents` na raiz;
recriadas como atalho de pasta (`New-Item -ItemType Junction`)
apontando pro clone. `.claude/settings.json` fica de fora deste
atalho -- é arquivo único, não pasta, e continua sincronizado por
cópia direta, mesmo padrão de antes.

## Consequências

- Testado ao vivo: `.claude/hooks/pre_mandatory_reading_guard.sh` e
  `.claude/hooks/state/` acessíveis pela raiz através do atalho;
  `bash -n` sem erro no gancho lido por esse caminho.
- A partir de agora, qualquer correção em `.claude/hooks`/`.claude/agents`
  precisa acontecer só no clone -- a raiz reflete sozinha, sem cópia
  manual.
