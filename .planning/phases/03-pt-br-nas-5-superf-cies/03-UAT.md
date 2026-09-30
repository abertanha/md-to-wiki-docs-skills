---
status: testing
phase: 03-pt-br-nas-5-superf-cies
source: [03-VERIFICATION.md]
started: 2026-09-30T00:00:00Z
updated: 2026-09-30T00:00:00Z
---

## Current Test

number: 1
name: GitHub Wiki chrome PT-BR — verificação comportamental
expected: |
  Rodar o fluxo de agents/format-github-wiki.md com OUTPUT_LANG=pt-br e confirmar que
  Home.md e _Sidebar.md gerados usam chrome em PT-BR (headings e rótulos de seção
  do catálogo: "Visão Geral do Projeto", "Arquitetura", "Funcionalidades", etc.),
  que nomes de página (Home.md, _Sidebar.md) e alvos [[Page]] não são traduzidos,
  e que a instrução de seção em português aparece onde esperado.
awaiting: user response

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
result: [pending]

### 2. CR-01 — disposição do bug de sed em format-github-wiki.md

expected: |
  CR-01: as expressões `sed -E` em agents/format-github-wiki.md:78-83 usam parens
  escapadas (\(...\)) com backreferences (\1, \2, \3) — inválido com -E (GNU sed
  retorna "invalid reference \N"). O comando aborta antes de converter qualquer link.
  
  Decisão necessária: corrigir agora (remover as barras das parens: usar `(...)` em
  vez de `\(...\)`), rastrear como issue para a Phase 4, ou aceitar como known-issue
  documentado. Não bloqueia chrome translation (step diferente), mas links wiki
  nunca são convertidos no formato atual.
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
