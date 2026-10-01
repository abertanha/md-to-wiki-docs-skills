---
status: passed
phase: 03-pt-br-nas-5-superf-cies
source: [03-VERIFICATION.md]
started: 2026-09-30T00:00:00Z
updated: 2026-09-30T00:00:00Z
completed: 2026-09-30T00:00:00Z
---

## Tests

### 1. GitHub Wiki chrome PT-BR — verificação comportamental

expected: |
  Gerar uma wiki de teste com OUTPUT_LANG=pt-br seguindo agents/format-github-wiki.md.
  Verificar em Home.md e _Sidebar.md:
  - Headings e rótulos de seção em PT-BR (usando as chaves: label_project_overview,
    label_architecture, section_features, section_overview, section_getting_started,
    label_contributing)
  - Nomes de página e alvos [[Page]] intactos, não traduzidos (CHROME-04)
  - Nenhum rótulo em inglês fora da allowlist (Stack, Roadmap, Design, —)
result: passed

### 2. CR-01 — disposição do bug de sed em format-github-wiki.md

expected: |
  CR-01: as expressões `sed -E` em agents/format-github-wiki.md:78-83 usam parens
  escapadas (\(...\)) com backreferences (\1, \2, \3) — inválido com -E (GNU sed
  retorna "invalid reference \N"). O comando aborta antes de converter qualquer link.
  
  Decisão necessária: corrigir agora (remover as barras das parens: usar `(...)` em
  vez de `\(...\)`), rastrear como issue para a Phase 4, ou aceitar como known-issue
  documentado. Não bloqueia chrome translation (step diferente), mas links wiki
  nunca são convertidos no formato atual.
result: deferred
disposition: rastreado para Phase 4 — fix: remover barras das parens em sed -E (usar `(...)` em vez de `\(...\)`) em agents/format-github-wiki.md:78-83

## Summary

total: 2
passed: 1
issues: 0
pending: 0
skipped: 0
deferred: 1
blocked: 0

## Gaps
