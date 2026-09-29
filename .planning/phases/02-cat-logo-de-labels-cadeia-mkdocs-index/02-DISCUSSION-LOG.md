# Phase 2: Catálogo de Labels & Cadeia MkDocs/index - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-29
**Phase:** 02-cat-logo-de-labels-cadeia-mkdocs-index
**Areas discussed:** Nenhuma área discutida interativamente — usuário confirmou que as decisões já estavam definidas nos planos existentes

---

## Verificação de planos existentes

| Opção | Descrição | Selecionada |
|-------|-----------|-------------|
| Continuar e replanejar depois | Capturar o contexto agora e refazer os planos após a discussão | ✓ |
| Ver planos existentes | Revisar os planos já criados antes de decidir | (revisão feita) |
| Cancelar | Abortar | |

**Escolha do usuário:** Ver planos existentes → Continuar e replanejar depois
**Notas:** O usuário solicitou ver os planos antes de decidir. Após a revisão dos planos 02-01 e 02-02 (detalhados, com tasks, verifies e acceptance criteria completos), o usuário confirmou que as decisões já estavam prontas como definidas e não havia áreas a discutir interativamente.

---

## Gray areas apresentadas (não discutidas)

| Área | Descrição resumida | Selecionada |
|------|--------------------|-------------|
| `templates/index.md` | Arquivo rascunho sem consumidor — remover, manter ou converter? | Não selecionada |
| Fronteira label/markup | O que entra no valor da chave vs. o que fica no format string | Não selecionada |
| Chaves futuras no catálogo en | `pdf_title` e `swagger_title_suffix` sem consumidor nesta fase | Não selecionada |

**Escolha do usuário:** "Nenhuma, so checando se esta tudo pronto como definimos."

---

## Claude's Discretion

As seguintes decisões foram capturadas no CONTEXT.md com base nos planos existentes (02-01-PLAN.md e 02-02-PLAN.md) e no contexto da Phase 1, sem discussão interativa adicional:

- Fronteira label/markup: valor da chave = texto puro; markup e pipes ficam no format string; `index_architecture_body`, `index_getting_started_body` e `generated_by` carregam frase inteira
- Chaves futuras (`pdf_title`, `swagger_title_suffix`): entram no catálogo `en` sem consumidor, marcadas com comentário; `pdf_toc_title` não entra
- `templates/index.md`: decisão delegada ao checkpoint bloqueante do plano 02-02 (durante execução), não pré-determinada no CONTEXT.md
- Proibições de fase: extraídas diretamente das proibições documentadas nos planos

## Deferred Ideas

None — discussão permaneceu dentro do escopo da fase.
