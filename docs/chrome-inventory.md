# Inventário de chrome — mapa chave → sítio

Date: 2026-09-29 · Status: accepted · Source: audited against scripts @ `11d2b7a`

Este documento É o mapa de todo o chrome publicado da skill: cada linha liga a chave futura do catálogo de labels (`templates/lang/*.lang`, Phase 2) ao valor `en` atual, transcrito VERBATIM, e ao(s) sítio(s) `arquivo:linha` onde a string vive. Ele é a fonte da Phase 2 para a extração verbatim dos valores `en` e a base do rubric (`docs/skill-quality-rubric.md`) para auditar o par en/pt-br completo.

**Source of the keys:** a seed do glossário em `.claude/CLAUDE.md` (seção "Seed do glossário") — nenhuma chave foi inventada aqui. **Source of the values:** os scripts e templates citados, auditados por leitura linha a linha contra o commit do header. Onde a seed e os scripts divergem, os scripts vencem: são a fonte viva da saída, e a extração `en` da Phase 2 vem deles, não da seed.

**Exceção do plano `04-01`:** quatro chaves desta fase (`index_development_body`, `nav_issues`, `pdf_generated_on`, `label_references`) NÃO vieram da seed do glossário — a seed não as antecipava. A fonte `en` das três primeiras é o gêmeo `.ps1` citado na Camada 2 (`scripts/generate-index.ps1`, `scripts/generate-mkdocs.ps1`, `scripts/to-pdf.ps1`); a de `label_references` é o substantivo de seção que `agents/references.md` já usa como título da página de referências. O critério continua o mesmo: onde a seed e os scripts (ou o agent) divergem, os scripts/agent vencem.

Convenções: valor em code span = texto byte-exato emitido hoje; sítios separados por `·`; divergências entre gêmeos `.sh`/`.ps1` estão **marcadas**, nunca silenciadas. Idiomas: prosa em PT-BR, valores `en` em inglês (são a saída de hoje).

**Fronteira label/markup (decidida na Phase 2).** O valor de cada chave carrega o TEXTO DO RÓTULO. O prefixo `## ` de heading, os separadores de tabela (`|---------|`) e os pipes de coluna são MARKUP: ficam no format string do `printf`/heredoc do gerador, nunca dentro do valor da chave. Exceção deliberada: as chaves de corpo de seção (`index_architecture_body`, `index_getting_started_body`) e `generated_by` carregam a FRASE INTEIRA — link markdown e URL incluídos — porque frase inteira é a unidade de tradução; fragmentar uma frase em torno de um link é anti-padrão de i18n. Os paths dentro desses links são estrutura e permanecem idênticos em qualquer idioma. `templates/lang/en.lang` é a materialização deste mapa: cada chave da Camada 1 listada abaixo tem uma linha correspondente lá, com o mesmo valor verbatim.

## Camada 1 — cadeia `.sh` (chrome congelável por golden)

Superfícies cobertas: `index.md` + `mkdocs.yml` + nav, livro-PDF (fallback markdown), DokuWiki README.

| Chave | Valor `en` atual (verbatim) | Sítio |
|-------|------------------------------|-------|
| `site_name_suffix` | `— Specifications` (em `# $PROJECT_NAME — Specifications` / `site_name: $PROJECT_NAME — Specifications`) | scripts/generate-index.sh:32 · scripts/generate-mkdocs.sh:43 |
| `site_description` | `Auto-generated documentation from spec-driven development` | scripts/generate-mkdocs.sh:44 |
| `nav_home` | `Home` (em `- Home: index.md`) | scripts/generate-mkdocs.sh:59 |
| `index_tagline` | `Auto-generated documentation from spec-driven development sessions.` | scripts/generate-index.sh:34 |
| `section_quick_start` | `## Quick Start` | scripts/generate-index.sh:45 |
| `section_overview` | `## Overview` | scripts/generate-index.sh:52 (ramo stakeholder) · scripts/generate-index.sh:60 (ramo general) |
| `section_features` | `## Features` (com headers `\| Feature \| Spec \| Design \| Tasks \|` na mesma linha) | scripts/generate-index.sh:73 |
| `section_architecture` | `## Architecture` | scripts/generate-index.sh:90 |
| `section_getting_started` | `## Getting Started` | scripts/generate-index.sh:95 |
| `section_development` | `## Development` | scripts/generate-index.sh:102 |
| `label_project_overview` | `Project Overview` | scripts/generate-index.sh:41,49,56 |
| `label_stack` | `Stack` | scripts/generate-index.sh:43 |
| `label_conventions` | `Conventions` | scripts/generate-index.sh:44 |
| `label_roadmap` | `Roadmap` | scripts/generate-index.sh:50,57 |
| `label_state_decisions` | `State & Decisions` | scripts/generate-index.sh:51 |
| `label_setup_guide` | `Setup Guide` | scripts/generate-index.sh:100 |
| `label_contributing` | `Contributing` | scripts/generate-index.sh:101 |
| `label_architecture` | `Architecture` | scripts/generate-index.sh:42,58 |
| `table_section` / `table_description` | `\| Section \| Description \|` | scripts/generate-index.sh:60 |
| `table_feature` / `table_spec` / `table_design` / `table_tasks` | `Feature` / `Spec` / `Design` / `Tasks` (headers da tabela Features) | scripts/generate-index.sh:73 |
| (rows da tabela Overview) | `Vision, goals, and scope` · `Features and milestones` · `System architecture` | scripts/generate-index.sh:56-58 |
| `index_architecture_body` | `Refer to the [Architecture](specs/codebase/ARCHITECTURE.md) document for system design and component relationships.` | scripts/generate-index.sh:90 |
| `index_getting_started_body` | `For installation instructions, see the [Project Overview](specs/project/PROJECT.md).` | scripts/generate-index.sh:95 |
| `generated_by` | `Generated by [md-to-wiki](https://github.com/abertanha/md-to-wiki-docs-skills) — %s` (o `%s` é `$(date +%Y-%m-%d)` — ISO 8601) | scripts/generate-index.sh:105 |
| `pdf_title` | `# Specifications` | scripts/to-pdf.sh:14 |
| `dokuwiki_readme` | Bloco `# DokuWiki Import Instructions` + 4 passos + `Generated by md-to-wiki skill set` | scripts/to-dokuwiki.sh:29-38 |

Observação: os labels derivados de nome de diretório (`## Quick Start`, labels de nav em `generate-mkdocs.sh:29,35` e células da tabela Features em `generate-index.sh:79-80`) passam pelo sed title-case `sed 's/-/ /g; s/\b\(.\)/\u\1/g'` — não são chaves fixas do catálogo; são transformação sobre nome de diretório (comportamento congelado pelo golden, não traduzível por label map).

## Camada 2 — gêmeos `.ps1` (mesmas chaves, sítios e strings divergentes)

Os gêmeos PowerShell emitem chrome próprio; divergências contra a Camada 1 estão marcadas em **negrito** e são congeladas por golden próprio (nunca combinadas com o `.sh`).

| Chave | Sítio `.ps1` | Divergência vs `.sh` |
|-------|---------------|----------------------|
| `site_name_suffix` | scripts/generate-index.ps1:23 · scripts/generate-mkdocs.ps1:46 | igual |
| `site_description` | scripts/generate-mkdocs.ps1:47 | igual |
| `nav_home` | scripts/generate-mkdocs.ps1:17 | igual |
| `index_tagline` | scripts/generate-index.ps1:25 | igual |
| `section_overview` (+ tabela + rows) | scripts/generate-index.ps1:34-40 | rows emitidas incondicionalmente (sem checagem de existência por arquivo) |
| `section_features` (+ headers) | scripts/generate-index.ps1:48-51 | headers iguais; **células divergem** — `[$name]($spec)` em todas as colunas, label = nome do diretório, sem checagem de existência (scripts/generate-index.ps1:58) |
| `section_architecture` (+ body) | scripts/generate-index.ps1:65,67 | body igual |
| `section_getting_started` (+ body) | scripts/generate-index.ps1:74,76 | body igual |
| `section_development` (prose) | scripts/generate-index.ps1:78-80 | convergiu nesta fase (04-01) por fonte única — a prosa passou a carregar a chave `index_development_body`, materializada nos dois catálogos |
| `generated_by` | scripts/generate-index.ps1:84 | convergiu nesta fase (04-01) por fonte única — o gêmeo passou a ler `generated_by` do catálogo; a URL divergente (`https://opencode.ai`) desapareceu por construção |
| `pdf_title` | scripts/to-pdf.ps1:19 | igual |
| `pdf_generated_on` (exclusiva do `.ps1`) | scripts/to-pdf.ps1:21 | convergiu nesta fase (04-01) — deixou de ser divergência inventariada e passou a ser a chave `pdf_generated_on`, materializada nos dois catálogos (sem consumidor `.ps1` ainda; o gêmeo `to-pdf.ps1` é escopo do plano `04-03`) |
| `dokuwiki_readme` | scripts/to-dokuwiki.ps1:36-45 | igual |
| `nav_issues` (exclusiva do `.ps1`) | scripts/generate-mkdocs.ps1:41 | convergiu nesta fase (04-01) — deixou de ser divergência inventariada e passou a ser a chave `nav_issues`, materializada nos dois catálogos (sem consumidor `.ps1` ainda; o gêmeo `generate-mkdocs.ps1` é escopo do plano `04-03`) |

## Camada 3 — templates

| Chave | Sítio | Valor `en` (verbatim) | Status |
|-------|-------|------------------------|--------|
| `swagger_title_suffix` | templates/swagger-ui.html:6 | `<title>{{PROJECT_NAME}} — API Docs</title>` (o placeholder `{{OPENAPI_YML}}` está na linha 18) | **vivo** — consumido por agents/format-swagger.md:67-70 |
| ~~(espelho das chaves de index)~~ | ~~templates/index.md~~ | ~~paralelo morto, nunca consumido~~ | **removido** — arquivo deletado via `git rm` na Phase 2 (commit `37c87bd`) |

Nota sobre `templates/index.md` (D-12): decisão resolvida na Phase 2 — o arquivo foi removido (`git rm`, commit `37c87bd`) porque grep em `agents/`, `scripts/`, `SKILL.md` e `CONTEXT.md` não encontrava nenhum consumidor (o `generate-index.sh` usa heredoc próprio, Camada 1) e a Phase 2 extraiu os valores `en` **dos scripts** (fonte viva) para `templates/lang/en.lang`, nunca deste template.

## Camada 4 — prosa de chrome escrita por agents em runtime

Chrome autoral de LLM na execução — **sem golden por construção** (não é capturável por diff); inventariado apenas para delimitar o alcance do catálogo da Phase 2.

| Sítio | Chrome | Superfície |
|-------|--------|------------|
| agents/format-github-wiki.md:47-53 | Nomes de arquivo `Home.md`, `_Sidebar.md`, `_Footer.md` e diretórios de seção `Project/`, `Architecture/`, `Features/`, `Quick-Tasks/` | GitHub Wiki |
| agents/format-swagger.md:32-34 | `title: "{{PROJECT_NAME}} — API Specs"` e `description: "Auto-generated from spec-driven development markdowns"` (esqueleto do openapi.yml) | Swagger |
| agents/format-swagger.md:45 | `description: "Success"` (resposta canônica do esqueleto) | Swagger |
| agents/format-mkdocs.md · format-dokuwiki.md · format-pdf.md | Nenhum chrome próprio — orquestram os scripts; os headings do livro vêm de `basename` do arquivo (passthrough, não é label) | — |
| agents/references.md | Título da página de referências gerada por formato (`docs/references.md`, `wiki/References.md`, `references.txt`, apêndice do PDF) — chrome autoral, materializado nesta fase (04-01) como a chave `label_references` | MkDocs · Swagger · GitHub Wiki · DokuWiki · PDF |
