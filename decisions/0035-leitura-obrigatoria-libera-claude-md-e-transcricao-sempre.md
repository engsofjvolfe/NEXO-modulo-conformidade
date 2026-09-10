# ADR 0035 — Leitura obrigatória libera CLAUDE.md e transcrição sempre

*Em resumo:* ler o `CLAUDE.md` do projeto hospedeiro, ou a transcrição
da própria sessão, nunca deveria exigir a lista de leitura obrigatória
já satisfeita antes -- a lista fica definida DENTRO do `CLAUDE.md`, então
bloquear a leitura dele até essa lista estar completa cria uma volta
sem saída pra quem ainda não leu nada (nenhuma leitura prévia registrada
nesta chamada específica).

## Status

Aceito.

## Contexto

Achado ao vivo: o vigia auditor do evento `Stop` (segunda inteligência
artificial, criada do zero a cada chamada, sem nenhuma leitura prévia
registrada) tentou ler o `CLAUDE.md` do projeto hospedeiro e a
transcrição da sessão, pra fazer o próprio trabalho dele (conferir
regra por regra). `pre_mandatory_reading_guard.sh` bloqueou as duas
leituras, exigindo primeiro outro documento da lista -- só que essa
lista É lida de dentro do próprio `CLAUDE.md`
([decisions/0028](<0028-lista-de-leitura-obrigatoria-lida-do-arquivo-de-instrucoes.md>)),
então satisfazer a exigência sem poder ler o `CLAUDE.md` primeiro não
tem caminho possível. Reproduzido ao vivo, repetidas vezes, cada
chamada satisfazendo só mais um item da lista (o estado é persistido
entre chamadas -- ver `synthesis_fresh_bytes`, `lib/common.sh`), numa
lista longa o bastante pra parecer sem fim.

Alternativas reais consideradas:

- **Identificar, dentro do gancho, se quem está chamando é o vigia
  auditor (não a sessão principal), e isentar só esse caso** --
  descartada: nenhum campo confiável, documentado, distingue os dois
  casos no JSON que o Claude Code entrega a um gancho `PreToolUse`.
- **Mudar a instrução do vigia auditor pra nunca precisar ler o
  `CLAUDE.md`/a transcrição sozinho** -- descartada: o trabalho dele
  (conferir regra por regra, e o que realmente aconteceu na conversa)
  exige abrir os dois; sem isso, a checagem vira decorativa.
- **Isentar a leitura do `CLAUDE.md` e da transcrição, sempre, pra
  qualquer chamador** -- escolhida: os dois casos abertos por essa
  isenção (transcrição: dado bruto de diagnóstico, não documentação a
  internalizar; `CLAUDE.md`: documento que só pode ser lido livremente,
  porque é a fonte da própria lista) não enfraquecem a exigência de
  leitura pros documentos que a lista realmente cobre -- só evita a
  volta sem saída.

## Decisão

`pre_mandatory_reading_guard.sh`, bloco de tratamento da ferramenta
`Read`: antes de checar `UNREAD_DOC`, compara o arquivo pedido contra
`$TRANSCRIPT` (já disponível no script) e contra
`mandatory_reading_claude_md_path` (`lib/common.sh`) -- em caso de
igualdade com qualquer um dos dois, libera (`exit 0`) sem checar a
lista.

## Consequências

- `bash -n` sem erro no script.
- Teste ao vivo, numa sessão nova, ainda pendente -- ver `tasks.md`.
- Escopo da isenção é só esses dois arquivos -- qualquer outro caminho
  fora da lista continua bloqueado normalmente enquanto a leitura
  obrigatória não estiver fresca, comportamento inalterado.
