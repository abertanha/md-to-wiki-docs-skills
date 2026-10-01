---
phase: 03-pt-br-nas-5-superf-cies
verified: 2026-09-30T14:20:00Z
status: human_needed
score: 8/9 must-haves verified
covered_files: [".planning/phases/03-pt-br-nas-5-superf-cies/03-01-PLAN.md", ".planning/phases/03-pt-br-nas-5-superf-cies/03-01-SUMMARY.md", ".planning/phases/03-pt-br-nas-5-superf-cies/03-02-PLAN.md", ".planning/phases/03-pt-br-nas-5-superf-cies/03-02-SUMMARY.md", ".planning/phases/03-pt-br-nas-5-superf-cies/03-03-PLAN.md", ".planning/phases/03-pt-br-nas-5-superf-cies/03-03-SUMMARY.md", ".planning/phases/03-pt-br-nas-5-superf-cies/03-CONTEXT.md", ".planning/phases/03-pt-br-nas-5-superf-cies/03-DISCUSSION-LOG.md", ".planning/phases/03-pt-br-nas-5-superf-cies/03-REVIEW.md", ".planning/phases/03-pt-br-nas-5-superf-cies/deferred-items.md", "agents/format-dokuwiki.md", "agents/format-github-wiki.md", "agents/format-pdf.md", "agents/format-swagger.md", "scripts/generate-mkdocs.sh", "scripts/to-dokuwiki.sh", "scripts/to-pdf.sh", "templates/lang/en.lang", "templates/lang/pt-br.lang", "templates/swagger-ui.html", "tests/fail-closed.sh", "tests/no-mixed-output.sh", "tests/regress.sh"]
covered_digest: "v2:sha256:d8a64b29859e51a0c877ec274b1ac74e3de298aaaf7fb1f406d3fc89b2e55147"
behavior_unverified: 0
overrides_applied: 0
behavior_unverified_items: []
human_verification:
  - test: "Rodar o fluxo real do agent `agents/format-github-wiki.md` (step 3) contra a fixture com `OUTPUT_LANG=pt-br` e inspecionar `Home.md`/`_Sidebar.md` gerados"
    expected: "Headings e rótulos de seção saem 100% PT-BR usando os nouns do catálogo (`label_project_overview`, `section_features`, etc.); nomes de página, diretório e alvos `[[Page]]` permanecem intocados"
    why_human: "GitHub Wiki é a única das 5 superfícies que não tem script companion determinístico — o chrome é escrito por um subagente LLM seguindo instruções em prosa. Não existe fixture gerada nem gate automatizado (tests/no-mixed-output.sh não cobre esta superfície — ver WR-01) para inspecionar por grep; só a instrução-fonte foi verificada estaticamente, não o comportamento"
  - test: "Decidir se o bug CR-01 (sed com paranteses invertidos, regex ERE inválida) em `agents/format-github-wiki.md:78-83` deve ser corrigido antes de considerar a superfície GitHub Wiki funcional"
    expected: "Ou o bug é corrigido nesta fase, ou a decisão de adiar é registrada formalmente (issue/DEF-*) — atualmente é um achado do code review sem disposição registrada"
    why_human: "É um bug funcional real (reproduzido: `sed: -e expression #1, char 43: invalid reference \\2`), mas pré-existe à Phase 3 e não afeta a tradução de chrome (afeta apenas a conversão de links, um passo diferente do fluxo). A decisão de bloquear o ship por causa dele é de produto/prioridade, não determinável objetivamente pela verificação"
---

# Phase 3: pt-br nas 5 Superfícies Verification Report

**Phase Goal:** Com `OUTPUT_LANG=pt-br`, as cinco superfícies publicáveis (MkDocs index+nav, GitHub Wiki, DokuWiki, PDF, Swagger UI) emitem chrome 100% PT-BR com o locale projetado em cada consumer — zero saída mista
**Verified:** 2026-09-30T14:20:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `templates/lang/pt-br.lang` existe, UTF-8 sem BOM, com paridade de keyset garantida por gate contra `en.lang` (exceto `pdf_toc_title` allowlisted) | ✓ VERIFIED | `grep -cE "^[a-z][a-z0-9_]*='"` → en=36, pt-br=37 (36 espelhadas + `pdf_toc_title` exclusiva); `bash tests/fail-closed.sh` imprime `OK: catalog_parity`; negative control (chave órfã injetada) reproduzida ao vivo → `FAIL: mixed_output` / `negative_control_ok` |
| 2 | `to-pdf.sh`, `to-dokuwiki.sh` e `templates/swagger-ui.html` emitem chrome 100% PT-BR por lookup de catálogo (zero string hardcoded) | ✓ VERIFIED | `bash tests/regress.sh` → `OK: pdf (specs-book.pdf fallback) identical`, `OK: dokuwiki identical`, `OK: swagger (index.html) identical` (todas date-masked); `bash tests/fail-closed.sh` → `OK: pandoc_lang_flags pt-br/en`, `OK: keyset_equality to-pdf.sh`, `OK: keyset_equality to-dokuwiki.sh`; renderização manual pt-br confirmou `# Especificações` (PDF), `# Instruções de Importação DokuWiki` (DokuWiki), `<html lang="pt-BR">`/`<title>… — Documentação da API</title>` (Swagger) |
| 3 | Cadeia MkDocs+index sobre a fixture produz saída 100% PT-BR (headings, nav, site_name), sem heading em inglês | ✓ VERIFIED | Execução ao vivo: `mkdocs.yml` nav com `specs/features/autenticação/spec.md`; `docs/index.md` com `## Visão Geral`, `## Funcionalidades`, sem headings en |
| 4 | Gate grep por superfície (allowlist do glossário) não encontra rótulo `en` na saída pt-br — zero saída mista | ⚠️ PARCIAL (ver truth 8) | `bash tests/no-mixed-output.sh` → RC=0, `OK: mixed_output`/`OK: positive_control` para `mkdocs`, `index`, `pdf`, `swagger`, `dokuwiki` (5 execuções, mas cobrindo 4 destinos distintos — mkdocs+index são a mesma superfície MkDocs). GitHub Wiki (5ª superfície canônica) não é gerada nem varrida por este gate — ver truth 8 |
| 5 | `theme.language: pt-BR` no mkdocs.yml somente com pt-br; `en` omite a chave — saída en inalterada | ✓ VERIFIED | `bash tests/fail-closed.sh`/`tests/regress.sh` verdes; `git diff --quiet HEAD -- tests/fixtures/golden-sh/` → rc=0 (nenhum golden reescrito) |
| 6 | Pandoc do PDF carrega `-M lang=pt-BR -M toc-title=Sumário` somente no branch pt-br, verificado sem engine real | ✓ VERIFIED | `tests/fail-closed.sh` → `OK: pandoc_lang_flags pt-br` e `OK: pandoc_lang_flags en` (stub de pandoc grava a linha de comando efetiva, sem engine real) |
| 7 | Tree de teste com diretório acentuado (`features/autenticação/`) atravessa a cadeia pt-br sem corrupção de bytes — labels, filenames e anchors intactos | ✓ VERIFIED | Execução ao vivo: `docs/index.md` contém `Autenticação` (label derivado) e o path `specs/features/autenticação/spec.md` intocado; DokuWiki gerou `…features:autenticação:spec.txt` sem mojibake |
| 8 | GitHub Wiki (uma das 5 superfícies canônicas do goal) emite chrome 100% PT-BR e não vaza saída mista | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `agents/format-github-wiki.md` foi atualizado com as 6 chaves de catálogo corretas e a proibição de traduzir paths/`[[Page]]` (grep confirma). Mas: (a) esta superfície não tem script companion — o chrome é escrito por um subagente LLM, não deterministicamente gerável/inspecionável por este verificador; (b) `tests/no-mixed-output.sh` **não gera nem varre** esta superfície apesar do próprio header do arquivo alegar cobertura das "5 superfícies" (achado WR-01 do code review, confirmado); (c) o passo 4 do mesmo agent (`sed` de conversão de link) contém regex ERE inválida — reproduzida ao vivo (`sed: invalid reference \2`) — pré-existente à Phase 3, não bloqueia a tradução de chrome mas deixa a superfície funcionalmente quebrada num passo adjacente (achado CR-01 do code review) |

**Score:** 7/8 truths fully verified, 1 present-but-behavior-unverified (GitHub Wiki chrome + its gate coverage)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `templates/lang/pt-br.lang` | catálogo pt-br, 34+3 chaves | ✓ VERIFIED | 37 chaves, UTF-8 sem BOM, source limpo |
| `templates/lang/en.lang` | catálogo en com as 3 chaves DokuWiki novas | ✓ VERIFIED | 36 chaves |
| `scripts/generate-mkdocs.sh` | `THEME_LANGUAGE` condicional | ✓ VERIFIED | testado ao vivo (pt-br emite `language: pt-BR`; en omite) |
| `scripts/to-pdf.sh` | `output_lang` posicional, `PANDOC_LANG_OPTS` | ✓ VERIFIED | testado ao vivo |
| `scripts/to-dokuwiki.sh` | `output_lang` posicional, 3 chaves README | ✓ VERIFIED | testado ao vivo |
| `templates/swagger-ui.html` | `{{LANG_ATTR}}`, `{{TITLE_SUFFIX}}` | ✓ VERIFIED | placeholders presentes, aditivos |
| `tests/fail-closed.sh` | gates `catalog_parity`, `pandoc_lang_flags`, etc. | ✓ VERIFIED | rodado ao vivo, RC=0, todas as linhas `OK:` |
| `tests/no-mixed-output.sh` | gate de zero saída mista | ⚠️ PARCIAL | rodado ao vivo, RC=0, mas cobre só 4/5 superfícies (GitHub Wiki ausente — WR-01) |
| `agents/format-pdf.md`, `agents/format-dokuwiki.md` | call site `$OUTPUT_LANG` | ✓ VERIFIED | grep confirma strings literais exigidas |
| `agents/format-swagger.md` | procedimento de 4 substituições | ✓ VERIFIED | grep confirma |
| `agents/format-github-wiki.md` | nouns de catálogo + proibição de tradução de paths | ✓ VERIFIED (instruções) / ⚠️ (comportamento) | instruções corretas por grep; sem prova comportamental (agent-driven) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `templates/lang/pt-br.lang` | `scripts/generate-mkdocs.sh`/`generate-index.sh` | `set -a; . "$CATALOG"; set +a` | ✓ WIRED | testado ao vivo |
| `templates/lang/{en,pt-br}.lang` | `scripts/to-pdf.sh` | chaves `pdf_title`/`pdf_toc_title` | ✓ WIRED | `pandoc_lang_flags` gate + render manual |
| `templates/lang/{en,pt-br}.lang` | `scripts/to-dokuwiki.sh` | chaves `dokuwiki_readme_*` | ✓ WIRED | render manual confirmou heading/steps/footer |
| `templates/lang/{en,pt-br}.lang` | `templates/swagger-ui.html` | `sed` em `agents/format-swagger.md`/`tests/regress.sh` | ✓ WIRED | render manual confirmou `lang="pt-BR"` e título |
| `templates/lang/*.lang` | `agents/format-github-wiki.md` | nouns de seção citados na prosa | ⚠️ PARTIAL | instrução presente; sem execução real do agent para confirmar output |
| `tests/no-mixed-output.sh` | as 5 superfícies geradas com pt-br | `scan_surface`/`check_positive` | ⚠️ PARTIAL | cobre 4 superfícies (mkdocs, index, pdf, swagger, dokuwiki); GitHub Wiki nunca gerado/varrido neste arquivo, apesar do header alegar as "5 superfícies" |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `tests/regress.sh` reproduz saída `en` byte-idêntica nas 4 superfícies `.sh` | `bash tests/regress.sh` | `OK: mkdocs`, `OK: pdf`, `OK: swagger`, `OK: dokuwiki` (date-masked); `pwsh` SKIPPED (RC=3, esperado) | ✓ PASS |
| `tests/fail-closed.sh` — todos os gates fail-closed pt-br/en | `bash tests/fail-closed.sh` | 24 linhas `OK:`, zero `FAIL:`, RC=0 | ✓ PASS |
| `tests/no-mixed-output.sh` — zero saída mista nas superfícies cobertas | `bash tests/no-mixed-output.sh` | 10 linhas `OK:` (5 `mixed_output` + 5 `positive_control`), RC=0 | ✓ PASS |
| Controle negativo de `no-mixed-output.sh` é real (não vacuidade) | `nav_home='Home'` injetado em sandbox | `FAIL: mixed_output … nav_home`, RC=1 | ✓ PASS |
| Cadeia pt-br sobre `features/autenticação/` não corrompe bytes (SC4) | execução manual generate-mkdocs.sh + generate-index.sh + to-dokuwiki.sh pt-br | `Autenticação` correto no index, path intocado no nav e no README DokuWiki, filename `…features:autenticação:spec.txt` sem mojibake | ✓ PASS |
| CR-01 (sed regex inválida em format-github-wiki.md) reproduzido | `sed -i -E -e 's@\[\([^]]*\)\]…'` sobre fixture | `sed: -e expression #1, char 43: invalid reference \2 on 's' command's RHS`, RC=1 | ✓ CONFIRMED BUG (pré-existente) |
| Golden fixtures intocados | `git diff --quiet HEAD -- tests/fixtures/golden-sh/` | rc=0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| CHROME-02 | 03-01, 03-02, 03-03 | 5 superfícies emitem chrome 100% PT-BR, zero saída mista | ⚠️ PARCIAL | 4/5 superfícies com prova automatizada completa (mkdocs/index, PDF, DokuWiki, Swagger); GitHub Wiki com instruções corretas mas sem gate/fixture — CHROME-02 não está 100% coberto no sentido de "zero saída mista provada" para a 5ª superfície |
| QUAL-01 | 03-01, 03-02, 03-03 | `theme.language`, `-M lang`/`-M toc-title`, `lang` no Swagger | ✓ SATISFIED | Todos os 3 consumers verificados ao vivo com asserts estruturais sem engine |

Nenhum requirement órfão encontrado — `CHROME-02` e `QUAL-01` são os únicos mapeados para a Phase 3 em `REQUIREMENTS.md`, e ambos aparecem no campo `requirements:` dos 3 PLANs.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `agents/format-github-wiki.md` | 78-83 | `sed -E` com parênteses invertidos (regex ERE inválida) | ℹ️ Info (pré-existente, não introduzido pela Phase 3; predata o milestone per code review) | Passo 4 (conversão de links) do GitHub Wiki é não-funcional em qualquer idioma — reproduzido ao vivo nesta verificação. Não afeta a tradução de chrome (escopo desta fase), mas deixa a superfície quebrada num passo adjacente. Registrado como CR-01 no `03-REVIEW.md`, sem disposição formal ainda |
| `tests/no-mixed-output.sh` | header (linhas 2-4) | Comentário alega cobertura das "5 superfícies" mas a implementação cobre 4 | ⚠️ Warning | GitHub Wiki nunca é gerado/varrido — WR-01 do code review, confirmado nesta verificação |
| diversos (`generate-mkdocs.sh`, `to-pdf.sh`, `to-dokuwiki.sh`, `tests/regress.sh`) | — | `shellcheck` SC2018/SC2019/SC2015 (info) e `shfmt` diff de estilo | ℹ️ Info | Todos pré-existentes, confirmados via `git stash`/`git show` antes de cada plano e documentados em `deferred-items.md`; nenhuma regressão introduzida pela Phase 3 |

Nenhum marcador de débito (`TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`) encontrado em nenhum dos 13 arquivos modificados pela fase.

### Human Verification Required

### 1. Comportamento real do GitHub Wiki sob `OUTPUT_LANG=pt-br`

**Test:** Rodar o fluxo real do agent `agents/format-github-wiki.md` (steps 1-3) contra a fixture com `OUTPUT_LANG=pt-br` e inspecionar `Home.md`/`_Sidebar.md` gerados.
**Expected:** Headings e rótulos de seção saem 100% PT-BR usando os nouns do catálogo (`label_project_overview`, `section_features`, `section_overview`, `section_getting_started`, `label_contributing`, `label_architecture`); nomes de página, de diretório e alvos `[[Page]]` permanecem intocados em qualquer idioma.
**Why human:** GitHub Wiki é a única das 5 superfícies sem script companion determinístico — o chrome é redigido por um subagente LLM seguindo instrução em prosa, não por um script `.sh` gerável/comparável a golden fixture. Não há fixture nem gate automatizado cobrindo esta superfície (`tests/no-mixed-output.sh` não a varre — achado WR-01, confirmado nesta verificação). Apenas a instrução-fonte foi auditada estaticamente (grep), não o comportamento de saída.

### 2. Disposição sobre CR-01 (bug de regex no passo de conversão de links do GitHub Wiki)

**Test:** Decidir se o bug `sed` (parênteses invertidos, regex ERE inválida, reproduzido ao vivo nesta verificação: `sed: invalid reference \2`) em `agents/format-github-wiki.md:78-83` deve ser corrigido antes do ship desta fase, tratado num plano dedicado, ou aceito como known-issue rastreado por issue/DEF-*.
**Why human:** É um bug funcional real e confirmado, mas pré-existe à Phase 3 (não foi introduzido pelo diff desta fase) e não afeta a tradução de chrome (o critério de completion desta fase) — afeta apenas a conversão de links, um passo adjacente do mesmo fluxo. A decisão de bloquear ou não o ship por causa dele é de prioridade/produto, não determinável objetivamente por este verificador.

### Gaps Summary

Nenhum gap classificado como `gaps_found` (bloqueador) foi identificado: todas as 4 superfícies com script companion determinístico (MkDocs+index, PDF, DokuWiki, Swagger) foram testadas ao vivo nesta verificação — golden fixtures `en` intocados e byte-idênticos, saída `pt-br` 100% traduzida, `theme.language`/`-M lang`/`-M toc-title`/`lang` HTML projetados corretamente e só no branch pt-br, e a tree acentuada (`features/autenticação/`) atravessa a cadeia sem corrupção. Os três harnesses de gate (`tests/regress.sh`, `tests/fail-closed.sh`, `tests/no-mixed-output.sh`) rodaram ao vivo com RC=0/3 (3 = SKIP esperado de `pwsh`) e zero linha `FAIL:`, incluindo dois controles negativos reproduzidos ao vivo (não vacuidade).

O único ponto que impede um `passed` limpo é a 5ª superfície canônica do goal — GitHub Wiki: as instruções do agent foram atualizadas corretamente (grep confirma os 6 nouns de catálogo e a proibição de tradução de paths), mas (a) não existe prova comportamental porque a superfície é agent-driven, sem script/fixture determinístico, e (b) o próprio gate de zero-saída-mista desta fase não a cobre, apesar do header do arquivo alegar cobertura das "5 superfícies" (WR-01, code review). Adicionalmente, um bug funcional pré-existente (CR-01: regex `sed` inválida no passo de conversão de links do mesmo agent) foi reproduzido ao vivo e permanece sem correção ou disposição formal registrada.

Por indicação explícita do solicitante desta verificação, CR-01 e WR-01 são tratados como achados a reportar — não como bloqueadores automáticos do phase completion. Concordo com essa classificação no sentido de "não é regressão introduzida pela Phase 3 e não invalida a tradução de chrome nas 4 superfícies com prova determinística" — mas discordo que o ponto deva passar silenciosamente: a superfície GitHub Wiki, sendo uma das 5 nomeadas explicitamente no goal e nas Success Criteria da fase, carece de qualquer evidência comportamental, e isso é exatamente o tipo de lacuna que a postura adversarial deste verificador existe para não deixar passar como "passed". Por isso o status desta verificação é `human_needed`, não `passed` nem `gaps_found`.

---

_Verified: 2026-09-30T14:20:00Z_
_Verifier: Claude (gsd-verifier)_
