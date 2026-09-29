---
phase: 01-contrato-golden-fixtures
verified: 2026-09-29T14:00:00Z
status: gaps_found
score: 4/5 must-haves verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/phases/01-contrato-golden-fixtures/01-01-PLAN.md
  - .planning/phases/01-contrato-golden-fixtures/01-01-SUMMARY.md
  - .planning/phases/01-contrato-golden-fixtures/01-02-PLAN.md
  - .planning/phases/01-contrato-golden-fixtures/01-02-SUMMARY.md
  - .planning/phases/01-contrato-golden-fixtures/01-03-PLAN.md
  - .planning/phases/01-contrato-golden-fixtures/01-03-SUMMARY.md
  - CONTEXT.md
  - agents/onboarding.md
  - docs/chrome-inventory.md
  - tests/fixtures/manifest.md
  - tests/regress.sh
covered_digest: "v1:sha256:d2c23d600c8ec34427e8cbe891cb68f93492def559065c0ba6f88ab568e51516"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Golden fixtures `en` congelados por geminho — `.sh` e `.ps1` capturados separadamente da cadeia atual não modificada, com tree de teste contendo diretório acentuado e token de data mascarado e documentado"
    status: partial
    reason: "`.sh` golden fixtures capturados por completo (mkdocs, pdf, swagger, dokuwiki). `tests/fixtures/golden-ps1/` não existe — os golden fixtures do geminho `.ps1` não foram capturados. O ROADMAP SC #3 requer ambos os geminhos capturados separadamente. A 01-03-SUMMARY reconhece explicitamente: 'QUAL-02 atendido parcialmente'. Causa: pwsh não disponível no host WSL; decisão acordada com o usuário e registrada no STATE.md como 'gap conhecido, não bloqueador'."
    artifacts:
      - path: "tests/fixtures/golden-ps1/"
        issue: "Diretório ausente — nenhum golden .ps1 foi capturado"
    missing:
      - "Instalar pwsh 7 em host com Windows ou WSL com pwsh disponível"
      - "Executar `bash tests/regress.sh capture` nesse host para capturar golden-ps1/{mkdocs,pdf,dokuwiki,swagger}"
      - "Validar que `bash tests/regress.sh` termina exit 0 (transição de exit 3 para exit 0 com pwsh disponível)"
      - "Registrar warts congelados no manifest (links specs//tmp/…, URL divergente do rodapé, separadores, path divergente docs/mkdocs.yml)"
---

# Phase 1: Contrato & Golden Fixtures — Verification Report

**Phase Goal:** O idioma de saída vira parâmetro de contrato (`OUTPUT_LANG`, default `pt-br`) e o comportamento `en` atual fica congelado em golden fixtures por geminho — decisões e rede de segurança antes de qualquer código depender delas

**Verified:** 2026-09-29T14:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from ROADMAP Phase 1 Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Onboarding pergunta o idioma de saída, grava `OUTPUT_LANG` com default `pt-br`, e `CONTEXT.md` documenta valores, token canônico minúsculo e transmissão por dispatch prompt — nenhum env var | ✓ VERIFIED | `agents/onboarding.md` item 4 `OUTPUT_LANG` com `Default: \`pt-br\``; `CONTEXT.md:18` tem linha na tabela §Variables com `en \| pt-br (default pt-br)`; `CONTEXT.md:29` proíbe env var explicitamente ("never reads from the environment"); return criteria inclui `OUTPUT_LANG` entre `AUDIENCE` e `FORMAT` |
| 2 | O contrato fixa normalização de locale na entrada (`pt-br` ≡ `pt-BR`), tabela de projeção por consumidor (`pt-BR` para Material/pandoc/HTML, `pt_BR` para Pyphen) e comportamento fail-closed para valor desconhecido listando os suportados | ✓ VERIFIED | `CONTEXT.md` seção `## Output language policy` (linha 23): normalização case-insensitive documentada, `pt-BR` para Material/pandoc/HTML, `pt_BR` para Pyphen, fail-closed com lista `(en, pt-br)` para valor desconhecido |
| 3 | Golden fixtures `en` congelados por geminho — `.sh` e `.ps1` capturados separadamente da cadeia atual não modificada, com tree de teste com diretório acentuado e token de data mascarado e documentado | ✗ FAILED | `.sh` complete: `golden-sh/{mkdocs,pdf,swagger,dokuwiki}/` todos presentes; tree tem 7 arquivos incluindo `features/autenticação/spec.md`; `Autenticação` íntegro em `golden-sh/mkdocs/docs/index.md`; `__DATE__` mascarado no harness. **BLOCKER**: `tests/fixtures/golden-ps1/` ausente — nenhum golden `.ps1` capturado. ROADMAP SC exige ambos os geminhos. 01-03-SUMMARY reconhece: "QUAL-02 atendido parcialmente" |
| 4 | Harness de diff (`diff -r`/`cmp`) commitado roda sem engines e valida os goldens como idênticos à cadeia atual | ✓ VERIFIED | `tests/regress.sh` existe, executável; `bash tests/regress.sh` exit 3 (SKIPPED .ps1, correto): 4 superfícies .sh mostram `OK: ... identical (date-masked)`; fallback PDF para markdown quando sem engine; `grep -c 'exit 3' tests/regress.sh` = 2; `git diff HEAD -- scripts/ templates/` vazio |
| 5 | Inventário de chrome (4 camadas × 5 superfícies, arquivo:linha) e decisões de escopo registradas no contrato: fail-closed de chave ausente, formato do catálogo, escopo Swagger com limite upstream documentado e datas ISO 8601 | ✓ VERIFIED | `docs/chrome-inventory.md` tem 4 seções `## Camada`, 12 chaves (seed + `pdf_generated_on` + `nav_issues`), `templates/index.md` marcado `unconsumed`; âncoras spot-checked (`scripts/generate-mkdocs.sh:43` = "Specifications", `scripts/generate-index.sh:105` = "Generated by"); `CONTEXT.md` Output language policy: catálogo `templates/lang/*.lang` em `KEY=value` UTF-8 sem BOM, fail-closed para chave ausente, escopo Swagger documentado, ISO 8601, `Authority: docs/chrome-inventory.md` |

**Score:** 4/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `tests/regress.sh` | Harness capture/regress, pin LC_ALL=C.UTF-8, máscara __DATE__, exit codes 0/1/3 | ✓ VERIFIED | Existe, executável; `LC_ALL=C.UTF-8` presente; `__DATE__` presente; `MDW_INDEX_OUT` ausente (correto); `exit 3` × 2 linhas; `# Usage: regress.sh [capture]`; `set -euo pipefail` |
| `tests/fixtures/tree/.specs/` | 7 arquivos .md incluindo `features/autenticação/spec.md` | ✓ VERIFIED | 7 arquivos presentes (`find tests/fixtures/tree -type f \| wc -l` = 7); `features/autenticação/spec.md` existe; sem datas ISO no conteúdo |
| `tests/fixtures/golden-sh/mkdocs/` | Golden MkDocs .sh (mkdocs.yml + docs/index.md + mirror specs) | ✓ VERIFIED | Presente; `repo_url:` com valor vazio (sem URL do origin); `Autenticação` íntegro em index.md |
| `tests/fixtures/golden-sh/pdf/specs-book.pdf` | Golden PDF .sh (fallback markdown) | ✓ VERIFIED | Presente |
| `tests/fixtures/golden-sh/swagger/index.html` | Golden Swagger .sh | ✓ VERIFIED | Presente |
| `tests/fixtures/golden-sh/dokuwiki/` | Golden DokuWiki .sh (7 arquivos .txt) | ✓ VERIFIED | 8 arquivos (README + 7 spec .txt); `features:autenticação:spec.txt` presente com UTF-8 preservado |
| `tests/fixtures/golden-ps1/` | Golden fixtures do geminho .ps1 (mkdocs, pdf, dokuwiki, swagger) | ✗ MISSING | Diretório não existe — pwsh não disponível no host WSL; captura deferida |
| `tests/fixtures/manifest.md` | Registro de pins, máscara, sítios datados, invariantes, proibição de edição manual | ✓ VERIFIED | Presente; contém `PROJECT_NAME=TestProject`, `AUDIENCE=general`, `LC_ALL=C.UTF-8`, `__DATE__`, `mktemp`, `autenticação` (6 pins); `generate-index.ps1` × 1; `to-pdf.ps1` × 2; pandoc 3.7.0.2 registrado |
| `docs/chrome-inventory.md` | Mapa 4 camadas × 5 superfícies, chaves da seed + novas, âncoras arquivo:linha | ✓ VERIFIED | 4 seções Camada; 12 chaves; `unconsumed` × 1; âncoras spot-checked |
| `CONTEXT.md` | Linha OUTPUT_LANG em §Variables + seção de política de idioma de saída | ✓ VERIFIED | Linha na tabela após AUDIENCE; seção `## Output language policy`; Authority pointer |
| `agents/onboarding.md` | Pergunta OUTPUT_LANG item 4 + token em §Return criteria | ✓ VERIFIED | Item 4 `OUTPUT_LANG`; `Default: \`pt-br\``; FORMAT item 5; Deployment item 6; OUTPUT_LANG na lista de retorno entre AUDIENCE e FORMAT |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `CONTEXT.md §Variables` | `agents/onboarding.md §Interview + §Return criteria` | mesmo nome canônico `OUTPUT_LANG` nos três sítios | ✓ WIRED | `OUTPUT_LANG` aparece em CONTEXT.md (tabela), onboarding.md (entrevista item 4 + lista de retorno) — casa única preservada |
| `CONTEXT.md (seção de política)` | `docs/chrome-inventory.md` | linha `Authority: docs/chrome-inventory.md` | ✓ WIRED | `grep -c 'chrome-inventory' CONTEXT.md` = 1 |
| `tests/fixtures/tree/.specs/` | `scripts/generate-mkdocs.sh` | `cp -r` da tree para WORK mktemp + invocação canônica (TestProject, .specs) | ✓ WIRED | regress.sh executa capture/regress com `mktemp -d` por perna; `git diff HEAD -- scripts/ templates/` vazio (cadeia não modificada) |
| `tests/regress.sh` | `tests/fixtures/golden-sh/` | `diff -r` entre cópias mascaradas do golden e saída fresca | ✓ WIRED | Execução real: 4 superfícies .sh mostram `OK: ... identical (date-masked)` |
| `tests/regress.sh (.ps1 perna)` | `tests/fixtures/golden-ps1/` | gate `command -v pwsh`; presente = executa; ausente = SKIPPED/exit 3 | ✗ NOT_WIRED | `golden-ps1/` não existe; a perna está corretamente gateada (SKIPPED: pwsh not found), mas sem o destino de golden para comparar |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| `tests/fixtures/golden-sh/mkdocs/docs/index.md` | Conteúdo do index | `scripts/generate-index.sh` executado durante capture | Sim — cadeia atual não modificada | ✓ FLOWING |
| `tests/fixtures/golden-sh/mkdocs/mkdocs.yml` | mkdocs.yml completo | `scripts/generate-mkdocs.sh` executado durante capture; `repo_url:` vazio (cwd mktemp fora do repo) | Sim — comportamento real congelado | ✓ FLOWING |
| `CONTEXT.md` linha OUTPUT_LANG | Definição de variável de contrato | Decisão documentada manualmente (não gerada por script) | Sim — documento de autoridade | ✓ FLOWING |
| `docs/chrome-inventory.md` | Âncoras arquivo:linha | Auditado contra scripts reais (`generate-mkdocs.sh:43`, `generate-index.sh:105` spot-checked) | Sim — âncoras verificadas | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Harness exit 3 com SKIPPED .ps1 e 4 superfícies .sh OK | `bash tests/regress.sh` | exit 3; 4× `OK: ... identical (date-masked)`; `SKIPPED: pwsh not found` | ✓ PASS |
| `Autenticação` íntegro no golden | `grep -c 'Autenticação' tests/fixtures/golden-sh/mkdocs/docs/index.md` | 1 | ✓ PASS |
| Sem URL do origin no golden mkdocs.yml | `grep 'github.com' tests/fixtures/golden-sh/mkdocs/mkdocs.yml` | (vazio) | ✓ PASS |
| Sem datas ISO na tree de fixture | `rg '[0-9]{4}-[0-9]{2}-[0-9]{2}' tests/fixtures/tree/` | (vazio) | ✓ PASS |
| regress.sh não exporta MDW_INDEX_OUT | `grep -c 'MDW_INDEX_OUT' tests/regress.sh` | 0 | ✓ PASS |
| git diff scripts/ templates/ vazio | `git diff HEAD -- scripts/ templates/` | (vazio) | ✓ PASS |
| chrome-inventory.md tem 4 camadas | `grep -c '^## Camada' docs/chrome-inventory.md` | 4 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PARAM-01 | 01-02-PLAN.md | `OUTPUT_LANG` parâmetro único de idioma, atribuído no onboarding, transmitido por dispatch prompt, nunca env var | ✓ SATISFIED | `CONTEXT.md:18` linha OUTPUT_LANG; `CONTEXT.md:29` proíbe env var; onboarding item 4 com Default pt-br; return criteria com OUTPUT_LANG |
| PARAM-02 | 01-02-PLAN.md | Locale normalizado na entrada; projeção por consumidor; erro fail-closed para valor desconhecido | ✓ SATISFIED | `CONTEXT.md` Output language policy: normalização, pt-BR/pt_BR por consumidor, fail-closed com suportados listados |
| QUAL-02 | 01-01-PLAN.md, 01-03-PLAN.md | Golden fixtures `en` congelados por geminho (.sh/.ps1); harness de diff sem engines | PARTIAL — .sh satisfied, .ps1 unsatisfied | `.sh` goldens completos (5 superfícies); harness runs exit 3/0; `tests/fixtures/golden-ps1/` ausente — QUAL-02 não atendido na parte `.ps1` |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | Nenhum padrão problemático encontrado nos arquivos modificados pela fase |

No TBD/FIXME/XXX markers found in phase-modified files. `git diff HEAD -- scripts/ templates/` is empty (chain not modified).

### Gaps Summary

**1 gap blocking full goal achievement:**

**SC3 — golden-ps1 ausente:** O ROADMAP Phase 1 Success Criterion #3 requer que os golden fixtures `en` sejam congelados por **geminho** — "`.sh` e `.ps1` capturados separadamente". O geminho `.sh` está completo (5 superfícies: mkdocs, pdf, swagger, dokuwiki, mais a tree e o manifest). O geminho `.ps1` não foi capturado: `tests/fixtures/golden-ps1/` não existe.

Causa documentada e acordada com o usuário (01-03-SUMMARY, STATE.md): `pwsh` não está disponível neste host Linux/WSL; os gêmeos `.ps1` são para usuários Windows. O regime SKIPPED/exit 3 é a saída correta para este host. O próprio SUMMARY diz: "QUAL-02 atendido parcialmente."

**Impacto downstream:** Sem golden-ps1 como baseline pré-refactor, a Phase 4 não terá o checkpoint byte-idêntico `.ps1` previsto no seu SC #2 ("reproduz os golden fixtures byte-idêntico por geminho também no lado `.ps1` após o refactor"). A captura do golden-ps1 deveria preceder qualquer refactor nos scripts `.ps1`.

**Para fechar o gap:** Instalar `pwsh` em um host que tenha Windows ou WSL com pwsh, executar `bash tests/regress.sh capture`, e commitar o resultado. O harness já está estruturado para capturar e validar esta perna sem alteração (o gate `command -v pwsh` já existe; apenas o diretório de destino golden-ps1 está vazio).

---

_Verified: 2026-09-29T14:00:00Z_
_Verifier: Claude (gsd-verifier)_
