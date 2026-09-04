# Frases de confirmação e AUTORIZO-TRAVA

| Campo | Valor |
|---|---|
| Licença | Todos os direitos reservados — ver [LICENSE](LICENSE) |

Guia rápido de todas as frases que destravam algum bloqueio automático
deste projeto (`.claude/hooks/`) — o que cada uma libera, e quando
usar cada uma. `MANUAL.md`, na raiz, tem outro papel: um checklist
linha a linha do `CLAUDE.md` contra o código real dos ganchos, não um
guia de uso das frases em si.

Sempre digitadas por você, no chat, nunca pelo Claude — nenhuma delas
é reconhecida se vier de dentro de uma ferramenta que o Claude chama
(um comando, o conteúdo de um arquivo). Cada uma vale só pra sua
mensagem imediata: se a mensagem seguinte não repetir a frase, o
bloqueio volta a valer normalmente, sem ficar "pendurado" de uma
mensagem pra outra.

**Formato exigido:** o texto depois dos dois-pontos (`AUTORIZO-TRAVA:`)
ou antes da palavra final (`..., confirmado`) precisa ter conteúdo de
verdade — reticências (`...`), o texto de exemplo `<motivo>` sem nada
real escrito, ou frase vazia não contam, mesmo que a frase apareça
citada dentro de outro contexto (contando uma história, por exemplo).
Uma vírgula faltando ou sobrando, dentro da frase de confirmação, não
atrapalha — é tolerada.

| Frase | Quando aparece | O que ela libera |
|---|---|---|
| `AUTORIZO-TRAVA: <motivo real>` | Qualquer gancho bloqueando, de qualquer tipo. | Libera esse gancho específico, só pra essa tentativa — bypass geral, não muda nenhuma regra pra sempre. |
| `nada a registrar, confirmado` | `pre_edit_safety.sh`, item 13 — código editado num módulo sem `pitfalls.md`/`findings.md` tocados na sessão. | Confirma que a implementação não revelou achado nem armadilha nenhuma — só esse item, nada mais do gancho. |
| `sem alternativas reais, confirmado` | `pre_edit_safety.sh`, itens 14/15 — `docs/`/`schemas/` de um módulo editados sem ADR nova em `decisions/` na sessão. | Confirma que a mudança não envolveu escolher entre alternativas reais — só esses itens. |
| `tom impessoal confirmado, sem violacao` | `pre_edit_safety.sh`, item 16 — texto novo parece usar tom pessoal ("o usuário pediu", "decidimos"). | Confirma que não é violação de verdade (a palavra apareceu sem esse sentido) — só esse item. |
| `sem duplicacao de conteudo, confirmado` | `pre_edit_safety.sh`, item 17 — `handoff.md` de um módulo com linha longa sem link. | Confirma que não é descrição duplicada de outro documento — só esse item. |
| `commit revisado, confirmado` | `pre_commit_hygiene.sh`, item 13 — commit tocando mais de um arquivo em `docs/`/`decisions/` do mesmo módulo. | Confirma que nada foi duplicado entre os documentos tocados, e que cada um foi relido contra a própria descrição — só esse item. |

## Controle de versão

| Versão | Data | Alteração | Origem da alteração |
|---|---|---|---|
| 0.1.0 | 29-08-2026 | Criação — tabela com as seis frases de confirmação/`AUTORIZO-TRAVA` reconhecidas, quando cada uma aparece e o que libera. | Pedido direto, depois de confusão ao vivo sobre o formato exato de cada frase |
