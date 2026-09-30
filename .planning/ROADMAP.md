# Roadmap: md-to-wiki

## Overview

O milestone OUTPUT_LANG retrofitta localização de chrome single-locale sobre a skill existente: `OUTPUT_LANG` (`en` | `pt-br`, default `pt-br`) entra pela camada de contrato, todo chrome de script/template resolve por chave contra um catálogo externo por idioma, e a saída `en` permanece byte-idêntica à atual — provada por golden fixtures congelados por geminho antes de qualquer refactor. A ordem das fases segue os invariantes da pesquisa: rede de segurança antes de mover strings (fixtures precedem refactor), decisões antes de código (contrato precede consumo), padrão provado antes de replicar (cadeia MkDocs/index `.sh` antes das demais superfícies e do host PowerShell). O agrupamento é por fronteira da arquitetura (contrato → determinístico `.sh` → pt-br nas superfícies → segunda shell + agents + release), nunca por idioma — idioma é arquivo de dados, não fase.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Contrato & Golden Fixtures** - `OUTPUT_LANG` no contrato, normalização de locale e golden fixtures `en` congelados por geminho antes de qualquer refactor (completed 2026-09-29)
- [x] **Phase 2: Catálogo de Labels & Cadeia MkDocs/index** - Extração mecânica das strings `en`, consumo por chave nas superfícies de maior risco e o checkpoint duro de regressão `en` (completed 2026-09-29)
- [x] **Phase 3: pt-br nas 5 Superfícies** - Catálogo `pt-br` completo, chrome 100% PT-BR nas cinco superfícies e locale projetado em cada consumer (completed 2026-09-30)
- [ ] **Phase 4: Gêmeos PowerShell, Prosa & Release** - Catálogo na segunda shell com encoding disciplinado, prosa regida pelo glossário anti-calque e fechamento do milestone

## Phase Details

### Phase 1: Contrato & Golden Fixtures

**Goal**: O idioma de saída vira parâmetro de contrato (`OUTPUT_LANG`, default `pt-br`) e o comportamento `en` atual fica congelado em golden fixtures por geminho — decisões e rede de segurança antes de qualquer código depender delas
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: PARAM-01, PARAM-02, QUAL-02
**Success Criteria** (what must be TRUE):

  1. Onboarding pergunta o idioma de saída e grava `OUTPUT_LANG` no contexto do projeto (`pt-br` default quando indiferente); o `CONTEXT.md` documenta valores (`en` | `pt-br`), default, token canônico minúsculo e transmissão por dispatch prompt — nenhum env var em lugar nenhum
  2. O contrato fixa a normalização de locale na entrada (`pt-br` ≡ `pt-BR`), a tabela de projeção por consumidor (`pt-BR` para Material/pandoc/HTML, `pt_BR` para Pyphen) e o comportamento de erro para valor desconhecido listando os suportados
  3. Golden fixtures `en` congelados por geminho — `.sh` e `.ps1` capturados separadamente da cadeia atual não modificada, com tree de teste contendo diretório acentuado e token de data mascarado e documentado
  4. Harness de diff (`diff -r`/`cmp`) commitado roda sem engines (host sem mkdocs/pandoc) e valida os goldens como idênticos à cadeia atual
  5. Inventário de chrome (4 camadas × 5 superfícies, arquivo:linha) e decisões de escopo registradas no contrato: política fail-closed de chave ausente, localização e formato do catálogo, escopo Swagger (título + `lang`, limite upstream documentado) e datas ISO 8601 nos dois idiomas

**Plans**: 3/3 plans executed

Plans:
**Wave 1**

- [x] 01-01-PLAN.md — Tracer (walking skeleton): árvore de fixture commitada + harness `tests/regress.sh` + goldens `.sh` engine-less com máscara de data e regime SKIPPED/exit 3
- [x] 01-02-PLAN.md — Contrato `OUTPUT_LANG` (CONTEXT.md + onboarding) + inventário de chrome `docs/chrome-inventory.md`

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-03-PLAN.md — Dev-deps pwsh/pandoc (sudo com o humano) + captura dos goldens `.ps1`/DokuWiki + regressão completa exit 0

### Phase 2: Catálogo de Labels & Cadeia MkDocs/index

**Goal**: Todo chrome de script/template da cadeia MkDocs/index resolve por chave contra um catálogo externo — a fonte única prova-se byte-estável no checkpoint `en` antes de qualquer tradução existir
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: CHROME-01, CHROME-03, CHROME-04
**Success Criteria** (what must be TRUE):

  1. Catálogo `en` externo (`KEY=value`, UTF-8 sem BOM, chaves namespaced por superfície) contém as strings extraídas verbatim das hardcoded atuais — `generate-index.sh`, `generate-mkdocs.sh` e os templates MkDocs emitem todo chrome por lookup, com zero string de chrome hardcoded
  2. Checkpoint duro: `OUTPUT_LANG=en` na cadeia MkDocs/index reproduz o golden fixture da Phase 1 byte-idêntico (diff vazio com máscara de data) — barreira de commit antes de qualquer pt-br
  3. Chave ausente no catálogo ativo interrompe a geração com erro nomeando a chave — verificado removendo uma chave e observando o fail (fail-closed, sem fallback silencioso)
  4. Labels derivados de nomes de arquivo do usuário saem passthrough — nenhuma transformação de case em runtime, chrome fora do sed de title-case; paths, anchors e filenames gerados permanecem idênticos aos atuais

**Plans**: 2/2 plans complete

Plans:
**Wave 1**

- [x] 02-01-PLAN.md — Tracer: catálogo `templates/lang/en.lang` (33 chaves verbatim) + `generate-index.sh` emitindo todo chrome por lookup + checkpoint byte-idêntico contra o golden da Phase 1

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02-02-PLAN.md — `generate-mkdocs.sh` por lookup, `tests/fail-closed.sh` como gate repetível de CHROME-03/CHROME-04, e decisão do usuário sobre `templates/index.md`

### Phase 3: pt-br nas 5 Superfícies

**Goal**: Com `OUTPUT_LANG=pt-br`, as cinco superfícies publicáveis (MkDocs index+nav, GitHub Wiki, DokuWiki, PDF, Swagger UI) emitem chrome 100% PT-BR com o locale projetado em cada consumer — zero saída mista
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: CHROME-02, QUAL-01
**Success Criteria** (what must be TRUE):

  1. Catálogo `pt-br` completo com o mesmo key-set do `en` (paridade checada por gate); `to-pdf.sh`, `to-dokuwiki.sh` e `templates/swagger-ui.html` passam a emitir chrome por lookup do catálogo — as 5 superfícies saem 100% PT-BR
  2. Gate grep por superfície (com allowlist do glossário) não encontra nenhum rótulo `en` na saída pt-br — zero saída mista
  3. `theme.language: pt-BR` aparece no mkdocs.yml somente com pt-br (com `en` a chave é omitida — saída en inalterada); o comando pandoc do PDF carrega `-M lang=pt-BR -M toc-title=Sumário` somente no branch pt-br, verificado por assert estrutural sem engines; o HTML do Swagger ganha `lang`
  4. A tree de teste com diretório acentuado (`features/autenticação/`) atravessa a cadeia pt-br sem corrupção de bytes — labels derivados preservados, filenames e anchors intactos

**Plans**: 3/3 plans executed

Plans:
**Wave 1**

- [x] 03-01-PLAN.md — Tracer: catálogo `templates/lang/pt-br.lang` (34 chaves) + `theme.language: pt-BR` condicional + gate de paridade de keyset en↔pt-br

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 03-02-PLAN.md — `to-pdf.sh` e `to-dokuwiki.sh` catalog-driven com `output_lang` posicional, flags `-M lang`/`-M toc-title` só em pt-br, e os agents `format-pdf.md`/`format-dokuwiki.md`

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 03-03-PLAN.md — `swagger-ui.html` com `{{LANG_ATTR}}`/`{{TITLE_SUFFIX}}`, agents Swagger e GitHub Wiki sob o contrato de `OUTPUT_LANG`, e `tests/no-mixed-output.sh` como gate de zero saída mista

### Phase 4: Gêmeos PowerShell, Prosa & Release

**Goal**: O idioma alcança o host Windows (gêmeos `.ps1` consumindo o mesmo catálogo com disciplina de encoding) e a prosa dos agents (glossário anti-calque com gate verificável); o milestone fecha com a regressão `en` válida por geminho e a nota de release do default flip
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: QUAL-03
**Success Criteria** (what must be TRUE):

  1. Gêmeos `.ps1` (`generate-index.ps1`, `generate-mkdocs.ps1`, `to-pdf.ps1`, `to-dokuwiki.ps1`) resolvem todo chrome por chave contra o mesmo catálogo (leitura com encoding pinado, parse do `KEY=value`) — divergências de string entre gêmeos convergem por construção da fonte única
  2. `OUTPUT_LANG=en` reproduz os golden fixtures byte-idêntico por geminho também no lado `.ps1` após o refactor; fixture com diretório acentuado não apresenta mojibake nem BOM inesperado no caminho en (wart atual preservado)
  3. Glossário anti-calque no `CONTEXT.md` rege a prosa dos agents: dispatch prompts e `agents/format-*.md` carregam a linha de `OUTPUT_LANG` + glossário inline (referência consultada sob demanda é ignorada sob pressão); nouns canônicos de seção vêm do mesmo mapa de labels
  4. Denylist de calques verificável por grep roda como critério de completion — zero ocorrência de calques ("deployar", "printar", "commitar", …) na prosa dos agents e na saída pt-br
  5. Release: `tests/regress.sh` wired no fluxo, README/README.pt-BR e rubric delta atualizados, nota de release documentando o default flip e que `OUTPUT_LANG=en` preserva o comportamento anterior; execução pt-br end-to-end num host com engines

**Plans**: 1/5 plans executed

Plans:
**Wave 1**

- [x] 04-01-PLAN.md — Tracer: `scripts/lib/catalog.ps1` (parser quote-aware) + `generate-index.ps1` catalog-driven com os bugs do D-16 corrigidos + 4 chaves novas + `tests/ps1-contract.sh`

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 04-02-PLAN.md — Glossário anti-calque no `CONTEXT.md` inline nos agents de prosa autoral, `tests/no-calques.sh`, e CR-01 + descarte de texto de link + laço frágil com `tests/wiki-links.sh`
- [ ] 04-03-PLAN.md — `generate-mkdocs.ps1`, `to-pdf.ps1` e `to-dokuwiki.ps1` catalog-driven (theme.language e flags de pandoc aditivas) + `ps1-contract.sh` nos quatro gêmeos

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 04-04-PLAN.md — Perna `.ps1` real de `tests/regress.sh`, checkpoint de instalação do `pwsh` e captura de `tests/fixtures/golden-ps1/`

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 04-05-PLAN.md — Release: ressalva de paridade removida dos READMEs, seção de gates, `CHANGELOG.md` com a nota do default flip, e auditoria delta consolidada do rubric

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Contrato & Golden Fixtures | 3/3 | Complete    | 2026-09-29 |
| 2. Catálogo de Labels & Cadeia MkDocs/index | 2/2 | Complete    | 2026-09-29 |
| 3. pt-br nas 5 Superfícies | 3/3 | In Progress|  |
| 4. Gêmeos PowerShell, Prosa & Release | 1/5 | In Progress|  |
