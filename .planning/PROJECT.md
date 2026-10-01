# md-to-wiki

## What This Is

md-to-wiki é uma skill opencode que transforma árvores de documentação spec-driven (`.specs`) em destinos publicáveis — site MkDocs Material, GitHub Wiki, DokuWiki, livro PDF e página Swagger UI — com enriquecimento de referências via issues do GitHub e deploy verificado. Este milestone adiciona suporte a idioma de saída: PT-BR como default, inglês preservado.

## Core Value

Qualquer árvore de specs vira documentação publicável com um comando — de forma previsível.

## Requirements

### Validated

- ✓ Descoberta de fontes em árvore `.specs` (`discover-sources.sh`) — existing
- ✓ Geração de site MkDocs Material com nav e index (`generate-mkdocs.sh`, `generate-index.sh`) — existing
- ✓ Conversão DokuWiki com espelho de paths (`to-dokuwiki.sh`) — existing
- ✓ Publicação em GitHub Wiki com conversão de links e verificação — existing
- ✓ Livro PDF multi-engine weasyprint-first (`to-pdf.sh`/`.ps1`) — existing
- ✓ Página Swagger UI standalone (`templates/swagger-ui.html`) — existing
- ✓ Enriquecimento de referências via issues do GitHub (`references.md`) — existing
- ✓ Deploy verificado gh-pages/surge (`deploy.md`) — existing
- ✓ Camada de contrato externa (`CONTEXT.md`) + ADRs 0001–0004 — quality-alignment milestone

### Active

- [ ] `OUTPUT_LANG` parametrizável na camada de contrato — default `pt-br`, `en` suportado no v1
- [ ] Chrome gerado pelos scripts em PT-BR nas 5 superfícies (index/nav MkDocs, GitHub Wiki, DokuWiki, PDF, Swagger)
- [ ] Prosa redigida pelos agents em PT-BR conforme convenção (sem calques, sem tiques de LLM)
- [ ] Glossário anti-calque explícito no `CONTEXT.md` (termo → forma canônica)
- [ ] Regressão: `OUTPUT_LANG=en` reproduz a saída atual byte-idêntica (diff vazio no fixture)

### Out of Scope

- Feat 2 (a revelar pelo usuário) — próximo milestone, não faz parte deste ciclo
- Lacuna de discovery `.planning/` (GSD) ↔ `.specs` (`discover-sources.sh`) — outra conversa, v2 ou feat 2
- Tradução do conteúdo dos specs — a skill transforma fontes, não reescreve o que o usuário escreveu
- Auto-detecção de idioma das fontes — frágil em amostra pequena; rejeitada no questioning

## Context

- Skill para opencode, instalável via symlink (`install.sh`) ou npx; escopos `~/.config/opencode/skills`, `.opencode/skills`, `.cursor/skills`
- Alinhamento de qualidade recém-concluído no branch `ft/gsd-pattern-align` (commits `d845da0`..`c6baa14`): rubric de 22 dimensões (`docs/skill-quality-rubric.md`), auditoria fresh-context (`docs/audit-findings.md`), correções A1–A17 + contrato B1–B10, 4 ADRs
- Instrumento de qualidade vivo: `docs/skill-quality-rubric.md` — qualquer arquivo de skill tocado passa por auditoria delta com ele
- Fixture de verificação da cadeia MkDocs validado em `/tmp/mdw-sr3` (nav 5 seções, links internos 100%)
- Rótulos em inglês hoje hardcoded: `generate-index.sh` (Quick Start, Overview, Features, Architecture, Getting Started, Development), `generate-mkdocs.sh` (site_name "— Specifications", Home), `templates/swagger-ui.html`
- Host de desenvolvimento sem mkdocs/pandoc instalados — verificação ao vivo limitada (ADR 0003 registra)

## Constraints

- **Compatibilidade**: saída com `OUTPUT_LANG=en` byte-idêntica à atual — protege quem já usa a skill em inglês
- **Metodologia**: toda mudança passa pelo gate MET-1 (custo permanente por execução vs ganho de previsibilidade); sem portar padrões sem necessidade demonstrada
- **Stack**: bash + markdown; nenhuma dependência nova de runtime
- **Idioma**: docs e saída em PT-BR sem calques ("deployar", "printar", "commitar"); termo técnico fica em inglês integral ou usa equivalente consagrado; glossário canônico manda
- **Git**: todo o trabalho no branch `ft/gsd-pattern-align` (decisão do usuário); merge ao final das feats

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Idioma parametrizável (`OUTPUT_LANG`), default `pt-br` | Skill pública com público-alvo lusófono; inglês preservado por retrocompatibilidade | — Pending |
| Saída `en` byte-idêntica à atual | Barra de regressão objetiva, verificável por diff no fixture | — Pending |
| Glossário anti-calque explícito no `CONTEXT.md` | Determinístico e checável; convenção em prosa é subjetiva demais para auditar | — Pending |
| PT-BR aplica-se a chrome + prosa, nunca ao conteúdo dos specs | A skill transforma fontes, não reescreve autoria do usuário | — Pending |
| Todo o trabalho no `ft/gsd-pattern-align` | Decisão do usuário — branch conta a história completa antes do merge | — Pending |
| Gate MET-1 como critério de mudança | Validado no milestone de qualidade (25 defeitos achados, zero falsos positivos metodológicos) | ✓ Good |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-09-28 after initialization*
