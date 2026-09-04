# 0002 — Comparação de caminho ignora maiúscula/minúscula

A checagem que evita listar a própria pasta de trabalho como "worktree
esquecida" (`stop_fact_check.sh`) comparava dois caminhos com `==`
direto. No Windows, a letra de unidade do mesmo lugar em disco pode
chegar em caixas diferentes dependendo de quem informou o caminho --
a comparação falhava mesmo os dois caminhos apontando pro mesmo lugar,
e a pasta principal aparecia, por engano, na lista de worktrees pra
remover.

## Status

Aceito.

## Contexto

Confirmado ao vivo, na mesma sessão: `git worktree list` devolveu o
caminho da pasta principal como `H:/Downloads/fisio/NEXO-EMBRIOLOGIA`
(H maiúsculo), enquanto o `cwd` que o Claude Code informou pro gancho,
na mesma sessão, veio como `h:/Downloads/fisio/NEXO-EMBRIOLOGIA` (h
minúsculo) -- mesmo lugar em disco (o sistema de arquivos do Windows
não diferencia maiúscula de minúscula), duas grafias diferentes. A
comparação `"$WT_PATH" == "$CWD"`, usada pra nunca listar a própria
pasta de trabalho como candidata a remover, falhava nesse caso.

Alternativas reais consideradas:
- Normalizar via consulta ao disco (`realpath`, ou `cd "$X" && pwd`)
  antes de comparar -- descartada: exige que o caminho já exista e
  seja acessível no momento da checagem, e adiciona uma chamada de
  sistema a mais por comparação, sem necessidade -- o problema é só de
  grafia de texto, não de resolução de link ou caminho relativo.
- Comparação de texto, ignorando maiúscula/minúscula, depois de
  normalizar a barra (`normalize_path`, já existente) -- escolhida:
  resolve exatamente o problema observado, sem custo extra, e mantém
  o padrão já usado no resto do projeto (comparação de texto simples,
  sem tocar o disco).

## Decisão

Nova função `paths_equal()` em `lib/common.sh`, chamada em vez de
`==` direto: normaliza os dois caminhos (`normalize_path`, já
existente) e depois compara em minúsculo (`${a,,}` / `${b,,}`, recurso
do próprio bash). Aplicada em `stop_fact_check.sh`, na checagem de
worktree esquecida -- tanto pra excluir a pasta atual (`$CWD`) da
lista quanto, de resto, pra qualquer comparação de caminho futura que
precisar da mesma tolerância.

## Consequências

- Verificado por teste isolado (ver
  [`findings.md`](<../docs/findings.md>)): três casos cobertos --
  mesma pasta com letra de unidade em caixa diferente (considerada
  igual, como esperado), pastas realmente diferentes (consideradas
  diferentes, como esperado), e barra invertida do Windows de um lado
  só (considerada igual ao caminho com barra normal, como esperado).
- Mesma limitação de carregamento de sessão da ADR 0001: a correção
  está no arquivo, mas o gancho que roda de verdade nesta sessão ainda
  usa a versão anterior (carregada antes da correção existir) --
  confirmado ao vivo, o aviso de "worktree já mesclada" continuou
  aparecendo pra pasta principal depois da correção já estar em disco.
  Confirmação de ponta a ponta fica pra uma sessão nova.
- A comparação em minúsculo não diferencia maiúscula de minúscula em
  nenhum sistema, não só no Windows -- em sistema de arquivo que
  diferencia (Linux, por exemplo), dois caminhos com grafias
  realmente diferentes, mas que só diferem em caixa, agora contariam
  como iguais também lá. Aceito de propósito: o cenário que motivou a
  correção (duas grafias do mesmo lugar) é sempre um erro de quem
  informou o caminho, não uma distinção intencional -- não há caso
  real, neste projeto, de duas pastas diferentes que só se distingam
  por maiúscula/minúscula.
