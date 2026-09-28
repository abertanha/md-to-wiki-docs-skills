<!-- GSD:project-start source:PROJECT.md -->

## Project

**md-to-wiki**

md-to-wiki é uma skill opencode que transforma árvores de documentação spec-driven (`.specs`) em destinos publicáveis — site MkDocs Material, GitHub Wiki, DokuWiki, livro PDF e página Swagger UI — com enriquecimento de referências via issues do GitHub e deploy verificado. Este milestone adiciona suporte a idioma de saída: PT-BR como default, inglês preservado.

**Core Value:** Qualquer árvore de specs vira documentação publicável com um comando — de forma previsível.

### Constraints

- **Compatibilidade**: saída com `OUTPUT_LANG=en` byte-idêntica à atual — protege quem já usa a skill em inglês
- **Metodologia**: toda mudança passa pelo gate MET-1 (custo permanente por execução vs ganho de previsibilidade); sem portar padrões sem necessidade demonstrada
- **Stack**: bash + markdown; nenhuma dependência nova de runtime
- **Idioma**: docs e saída em PT-BR sem calques ("deployar", "printar", "commitar"); termo técnico fica em inglês integral ou usa equivalente consagrado; glossário canônico manda
- **Git**: todo o trabalho no branch `ft/gsd-pattern-align` (decisão do usuário); merge ao final das feats

<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->

## Technology Stack

## Recommended Stack

### Core Technologies (mecanismos)

| Mecanismo | "Versão" | Propósito | Por quê | Confiança |
|-----------|----------|-----------|---------|-----------|
| **Label maps `KEY=value`** em `templates/lang/en.lang` e `templates/lang/pt-br.lang` | — | Fonte única de rótulos de chrome para os 5 destinos e para os 2 hosts de script | Formato `KEY=value` é o ponto de encontro mínimo entre bash (`set -a; . file`) e PowerShell (`ConvertFrom-StringData` sobre `Get-Content -Encoding UTF8`); reproduz a arquitetura gettext (chave estável + fallback para o idioma-fonte) sem binários, sem compilação e sem detecção de locale. Padrão de comunidade consolidado, embora sem spec formal | MEDIUM (padrão de comunidade, multi-fonte) |
| **`OUTPUT_LANG` na camada de contrato (`CONTEXT.md` + `agents/onboarding.md`)** | v1: `en` \| `pt-br` | Parametrização explícita, default `pt-br` | Mesmo mecanismo já validado no milestone de qualidade (variáveis vivem no contrato, o agente de onboarding é o único ponto de atribuição). BCP 47/RFC 5646: matching é case-insensitive; normalizar internamente em minúsculas (`en`, `pt-br`) e projetar para a forma canônica de cada consumidor só no ponto de uso | HIGH (arquitetura do próprio projeto + RFC 5646 verificada, MEDIUM na parte BCP 47) |
| **MkDocs Material `theme.language: pt-BR`** | mkdocs-material 9.x | Traduz o chrome do tema (placeholder de busca, prev/next, footer, clipboard) | Nativo, sem plugin: o Material ships traduções de template em 60+ idiomas, incluindo `pt` e `pt-BR`. `site_name` (sufixo "— Specifications"), `site_description` e o item de nav `Home` são **nossas** strings → label map | HIGH (docs oficiais) |
| **pandoc `-M lang=pt-BR -M toc-title=Sumário`** | pandoc atual (suporte de longa data) | Superfície PDF: hifenização babel/polyglossia, datas/aspas localizadas, título do sumário | `lang` (BCP-47) alimenta babel/polyglossia no LaTeX e vira atributo `lang` no HTML; `toc-title` é a variável oficial do título do ToC (EPUB, HTML, revealjs, odt, docx, pptx, beamer, LaTeX). No WeasyPrint, `lang` + `hyphens: auto` ativa hifenização via dicionário `pt_BR` do Pyphen (incluído) | HIGH (manual oficial + cruzado) |
| **Swagger UI: traduzir só o que o template controla** | swagger-ui atual | Title/intro da página standalone | Swagger UI **não tem i18n oficial** (issue #472 aberta há anos; config docs sem opção de locale; o `/lang` pré-3.x caiu no rewrite React). Forkar para traduzir "Authorize"/"Try it out" viola o gate MET-1. Localiza-se apenas `<title>{{PROJECT_NAME}} — …</title>` e eventuais headings do template — via label map; o chrome do bundle fica em inglês e isso fica **documentado** no CONTEXT.md | HIGH (claim negativa verificada em docs oficiais + issue) |
| **Convenção de prosa + glossário anti-calque no `CONTEXT.md`** | — | Regir a prosa PT-BR escrita pelos agents (sem "deployar", "printar", "commitar"; sem tiques de LLM) | Determinístico e auditável (decisão já registrada no PROJECT.md). Ancorado nas referências da seção abaixo; o glossário manda sobre a prosa | HIGH (decisão de projeto) / MEDIUM (URLs das referências) |
| **Disciplina de encoding UTF-8 nos 2 hosts** | PS 5.1 e 7; GNU coreutils | Não corromper acentuação nem quebrar a regressão `en` | PS 5.1: `Out-File -Encoding UTF8` grava **com BOM**, `>` grava UTF-16LE, `Get-Content` sem BOM assume ANSI, e o motor lê script BOM-less como ANSI (acentos exigem UTF-8 **com BOM** no `.ps1` em si). PS 7+: `utf8NoBOM` em tudo. Bash: arquivos de labels UTF-8 sem BOM; **nunca** capitalizar label via `sed '\u'` (em locale C só converte ASCII) | HIGH (about_Character_Encoding oficial; sed: MEDIUM, corroboração de mantenedor coreutils) |

### As referências PT-BR que fundamentam o glossário (o "stack" de estilo)

| Referência | Papel | Confiança / Status |
|------------|-------|-------------------|
| **Novo Manual da Redação da Folha** (Folha de S.Paulo) | A referência clássica de estilo em PT-BR, incluindo regras de estrangeirismo (quando manter o termo em inglês, quando aportuguesar). Base para a regra "termo técnico fica em inglês integral ou usa equivalente consagrado" | HIGH como referência; a edição online oficial é instável — tratar o livro como forma canônica |
| **Manual de Redação e Estilo de O Estado de S. Paulo** (Eduardo Martins, 3ª ed.) | Contraponto consagrado ao da Folha; útil para desempate em estilo | HIGH como referência; PDF da 3ª ed. circula publicamente |
| **Microsoft Writing Style Guide** (learn.microsoft.com/style-guide) + **Localization Style Guides por idioma** (hub Globalization → "Microsoft language resources") | O padrão de facto para documentação técnica de software; o hub publica **style guide de localização por idioma (inclui Português–Brasil)** + Terminology (busca e coleção .tbx) para consulta de forma canônica de termos técnicos | HIGH (hub verificado); o Writing Style Guide em si **não** tem edição pt-BR (a URL pt-br serve o conteúdo EN) — usar o guia de localização pt-BR, não esperar tradução do guia geral |
| **VOLP (ABL)** como regra de desempate verificável | "Equivalente consagrado" vira checável: se a forma aportuguesada não está no VOLP, o termo fica em inglês integral | MEDIUM (mecanismo proposto aqui, não prescrito pelas fontes) |
| **Google developer documentation style guide** (developers.google.com/style) | Secundário: estrutura de doc técnica e "write for a global audience" | MEDIUM — **sem edição pt-BR oficial**; usar para forma, não para terminologia |

### Seed do glossário (mapeamento dos rótulos hardcoded de hoje)

| Chave | `en` (byte-idêntico ao atual) | `pt-br` (proposta) |
|-------|-------------------------------|--------------------|
| `site_name_suffix` | `— Specifications` | `— Especificações` |
| `site_description` | `Auto-generated documentation from spec-driven development` | `Documentação gerada automaticamente a partir de desenvolvimento spec-driven` |
| `nav_home` | `Home` | `Início` |
| `index_tagline` | `Auto-generated documentation from spec-driven development sessions.` | `Documentação gerada automaticamente a partir de sessões de desenvolvimento spec-driven.` |
| `section_quick_start` | `Quick Start` | `Início Rápido` |
| `section_overview` | `Overview` | `Visão Geral` |
| `section_features` | `Features` | `Funcionalidades` |
| `section_architecture` | `Architecture` | `Arquitetura` |
| `section_getting_started` | `Getting Started` | `Primeiros Passos` |
| `section_development` | `Development` | `Desenvolvimento` |
| `label_project_overview` | `Project Overview` | `Visão Geral do Projeto` |
| `label_stack` | `Stack` | `Stack` (consagrado; fica) |
| `label_conventions` | `Conventions` | `Convenções` |
| `label_roadmap` | `Roadmap` | `Roadmap` (consagrado; fica) |
| `label_state_decisions` | `State & Decisions` | `Estado e Decisões` |
| `label_setup_guide` | `Setup Guide` | `Guia de Configuração` |
| `label_contributing` | `Contributing` | `Contribuição` |
| `table_section` / `table_description` | `Section` / `Description` | `Seção` / `Descrição` |
| `table_feature` / `table_spec` / `table_design` / `table_tasks` | `Feature` / `Spec` / `Design` / `Tasks` | `Funcionalidade` / `Especificação` / `Design` (fica) / `Tarefas` |
| `index_architecture_body` | `Refer to the [Architecture](…) document for system design…` | frase inteira traduzida (ver regra abaixo) |
| `index_getting_started_body` | `For installation instructions, see the [Project Overview](…).` | frase inteira traduzida |
| `generated_by` | `Generated by [md-to-wiki](…) — %s` | `Gerado por [md-to-wiki](…) — %s` |
| `pdf_title` | `Specifications` | `Especificações` |
| `pdf_toc_title` | (não passado hoje; default LaTeX `Contents`) | `Sumário` |
| `swagger_title_suffix` | `API Docs` | `Documentação da API` |

### Emissão por superfície (regra "aditiva-só-quando-não-default")

| Superfície | `OUTPUT_LANG=en` (regressão) | `OUTPUT_LANG=pt-br` |
|------------|------------------------------|---------------------|
| `generate-mkdocs.sh` → mkdocs.yml | **omite** a chave `language:` (o default do Material já é `en` — hoje o arquivo não tem a chave; emitir `language: en` mudaria bytes do mkdocs.yml). Rótulos de `en.lang` | adiciona `language: pt-BR` sob `theme:`; `site_name`/`site_description`/`Home` de `pt-br.lang` |
| `generate-index.sh` → index.md | valores `en.lang` (idênticos aos atuais) | valores `pt-br.lang` |
| `to-pdf.sh` | não passa `-M lang`/`-M toc-title` (como hoje) | `-M lang=pt-BR -M toc-title=Sumário` (hifenização babel/Pyphen, datas localizadas) |
| `templates/swagger-ui.html` | `{{…}}` substituído por valores en | title/intro de `pt-br.lang`; chrome do bundle permanece EN (sem i18n oficial) |
| GitHub Wiki / DokuWiki (agents) | headings/sidebar de chrome em en | chrome de `pt-br.lang`; conteúdo dos specs intocado |
| `.ps1` companions | leitura `Get-Content -Encoding UTF8` sobre `.lang`; gravação BOM-less (`[System.IO.File]::WriteAllText` com `UTF8Encoding($false)` — portável 5.1/7) | idem; o `.ps1` em si, se carregar acentos, precisa ser UTF-8 **com BOM** para o 5.1 ler corretamente |

### Development Tools

| Tool | Propósito | Notas |
|------|-----------|-------|
| Fixture + `diff`/`sha256sum` da saída `en` | Barra de regressão byte-idêntica (requisito ativo do PROJECT.md) | Rodar antes/depois de cada mudança de script; vale para os 5 destinos |
| Auditoria delta com `docs/skill-quality-rubric.md` | Todo arquivo de skill tocado passa pelo rubric | Protocolo do milestone de qualidade (metodologia-constraints) |
| `locale -a` | **Não é necessário** — nenhum runtime detection | A ausência de detecção de locale também elimina a classe de bugs sed/locale |

## Installation

## Alternatives Considered

| Recomendado | Alternativa | Quando a alternativa faria sentido |
|-------------|-------------|-----------------------------------|
| Label maps `KEY=value` | **gettext/gettext.sh** | Se a skill fosse um binário C/Python multi-usuário com catálogos mantidos por terceiros — requer `msgfmt` + binários GNU gettext, compilação .po→.mo, e detecção de locale via `LANGUAGE`/`LC_ALL`/`LC_MESSAGES`/`LANG` (precedência que **conflita** com parametrização explícita `OUTPUT_LANG`); sem equivalente em PowerShell. Para substituição em tempo de geração com ~30 chaves, é toolchain sem ganho |
| `theme.language` nativo | **mkdocs-static-i18n 1.3.1** (ativo; tag 2026-02-20) | Se um milestone futuro quiser **site bilíngue com seletor de idioma** (build default + `/pt/` por idioma, fallback automático). Para um idioma por build, adiciona plugin + complexidade de build por benefício zero — e viola a constraint de dependência |
| `KEY=value` | **YAML catalogs estilo Rails** (`pt-BR: {nav: {home: Início}}`) | A ideia boa (escopo por namespace, fallback-map) já foi absorvida no desenho das chaves planas; YAML exigiria parser em bash/PS (dependência nova). Adotar do Rails apenas o princípio: frase inteira como unidade, fallback explícito |
| `KEY=value` + `ConvertFrom-StringData` | **JSON catalogs estilo Docusaurus** (`navbar.json` etc.) | JSON nativo no PS mas exige `jq`/python no bash (dependência). O padrão arquitetural do Docusaurus — chrome separado de conteúdo, catálogo por locale, en como default — é o que replicamos em miniatura |
| `OUTPUT_LANG` explícito | **Auto-detecção via `$LANG`/`LC_ALL`** | Nunca neste projeto — já rejeitada no questioning (frágil, imprevisível); a fila `LANGUAGE→LC_ALL→LC_MESSAGES→LANG` do gettext é exatamente o tipo de variável implícita que o contrato exists para eliminar |
| Traduzir só o template own strings | **Fork do Swagger UI** (patch das strings React) | Custo permanente de manutenção do fork vs. ganho cosmético — reprova no MET-1 |

## What NOT to Use

| Evitar | Por quê | Usar em vez |
|--------|---------|-------------|
| gettext / gettext.sh / `.mo` | Toolchain binário, passo de compilação, detecção de locale por env-vars, zero porta para PowerShell | Label maps `KEY=value` sourced/parsed |
| mkdocs-static-i18n (neste milestone) | Projetado para sites multi-idioma; aqui cada build é monolíngue; quebra a constraint de dependência | `theme.language` nativo + emissão aditiva |
| Detecção runtime de locale (`$LANG`, `Accept-Language`) | Im previsível; rejeitada no questioning do projeto | `OUTPUT_LANG` explícito na camada de contrato |
| Frameworks i18n (Babel, i18next, etc.) | Dependência nova de runtime; a skill gera artefatos, não serve UI interativa | Label maps + convenção de prosa |
| `sed '\u'/'\U'` para capitalizar chrome | Só converte ASCII em locale C; comportamento depende do locale do host → não-determinismo e acento minúsculo | Label pré-capitalizado no `.lang` |
| `Out-File -Encoding UTF8` / `>` no PS 5.1 para gravar saída gerada | 5.1 grava **BOM** (UTF8) ou UTF-16LE (`>`); BOM quebra diff byte-idêntico e ferramentas Unix | `[System.IO.File]::WriteAllText` com `UTF8Encoding($false)` (funciona em 5.1 e 7) |
| Traduzir conteúdo dos specs | A skill transforma fontes, não reescreve autoria (Out of Scope do PROJECT.md) | Chrome + prosa de chrome apenas; conteúdo intocado |
| `learn.microsoft.com/pt-br/style-guide` como guia pt-BR | URL serve o conteúdo **inglês** (verificado: canonical en-us) | Microsoft **Localization Style Guide** Português (Brasil) do hub Globalization + Terminology Search |

## Stack Patterns by Variant

- Carregar só `en.lang`; **omitir** chaves de idioma em tudo que hoje não as tem (`theme.language`, `-M lang`, `-M toc-title`)
- Porque: qualquer linha extra quebraria o diff byte-idêntico do fixture — a regressão é o requisito, não um desejo
- Emissão aditiva em todas as superfícies: `language: pt-BR` no mkdocs.yml, `-M lang=pt-BR -M toc-title=Sumário` no pandoc, labels de `pt-br.lang` nos demais
- Formas canônicas por consumidor: mkdocs `pt-BR` \| pandoc `pt-BR` \| Pyphen/WeasyPrint `pt_BR` \| HTML `lang` `pt-BR` (a projeção acontece em UMA tabela no ponto de uso, não espalhada)
- Erro imediato com lista de valores suportados (fail-closed). Previsibilidade > conveniência; coerente com o MET-1
- Primeiro entra em `en.lang` (com o valor que seria o hardcoded), depois em `pt-br.lang` no mesmo commit; chave órfã em pt-br cai no en por fallback, mas o par completo é o que o rubric audita

## Version Compatibility

| Componente | Compatível com | Notas |
|------------|----------------|-------|
| `theme.language: pt-BR` | mkdocs-material 9.x | `pt-BR` é locale built-in das 60+ traduções de template; default do Material é `en` (por isso omitir a chave em en = byte-idêntico). O seletor "stay on page" do 9.7.0 é experimental e multilíngue — fora de escopo |
| mkdocs-static-i18n 1.3.1 | (não usar) | Última tag 2026-02-20; compatível com Material; reservado a hipotético milestone multi-idioma |
| pandoc `lang`/`toc-title` | pandoc ≥ 2.x corrente | `toc-title` cobre EPUB, HTML, revealjs, odt, docx, pptx, beamer, LaTeX; `lang` alimenta babel/polyglossia e o atributo `lang` do HTML intermediário do WeasyPrint |
| WeasyPrint + Pyphen | WeasyPrint atual | Hifenização automática exige `lang` no documento **e** dicionário Pyphen — `pt_BR` incluído (underscore); `hyphens: auto` no CSS; aspas geradas por CSS **não** implementadas |
| `.lang` no PS 5.1 | Windows PowerShell 5.1, PowerShell 7+ | Ler com `Get-Content -Encoding UTF8`; gravar saída com `UTF8Encoding($false)`; o próprio `.ps1` contendo acentos deve ser UTF-8 com BOM (5.1 lê BOM-less como ANSI) |
| `.lang` no bash | bash 3.2+ (macOS) / GNU bash | `set -a; . templates/lang/pt-br.lang; set +a` — formato estrito `KEY=value`, sem expansão de shell; arquivos UTF-8 sem BOM |

## Sources

- MkDocs Material — Changing the language (squidfunk.github.io/mkdocs-material/setup/changing-the-language/) — `theme.language`, 60+ locales incl. pt-BR, default en, override via custom.html com fallback en — HIGH
- mkdocs-static-i18n — GitHub tags ultrabug/mkdocs-static-i18n (1.3.1, 2026-02-20) + docs home (multi-lang build, fallback, compat Material) — MEDIUM/HIGH
- pandoc User's Guide (pandoc.org/MANUAL.html) + issue jgm/pandoc#3318 — `toc-title` (formatos suportados), `-M/--metadata`, `lang`→babel/polyglossia — HIGH (cruzado)
- WeasyPrint docs (doc.courtbouillon.org/weasyprint/stable/api_reference.html) + Pyphen (pyphen.org) — `hyphens*` suportados, exigência de `lang` + dicionário, `pt_BR`/`pt_PT` incluídos (underscore), quotes não implementadas — MEDIUM/HIGH
- Docusaurus i18n Introduction (docusaurus.io/docs/i18n/introduction) — layout `i18n/[locale]/[plugin]`, JSON chrome (formato Chrome i18n), documentos traduzidos inteiros, default locale — HIGH (padrão de referência)
- Sphinx Intl docs (sphinx-doc.org/en/master/usage/advanced/intl.html) — workflow gettext completo + toolchain exigido (cautelar) — HIGH
- Rails i18n Guide (guides.rubyonrails.org/i18n.html) — YAML por locale, interpolação `%{name}`, fallbacks — HIGH (oficial; usado como princípio, não como ferramenta)
- GNU gettext (glibc manual, PHP gettext docs, Lokalise, Oracle msgen) — msgid como chave, cadeia LANGUAGE→LC_ALL→LC_MESSAGES→LANG, miss→msgid — MEDIUM (multi-fonte)
- RFC 5646 / IANA Language Subtag Registry — case-insensitive, convenção pt-BR, pt-BR≠pt-PT — MEDIUM
- swagger-api/swagger-ui issue #472 + config docs — sem i18n oficial; `/lang` pré-3.x removido — MEDIUM (claim negativa verificada contra docs)
- PowerShell about_Character_Encoding (learn.microsoft.com, versões 5.1–7.6) — encodings por cmdlet/versão, BOM, scripts não-ASCII — HIGH
- PT-BR: Novo Manual da Redação da Folha; Manual do Estadão (E. Martins); Microsoft Learn hub "Microsoft language resources" (Localization Style Guides + Terminology .tbx + UI strings); Writing Style Guide EN (canonical da URL pt-br: en-us); Google developers.google.com/style (sem edição pt-BR) — MEDIUM em URLs/edições, HIGH no estatuto das referências
- GNU coreutils/sed multibyte (crashcourse.housegordon.org/coreutils-multibyte-support.html) + prática `\u` em locale C — MEDIUM

### Gaps

- URL exata de download do Microsoft Localization Style Guide "Portuguese (Brazil)" não foi verificada diretamente (o hub language-resources foi; o estilo por idioma está a um link dali) — resolver no primeiro uso
- Edição online vigente do Manual da Folha instável — citar a obra, não a URL
- O padrão bash de label maps não tem spec/autoridade única — a validação real é o fixture de regressão + rubric, não a literatura

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
