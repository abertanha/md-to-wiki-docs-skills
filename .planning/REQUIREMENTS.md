# Requirements: md-to-wiki — milestone OUTPUT_LANG

**Defined:** 2026-09-28
**Core Value:** Qualquer árvore de specs vira documentação publicável com um comando — de forma previsível.

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Parâmetro & Contrato

- [x] **PARAM-01**: `OUTPUT_LANG` é o único parâmetro de idioma (`en` | `pt-br`, default `pt-br`), atribuído no onboarding e transmitido por dispatch prompt — como `AUDIENCE`, nunca env var
- [x] **PARAM-02**: Locale é normalizado na entrada (`pt-br` ≡ `pt-BR`) e projetado para a forma canônica de cada consumidor (`pt-BR` para Material/pandoc/HTML, `pt_BR` para Pyphen); valor desconhecido interrompe com erro listando os suportados

### Catálogo & Chrome

- [x] **CHROME-01**: Todo chrome de script/template resolve por chave contra um catálogo externo `KEY=value` por idioma; as strings `en` são extraídas verbatim das strings hardcoded atuais (nunca redigitadas)
- [x] **CHROME-02**: Com `OUTPUT_LANG=pt-br`, as 5 superfícies (MkDocs index+nav, GitHub Wiki, DokuWiki, PDF, Swagger UI) emitem chrome 100% PT-BR — zero saída mista
- [x] **CHROME-03**: Chave ausente no catálogo ativo interrompe a geração com erro nomeando a chave (fail-closed; fallback silencioso é o mecanismo da saída mista)
- [x] **CHROME-04**: Paths, anchors e filenames gerados jamais são traduzidos; labels derivados de nomes de arquivo do usuário são passthrough sem transformação de case

### Qualidade & Locale

- [x] **QUAL-01**: Idioma alcança os consumers: `theme.language: pt-BR` no mkdocs.yml (en omite a chave), `-M lang=pt-BR -M toc-title=Sumário` no pandoc (só pt-br), `lang` no HTML do Swagger
- [x] **QUAL-02**: Golden fixtures `en` congelados por geminho (.sh/.ps1) + harness de diff sem engines; `OUTPUT_LANG=en` reproduz a saída atual byte-idêntica (token de data mascarado e documentado)
- [ ] **QUAL-03**: Glossário anti-calque no `CONTEXT.md` rege a prosa dos agents; denylist de calques verificável por grep como critério de completion

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Contrato

- **PARAM-03**: Fronteira chrome/conteúdo como seção formal do contrato (T9; o princípio já vigora como Key Decision do PROJECT.md)

### Catálogo

- **CHROME-05**: Mais locales além de en/pt-br (custo: 1 arquivo novo por idioma após CHROME-01)
- **CHROME-06**: Nomes de seção derivados de diretório traduzidos via mapping explícito do usuário (toca autoria)
- **CHROME-07**: `OUTPUT_LANG` sobrescrevível por formato (ex.: site pt-br, PDF en)

### Locale avançado

- **LOCALE-01**: Datas/números por locale (D6) · **LOCALE-02**: hreflang + language switcher (D8 — o recurso "site multilíngue") · **LOCALE-03**: RTL (D9)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Machine-translation de conteúdo do usuário | A skill transforma fontes, não reescreve autoria (decisão do questioning) |
| Auto-detecção de idioma das fontes | Inferência frágil em amostra pequena; rejeitada no questioning |
| Memória de idioma por usuário/run | Quebra determinismo dado-entrada ↔ saída |
| Fallback silencioso para en | É o mecanismo exato da saída mista (defeito mais visível de i18n) |
| Sufixos de locale nas fontes (`page.pt-br.md`) | Toca autoria do usuário; padrão de site multilíngue é outro produto |
| Conditionais inline por idioma no código | 2 shells × N idiomas × labels; mata a regressão en por construção |
| Dependências novas de runtime (gettext, plugins mkdocs) | Constraint de stack (bash + markdown) + gate MET-1 |
| Console de progresso dos scripts em PT-BR | Decisão explícita da research: console fica em inglês no v1 (não é superfície publicada) |
| Feat 2 (a revelar) | Próximo milestone |
| Discovery `.planning/` (GSD) ↔ `.specs` | Outro ciclo; registrado no PROJECT.md |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| PARAM-01 | Phase 1 | Complete |
| PARAM-02 | Phase 1 | Complete |
| CHROME-01 | Phase 2 | Complete |
| CHROME-02 | Phase 3 | Complete |
| CHROME-03 | Phase 2 | Complete |
| CHROME-04 | Phase 2 | Complete |
| QUAL-01 | Phase 3 | Complete |
| QUAL-02 | Phase 1 | Complete |
| QUAL-03 | Phase 4 | Pending |

**Coverage:**

- v1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0

---

*Requirements defined: 2026-09-28*
*Last updated: 2026-09-28 after roadmap creation*
