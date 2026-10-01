---
phase: 03-pt-br-nas-5-superf-cies
plan: 02
subsystem: infra
tags: [bash, pandoc, i18n, catalog-driven-chrome, gettext-lite]

requires:
  - phase: 03-pt-br-nas-5-superf-cies
    provides: "templates/lang/pt-br.lang (catálogo pt-br com paridade de keyset), gate catalog_parity, THEME_LANGUAGE condicional (03-01)"
provides:
  - "to-pdf.sh e to-dokuwiki.sh catalog-driven, output_lang como segundo posicional obrigatório sem default"
  - "chaves dokuwiki_readme_heading/steps/footer nos dois catálogos (en.lang: 36 chaves, pt-br.lang: 37 chaves)"
  - "projeção -M lang=pt-BR -M toc-title=Sumário no pandoc, só no branch pt-br, provada por stub sem engine real"
  - "gate pandoc_lang_flags em tests/fail-closed.sh; keyset_equality/missing_key_halts/intact_catalog_succeeds estendidos para os dois scripts novos"
  - "format-pdf.md e format-dokuwiki.md com call site $OUTPUT_LANG e frase de contrato D-03"
affects: [phase-04-ps1-e-release]

actuals:
  tokens: 3800
  tasks: 3
  commits: 3
  plan_head_before: 685e17c1713a4dd11ede7fbb856757dee730cd83
  plan_head_after: bcde075f6c03c93786516726d1c91d7f0910ee16

tech-stack:
  added: []
  patterns:
    - "Bootstrap de catálogo replicado verbatim (D-02): ler ${N:?...}, normalizar tr, case allowlist en|pt-br ANTES de montar path, SCRIPT_DIR/CATALOG, set -a; . \"$CATALOG\"; set +a, gate fail-closed up-front"
    - "PANDOC_LANG_OPTS: array vazio no branch en, populado só no branch pt-br, expandido em toda invocação de pandoc com \"${arr[@]+\"${arr[@]}\"}\" (seguro sob set -u em bash 3.2)"
    - "printf '%b' para expandir \\n literais de um valor de catálogo multi-linha (dokuwiki_readme_steps), sempre como argumento nunca como format string"
    - "bootstrap de catálogo roda ANTES de guardas de dependência externa (pandoc), para que CHROME-03 não dependa de dependência de dev"

key-files:
  created: []
  modified:
    - scripts/to-pdf.sh
    - scripts/to-dokuwiki.sh
    - templates/lang/en.lang
    - templates/lang/pt-br.lang
    - tests/regress.sh
    - tests/fail-closed.sh
    - agents/format-pdf.md
    - agents/format-dokuwiki.md

key-decisions:
  - "PANDOC_LANG_OPTS inserido em TODAS as cinco invocações de pandoc de to-pdf.sh (as 4 da cascata de engines + a do ramo sem --pdf-engine), não só na primeira — senão o fallback xelatex/pdflatex/wkhtmltopdf perderia a locale em pt-br"
  - "pandoc_lang_flags usa um stub executável de pandoc (responde a --help e grava argumentos num arquivo) em vez de mockar via variável de ambiente — prova a linha de comando efetiva sem exigir engine real (D-13)"
  - "keyset_equality relaxado para tolerar guard indentado (^[[:space:]]*: \"...) porque o guard de pdf_toc_title vive dentro de um case, não em coluna 0"

requirements-completed: [CHROME-02, QUAL-01]

coverage:
  - id: D1
    description: "to-pdf.sh aceita output_lang como segundo posicional obrigatório, sem default, com allowlist fail-closed en|pt-br"
    requirement: CHROME-02
    verification:
      - kind: other
        ref: "tests/fail-closed.sh: OK: keyset_equality to-pdf.sh, OK: missing_key_halts to-pdf.sh (pdf_title), OK: intact_catalog_succeeds to-pdf.sh"
        status: pass
      - kind: other
        ref: "manual sandbox probe: to-pdf.sh sem output_lang e com valor inválido ('klingon') haltam citando 'en, pt-br'"
        status: pass
    human_judgment: false
  - id: D2
    description: "Título do livro PDF sai 100% PT-BR (# Especificações) com output_lang=pt-br; saída en byte-idêntica ao golden"
    requirement: CHROME-02
    verification:
      - kind: other
        ref: "manual sandbox probe: head -1 specs-book.md == '# Especificações' (pt-br) / == golden-sh/pdf/specs-book.pdf (en)"
        status: pass
      - kind: other
        ref: "tests/regress.sh: OK: pdf (specs-book.pdf fallback) identical (date-masked)"
        status: pass
    human_judgment: false
  - id: D3
    description: "pandoc recebe -M lang=pt-BR -M toc-title=Sumário só no branch pt-br, provado sem engine real"
    requirement: QUAL-01
    verification:
      - kind: other
        ref: "tests/fail-closed.sh: OK: pandoc_lang_flags pt-br, OK: pandoc_lang_flags en"
        status: pass
    human_judgment: false
  - id: D4
    description: "to-dokuwiki.sh aceita output_lang como segundo posicional obrigatório; README monta heading/steps/footer por lookup das 3 chaves novas"
    requirement: CHROME-02
    verification:
      - kind: other
        ref: "tests/fail-closed.sh: OK: keyset_equality to-dokuwiki.sh, OK: missing_key_halts to-dokuwiki.sh (dokuwiki_readme_heading)"
        status: pass
      - kind: other
        ref: "manual sandbox probe: README.md pt-br com heading '# Instruções de Importação DokuWiki', 4 passos numerados, footer 'Gerado pelo conjunto de skills md-to-wiki'"
        status: pass
      - kind: other
        ref: "tests/regress.sh: OK: dokuwiki identical"
        status: pass
    human_judgment: false
  - id: D5
    description: "Gate fail-closed de to-dokuwiki.sh halta nomeando a chave ausente mesmo num host sem pandoc no PATH (bootstrap antes da guarda de pandoc)"
    requirement: CHROME-02
    verification:
      - kind: other
        ref: "manual sandbox probe (PATH sem pandoc em bin próprio): halt citando dokuwiki_readme_heading, status != 0"
        status: pass
    human_judgment: false
  - id: D6
    description: "format-pdf.md e format-dokuwiki.md passam $OUTPUT_LANG no call site do script companion, sem fallback silencioso"
    requirement: CHROME-02
    verification:
      - kind: other
        ref: "grep: to-pdf$SCRIPT_EXT\" specs-book.pdf \"$OUTPUT_LANG\" e to-dokuwiki$SCRIPT_EXT\" dokuwiki-out \"$OUTPUT_LANG\" presentes; nenhuma assinatura antiga restante"
        status: pass
    human_judgment: false
  - id: D7
    description: "Saída en das duas superfícies byte-idêntica ao golden; goldens não reescritos"
    requirement: QUAL-01
    verification:
      - kind: other
        ref: "git diff --quiet HEAD -- tests/fixtures/golden-sh/ (rc=0); tests/regress.sh sem linha FAIL:"
        status: pass
    human_judgment: false

duration: ~45min
completed: 2026-09-29
status: complete
---

# Phase 3 Plan 02: to-pdf.sh e to-dokuwiki.sh catalog-driven Summary

**`to-pdf.sh` e `to-dokuwiki.sh` migrados para lookup de catálogo com `output_lang` posicional obrigatório; pandoc recebe `-M lang=pt-BR -M toc-title=Sumário` só em pt-br, provado por stub sem engine real; saída `en` byte-idêntica ao golden.**

## Performance

- **Duration:** ~45min
- **Tasks:** 3
- **Files modified:** 8
- **Commits:** 3 (+ este de SUMMARY)

## Accomplishments
- `to-pdf.sh` lê `output_lang` como segundo posicional (D-01/D-02), emite o título do livro por lookup de `pdf_title`, e projeta `-M lang=pt-BR -M toc-title=Sumário` no pandoc só no branch `pt-br` via `PANDOC_LANG_OPTS`, inserido nas 5 invocações de pandoc do script
- `to-dokuwiki.sh` migrado com o mesmo padrão posicional; README montado por lookup das 3 chaves novas `dokuwiki_readme_heading/steps/footer`, com o bootstrap do catálogo rodando ANTES da guarda de pandoc para que CHROME-03 não dependa de dependência de dev
- `templates/lang/en.lang` (36 chaves) e `templates/lang/pt-br.lang` (37 chaves) ganham as 3 chaves DokuWiki, valores `en` extraídos verbatim do heredoc original e conferidos byte a byte contra o golden
- `tests/fail-closed.sh` ganha o gate `pandoc_lang_flags` (stub executável de pandoc, sem engine real) e as invocações de `keyset_equality`/`missing_key_halts`/`intact_catalog_succeeds` para os dois scripts novos
- `format-pdf.md` e `format-dokuwiki.md` atualizados com `"$OUTPUT_LANG"` no call site e a frase de contrato D-03; fallback manual do PDF documentado para replicar as flags de locale

## Task Commits

1. **Tarefa 1: to-pdf.sh catalog-driven com projeção de locale no pandoc** - `e7c6899` (feat)
2. **Tarefa 2: to-dokuwiki.sh catalog-driven e as três chaves dokuwiki_readme_*** - `9935765` (feat)
3. **Tarefa 3: call sites de $OUTPUT_LANG em format-pdf.md e format-dokuwiki.md** - `bcde075` (feat)

**Plan metadata:** (este commit — docs: registra SUMMARY do plano 03-02)

## Files Created/Modified
- `scripts/to-pdf.sh` - assinatura `<output.pdf> <output_lang> <file...>`, título por lookup, `PANDOC_LANG_OPTS` condicional
- `scripts/to-dokuwiki.sh` - assinatura `<output_dir> <output_lang> <file...>`, README por lookup de 3 chaves, bootstrap antes da guarda de pandoc
- `templates/lang/en.lang` - +3 chaves `dokuwiki_readme_*` (36 chaves totais)
- `templates/lang/pt-br.lang` - +3 chaves `dokuwiki_readme_*` (37 chaves totais)
- `tests/regress.sh` - call sites de `to-pdf.sh`/`to-dokuwiki.sh` recebem `en`
- `tests/fail-closed.sh` - gate `pandoc_lang_flags`, anchor de `keyset_equality` tolerante a indentação, novas invocações para os dois scripts
- `agents/format-pdf.md` - call site com `"$OUTPUT_LANG"`, contrato D-03, fallback com flags de locale
- `agents/format-dokuwiki.md` - call site com `"$OUTPUT_LANG"`, contrato D-03

## Decisions Made
- `PANDOC_LANG_OPTS` é inserido em TODAS as 5 invocações de pandoc de `to-pdf.sh` (não só na primeira), porque a cascata de fallback de engines (weasyprint → xelatex → pdflatex → wkhtmltopdf) precisa preservar a locale em qualquer engine que de fato rode
- `pandoc_lang_flags` prova a projeção de locale com um stub executável de `pandoc` no `PATH` (responde `--help` e grava a linha de comando efetiva num arquivo), em vez de mockar via variável — cobre o comando REAL montado pelo script, não uma reimplementação da lógica de teste (D-13)
- `keyset_equality` teve sua âncora de extração relaxada de `^: "` para `^[[:space:]]*: "` porque o guard de `pdf_toc_title` vive indentado dentro de um `case` — os scripts existentes (guards em coluna 0) seguem casando sem alteração de comportamento

## Deviations from Plan

### Auto-fixed Issues

Nenhum desvio das Regras 1–3 (bugs, funcionalidade crítica ausente, ou blocker) foi necessário — a implementação seguiu o plano à risca.

### Divergências de lint pré-existentes (documentadas, não corrigidas)

**1. [Rule 2 - fora de escopo, apenas registrado] `shellcheck` SC2018/SC2019 (info) em `scripts/to-pdf.sh` e `scripts/to-dokuwiki.sh`**
- **Found during:** Tarefas 1 e 2
- **Issue:** A linha `OUTPUT_LANG=$(printf '%s' "$OUTPUT_LANG" | tr 'A-Z' 'a-z')` — replicada VERBATIM de `scripts/generate-index.sh` por exigência explícita do plano (D-02) — dispara os avisos informativos SC2018/SC2019 ("use `[:lower:]`/`[:upper:]`"). Confirmado pré-existente: o mesmo padrão em `generate-index.sh` já dispara os mesmos avisos hoje, e a divergência já havia sido documentada (não corrigida) no SUMMARY do plano 03-01 para `generate-mkdocs.sh`.
- **Fix:** Nenhuma — trocar o padrão divergiria da instrução explícita "replicar verbatim" (D-02) e criaria uma forma de normalização nova e não testada, fora do escopo desta tarefa.
- **Files modified:** nenhum (apenas documentado)
- **Verification:** `shellcheck scripts/generate-index.sh` reproduz os mesmos dois avisos na mesma linha padrão, confirmando que é herança do bootstrap compartilhado, não regressão introduzida por este plano
- **Committed in:** `e7c6899` e `9935765`

**2. [Rule 2 - fora de escopo, apenas registrado] `shfmt -d` diverge em estilo (2 espaços do repo + case sem indentação extra vs. defaults do `shfmt`) em `scripts/to-pdf.sh` e `tests/fail-closed.sh`**
- **Found during:** Tarefas 1 e 2
- **Issue:** `shfmt` por padrão indenta corpos de `case` (`-ci`) e usa tabs; o repositório usa 2 espaços e não indenta os corpos de `case` além do padrão do arquivo. Confirmado pré-existente por diff comparativo: `shfmt -i 2 -d` sobre a versão ORIGINAL (pré-plano) de `scripts/to-pdf.sh` já reporta a mesma forma de divergência nos blocos de `{ ... } > "$BOOK"` e na cascata de `||`/`&&`; o código novo (bootstrap, `case "$OUTPUT_LANG"`, `pandoc_lang_flags`) segue a MESMA convenção de 2 espaços já estabelecida no arquivo, para não introduzir uma forma de divergência adicional.
- **Fix:** Nenhuma — reformatar o arquivo inteiro para a convenção do `shfmt` é fora do escopo da tarefa (SCOPE BOUNDARY) e arriscaria um diff desnecessariamente grande, alterando linhas não tocadas pelo plano.
- **Files modified:** nenhum (apenas documentado)
- **Verification:** `shfmt -i 2 -d` na versão pré-plano (`git show HEAD:scripts/to-pdf.sh` antes do commit `e7c6899`) reproduz divergência equivalente; o mesmo padrão foi documentado como deviation aceita no SUMMARY do plano 03-01
- **Committed in:** `e7c6899` e `9935765`

---

**Total deviations:** 2 divergências de lint pré-existentes documentadas, não corrigidas (fora de escopo)
**Impact on plan:** Nenhum — não são regressões introduzidas por este plano. `shellcheck`/`shfmt` de `tests/regress.sh` e `tests/fail-closed.sh` (exceto a extensão do padrão de `case` já discutido) seguem limpos; a suite `tests/fail-closed.sh` roda com `rc=0` e `tests/regress.sh` com `rc=3` (SKIP esperado de `pwsh`, não uma falha).

## Issues Encountered

Nenhum. O host de desenvolvimento tem `pandoc` instalado (satisfazendo o `<precondition>` da Tarefa 2), mas não tem nenhum engine de PDF real (`weasyprint`/`xelatex`/`pdflatex`/`wkhtmltopdf`) — o wart do fallback markdown-como-PDF foi preservado e é exatamente o comportamento que o golden já captura, sem regressão.

## Auditoria delta — `docs/skill-quality-rubric.md` (agents/format-pdf.md, agents/format-dokuwiki.md)

Auditoria leve (self-audit do executor, não um subagente fresh-context dedicado — proporcional ao tamanho da mudança: 2 arquivos, ~10 linhas de diff cada). Dimensões relevantes à mudança:

| File | Dim | Verdict | Evidence | Nota |
|------|-----|---------|----------|------|
| agents/format-pdf.md | HIE-2 (rung placement) | ✅ Pass | linha 33 | Frase de contrato inline no step onde `$OUTPUT_LANG` é usado — toda invocação do step 2 precisa dela, não é conteúdo de branch específico |
| agents/format-pdf.md | PRU-1 (duplicação) | ✅ Pass | linha 33 vs. `agents/format-mkdocs.md:31` | Mesma frase-molde reaproveitada, sem reescrever a definição do contrato D-03 em prosa nova — a fonte da verdade do mecanismo continua em `format-mkdocs.md` |
| agents/format-pdf.md | STE-1 (critério checável) | ✅ Pass | linha 54 | "Same completion criterion as step 2" preservado; nenhuma mudança ao critério de done |
| agents/format-dokuwiki.md | HIE-2 / PRU-1 | ✅ Pass | linha 33 | Mesmo padrão, mesma frase-molde |
| agents/format-pdf.md | PRU-3 (sediment) | ✅ Pass | grep de assinatura antiga (`stale_pdf=0`) | Nenhuma referência à assinatura pré-D-01 restante |
| agents/format-dokuwiki.md | PRU-3 (sediment) | ✅ Pass | grep de assinatura antiga (`stale_dokuwiki=0`) | idem |

Nenhuma dimensão MET-1 aplicável (mudança mecânica de call site, não uma reestruturação de skill). Nenhum achado ⚠️/❌.

## User Setup Required

None - nenhuma configuração de serviço externo necessária.

## Next Phase Readiness

- As 4 superfícies `.sh` restantes com chrome hardcoded (MkDocs, index, PDF, DokuWiki) estão agora 100% catalog-driven; falta apenas Swagger (fora do escopo desta fase, ver `03-CONTEXT.md`)
- Padrão de bootstrap posicional (`output_lang` como 2º argumento, allowlist fail-closed, `PANDOC_LANG_OPTS`/`steps_block` como técnicas de projeção) está pronto para ser replicado pelos gêmeos `.ps1` na Phase 4
- Nenhum bloqueio conhecido para a Phase 4 (gêmeos PowerShell, glossário anti-calque, prosa dos agents)

## Self-Check: PASSED

Todos os 8 arquivos declarados (`scripts/to-pdf.sh`, `scripts/to-dokuwiki.sh`, `templates/lang/en.lang`, `templates/lang/pt-br.lang`, `tests/regress.sh`, `tests/fail-closed.sh`, `agents/format-pdf.md`, `agents/format-dokuwiki.md`) e os 3 hashes de commit de tarefa (`e7c6899`, `9935765`, `bcde075`) confirmados presentes.

---
*Phase: 03-pt-br-nas-5-superf-cies*
*Completed: 2026-09-29*
