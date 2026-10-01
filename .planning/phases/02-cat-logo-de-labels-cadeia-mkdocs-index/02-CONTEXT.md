# Phase 2: Catálogo de Labels & Cadeia MkDocs/index - Context

**Gathered:** 2026-09-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 2 entrega o catálogo externo de labels `en` (`templates/lang/en.lang`), a refatoração de `generate-index.sh` e `generate-mkdocs.sh` para consumir o catálogo por lookup, o gate fail-closed automatizado (`tests/fail-closed.sh`), e a prova byte-idêntica com `OUTPUT_LANG=en` contra os goldens da Phase 1 — tudo antes de qualquer tradução pt-br existir.

Fora do escopo: catálogo `pt-br` (Phase 3), chrome pt-br nas 5 superfícies (Phase 3), gêmeos `.ps1` refatorados (Phase 4), wiring do `tests/fail-closed.sh` no fluxo de release (Phase 4), glossário anti-calque e prosa dos agents (Phase 4).

</domain>

<decisions>
## Implementation Decisions

### Catálogo `en.lang`

- **D-01:** Formato `KEY='value'` (aspas simples sempre; aspas simples literais no valor usam fechar-inserir-reabrir), um par por linha, UTF-8 sem BOM, sem espaços em torno do `=`, sem expansão de shell. Comentários com `#`, prosa em PT-BR, valores em inglês.
- **D-02:** 33 chaves no total — 29 consumidas por `generate-index.sh`, 3 por `generate-mkdocs.sh` (`site_name_suffix` compartilhada entre os dois, `site_description`, `nav_home`), 2 prontas para Phase 3 sem consumidor nesta fase (`pdf_title`, `swagger_title_suffix`, marcadas com comentário de qual fase consome). `pdf_toc_title` **NÃO entra** — não existe valor `en` hoje (a flag não é passada ao pandoc); inventar uma quebraria a barra byte-idêntica. — **Reversibility:** costly — a Phase 3 assume o esquema de 33 chaves; remover ou renomear uma chave depois exige coordenar mudanças no catálogo, nos scripts da Phase 3 e nos harnesses de verificação.
- **D-03:** Valores extraídos verbatim de `docs/chrome-inventory.md` (que cita `arquivo:linha` dos scripts). **NUNCA** redigitar de memória ou copiar da seed do glossário — onde a seed e os scripts divergem, os scripts vencem. Divergência de um byte quebra a barra byte-idêntica.
- **D-04:** Namespace por prefixo de superfície: `site_*` e `nav_*` = MkDocs; `index_*`, `section_*`, `label_*`, `table_*`, `desc_*`, `cell_*`, `generated_by` = index; `pdf_*` = PDF; `swagger_*` = Swagger.

### Fronteira label/markup

- **D-05:** Valor da chave = **texto do rótulo apenas** (sem markup). Prefixo `##` de heading, separadores de tabela (`|---------|`), pipes de coluna ficam no format string do `printf`/heredoc — nunca dentro do valor. **Exceção deliberada:** `index_architecture_body`, `index_getting_started_body` e `generated_by` carregam a frase inteira com link markdown e URL — frase inteira é a unidade de tradução; fragmentar em torno de link é anti-padrão de i18n. Paths dentro desses links são estrutura e permanecem idênticos em qualquer idioma (CHROME-04). — **Reversibility:** costly — a Phase 3 traduz com base nessa fronteira; mudar a granularidade das chaves depois exige reescrever o catálogo `pt-br` e os format strings dos scripts.
- **D-06:** Labels derivados de nome de diretório do usuário (via `sed 's/-/ /g; s/\b\(.\)/\u\1/g'`) são **passthrough** — não viram chave de catálogo. Esse sed permanece exatamente **1 vez** em `generate-index.sh` e **2 vezes** em `generate-mkdocs.sh`, e nenhuma variável de catálogo atravessa esse pipeline (CHROME-04).

### Bootstrap e gate fail-closed

- **D-07:** Assinatura nova de `generate-index.sh`: `<project_name> <audience> <output_lang> [feature_base_dirs...]` — `output_lang` é o terceiro posicional, obrigatório (sem default). — **Reversibility:** costly — a assinatura é contrato publicado (agents, harness, READMEs, gêmeos `.ps1` na Phase 4); desfazer exige mudança coordenada em todos os call sites.
- **D-08:** Assinatura nova de `generate-mkdocs.sh`: `<project_name> <specs_dir> <output_lang>` — `output_lang` é o terceiro posicional, obrigatório.
- **D-09:** Bootstrap em todos os scripts da cadeia, nesta ordem: (1) ler `output_lang` com `${3:?…}`, normalizar para minúsculo com `tr 'A-Z' 'a-z'` (faixa ASCII explícita — não classe de caractere dependente de locale, não `sed`), (2) `case` de allowlist `en|pt-br` ANTES de qualquer construção de path (barreira de path traversal), (3) derivar `SCRIPT_DIR` com `cd "$(dirname "${BASH_SOURCE[0]}")" && pwd`, montar `CATALOG`, checar `[ -f "$CATALOG" ]`, (4) carregar com `set -a; . "$CATALOG"; set +a`, (5) gate fail-closed up-front com `: "${chave:?key chave not found in catalog}"` para TODAS as chaves que o script expande — nunca um subconjunto (CHROME-03).
- **D-10:** `OUTPUT_LANG` chega **sempre por argumento posicional** — nunca por env var, nunca com default no script. O default `pt-br` vive no contrato/onboarding e em lugar nenhum mais.

### `templates/index.md` (checkpoint bloqueante do plano 02-02)

- **D-11:** A decisão sobre o destino de `templates/index.md` (remover / manter como débito técnico / converter em consumidor real) **será tomada durante a execução do plano 02-02**, não pré-determinada aqui. O arquivo é unconsumed (registrado no inventário como D-12 da Phase 1). Remoção requer confirmação explícita do usuário (regra do projeto). Opções: remover (recomendada — fecha CHROME-01 sem exceção, reversível por `git restore`), manter e marcar como débito técnico, ou converter (reprova no MET-1 — custo permanente sem consumidor). — **Reversibility:** reversible — `git restore` recupera em < 1 min.

### Regressão e goldens

- **D-12:** Checkpoint duro: `bash tests/regress.sh` produz diff vazio (mascarando token de data) contra goldens de `tests/fixtures/golden-sh/` antes de qualquer commit de chrome. `tests/fixtures/golden-sh/` permanece **intocado** nesta fase — `tests/regress.sh capture` **NÃO** é executado.
- **D-13:** Warts do gerador preservados byte-a-byte: linha de `repo_url` com espaço à direita quando a variável é vazia, linha em branco final do heredoc em `generate-mkdocs.sh`. Editor que remove espaço à direita corrompe a saída em silêncio — conferir diff antes de commitar.

### Harness fail-closed

- **D-14:** `tests/fail-closed.sh` — gate automatizado de CHROME-03/CHROME-04. Toda mutação de catálogo acontece em cópia sob `mktemp -d` (nunca muta a árvore de trabalho). Pin de locale `LC_ALL=C.UTF-8`. NÃO wired no fluxo de release nesta fase — isso é da Phase 4.

### Dispatch do agent e READMEs

- **D-15:** `agents/format-mkdocs.md` transmite `OUTPUT_LANG` como argumento posicional nos dois call sites (`generate-index` e `generate-mkdocs`), **nunca por ambiente**. O script falha com idioma ausente ou inválido — o agent precisa saber que não existe fallback.
- **D-16:** Afirmação de paridade incondicional de argumentos posicionais `.sh`/`.ps1` é corrigida nos dois READMEs para registrar a divergência temporária vigente (Phase 4 resolve). É correção de fato, não documentação de release.

### Proibições

- Nenhum golden de `tests/fixtures/golden-sh/` é reescrito nesta fase
- Nenhuma chave `pt-br` e nenhuma tradução entram nesta fase (Phase 3)
- Nenhuma dependência nova de runtime (bash + coreutils apenas; os `.lang` são arquivos de dados)
- Nenhum default de idioma no script, nenhum env var de idioma lido
- Nenhum heredoc convertido para a forma com aspas (`<<'EOF'`) — o quoting bloquearia a expansão das variáveis de catálogo
- Nenhuma transformação de case em runtime sobre chrome — nenhuma variável de catálogo atravessa o sed de title-case

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requisitos & roadmap

- `.planning/REQUIREMENTS.md` — CHROME-01, CHROME-03, CHROME-04 (critérios desta fase); §Out of Scope (fallback silencioso, condicionais inline, deps novas)
- `.planning/ROADMAP.md` §Phase 2 — os 4 success criteria que esta fase entrega

### Fonte de extração dos valores `en`

- `docs/chrome-inventory.md` — mapa chave→sítio (`arquivo:linha`) com valores verbatim; **fonte canônica** para extração; onde a seed e os scripts divergem, os scripts vencem
- `scripts/generate-index.sh` — 29 chaves consumidas; sítios de extração documentados no inventário
- `scripts/generate-mkdocs.sh` — 3 chaves consumidas (`site_name_suffix`, `site_description`, `nav_home`)
- `scripts/to-pdf.sh` — sítio de `pdf_title` (Phase 3 consome; esta fase extrai verbatim)
- `templates/swagger-ui.html` — sítio de `swagger_title_suffix` (Phase 3 consome; esta fase extrai verbatim)

### Contexto da fase anterior

- `.planning/phases/01-contrato-golden-fixtures/01-CONTEXT.md` — decisões D-01 a D-12 da Phase 1; D-12 registra `templates/index.md` como unconsumed
- `tests/fixtures/manifest.md` — pins canônicos da invocação dos scripts no harness (args, cwd, valores)
- `tests/fixtures/golden-sh/` — goldens byte-idênticos que esta fase não deve modificar

### Contrato da skill

- `CONTEXT.md` — tabela §Variables (`OUTPUT_LANG`), §Script-call convention; mecanismo de transmissão por dispatch prompt
- `agents/format-mkdocs.md` — dispatch prompt que transmite `OUTPUT_LANG` para os dois call sites

### ADRs & instrumento de qualidade

- `docs/adr/0003-mkdocs-chain-repair.md` — host sem engines; gates estruturais no interim
- `docs/adr/0004-script-primary-pdf.md` — cadeia PDF script-primary
- `docs/skill-quality-rubric.md` — todo arquivo de skill tocado passa por auditoria delta com este rubric

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `tests/regress.sh` — harness existente; a invocação de `generate-index.sh` precisa ganhar `en` como terceiro posicional; `generate-mkdocs.sh` ganha `en` no plano 02-02
- `docs/chrome-inventory.md` — mapa completo de 33 chaves com valores verbatim e sítios exatos; é a fonte direta de extração
- `tests/fixtures/tree/.specs` — árvore de entrada para as sondas do `tests/fail-closed.sh`

### Established Patterns

- Bootstrap de catálogo em `generate-index.sh` (plano 02-01) é o padrão provado; `generate-mkdocs.sh` (plano 02-02) **replica** esse padrão exato — scripts são autocontidos, nenhum faz source de outro
- Fail-closed com `:?` no bash: padrão já validado no contrato da skill para `OUTPUT_LANG`; estende-se às chaves do catálogo
- `BASH_SOURCE[0]` para derivar `SCRIPT_DIR` — path relativo ao script, não ao cwd do chamador

### Integration Points

- `agents/format-mkdocs.md` → `scripts/generate-index.sh` e `scripts/generate-mkdocs.sh`: dispatch prompt transmite `OUTPUT_LANG` como terceiro posicional (plano 02-01 cobre generate-index; plano 02-02 cobre generate-mkdocs)
- `tests/regress.sh` → `scripts/generate-index.sh` e `scripts/generate-mkdocs.sh`: harness passa `en` explicitamente e diffa contra `tests/fixtures/golden-sh/` (golden intocado)
- `templates/lang/en.lang` → todos os scripts da cadeia: consumido por `set -a; . "$CATALOG"; set +a` com path derivado de `${BASH_SOURCE[0]}`

</code_context>

<specifics>
## Specific Ideas

- O plano 02-01 é tracer: prova a perna `generate-index.sh` ponta a ponta (catálogo → lookup → diff byte-idêntico) antes de qualquer outra parte da cadeia ser tocada. O plano 02-02 **replica o padrão provado**, não abre nova arquitetura.
- `generated_by` é caso especial: o valor do catálogo contém `%s` que é o specifier da data no `printf`; o valor deve ser passado NA POSIÇÃO de format string (com aspas duplas), não como argumento.
- `cell_absent` é o glifo emitido quando o arquivo não existe (`—`); entra no catálogo para que a Phase 3 possa trocá-lo se necessário (embora o valor seja o mesmo em qualquer idioma).
- As descrições das linhas da tabela Overview (`desc_project_overview`, `desc_roadmap`, `desc_architecture`) estão no inventário como valores verbatim — são texto puro sem link, entram como chaves normais.

</specifics>

<deferred>
## Deferred Ideas

None — discussão permaneceu dentro do escopo da fase.

</deferred>

---

*Phase: 2-Catálogo de Labels & Cadeia MkDocs/index*
*Context gathered: 2026-09-29*
