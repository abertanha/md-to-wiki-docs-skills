# Project Research Summary

**Project:** md-to-wiki — milestone OUTPUT_LANG (idioma de saída: PT-BR default, `en` byte-idêntico)
**Domain:** Retrofit de i18n de chrome gerado sobre uma skill bash+markdown multi-destino em produção (5 superfícies: MkDocs Material, GitHub Wiki, DokuWiki, PDF, Swagger UI)
**Researched:** 2026-09-28
**Confidence:** HIGH no padrão governante e nos fatos do repo; MEDIUM pontual em detalhes de engine a verificar ao vivo (ver Confiança e Gaps)

## Executive Summary

Este milestone não é um produto novo — é o retrofit do recurso "single-locale chrome localization" sobre um gerador de documentação existente. A pesquisa (MkDocs Material, mkdocs-static-i18n, Docusaurus, Sphinx, Hugo, VitePress, gettext, Rails i18n) converge em três invariantes universais, todas confirmadas em 3+ fontes primárias independentes: **traduz-se o chrome (rótulos que a ferramenta gera), nunca o conteúdo (o que o usuário escreveu)**; **um idioma canônico por build**, expresso como um único parâmetro de topo; e **labels vivem em catálogos por idioma, nunca inline em código**. O v1 de `OUTPUT_LANG` é exatamente esse recurso padrão — não o recurso "site multilíngue com seletor" (D8), que fica para um milestone futuro.

A abordagem recomendada: `OUTPUT_LANG` (default `pt-br`, valor `en`) entra na camada de contrato (CONTEXT.md + agents/onboarding.md, hand-off por dispatch prompt como AUDIENCE — nunca env var); todo chrome de script/template resolve por chave contra **um catálogo único `KEY=value` por idioma** (UTF-8 sem BOM), lido pelos gêmeos `.sh`/`.ps1` e pelos templates; plumbing de idioma é **aditivo-só-quando-não-default** (`en` omite as chaves que hoje não existem — sem `language:` no mkdocs.yml, sem `-M lang` no pandoc; `pt-br` adiciona `theme.language: pt-BR`, `-M lang=pt-BR -M toc-title=Sumário`, `lang` no HTML). A barra objetiva do milestone é o **diff byte-idêntico do fixture `en` vazio**, e por isso a extração das strings en para o catálogo deve ser **mecânica** (nunca redigitada), sobre **golden fixtures congelados ANTES de qualquer refactor** (com o token de data mascarado e documentado no gate).

O risco central não é a tradução — é o refactor de extração quebrar a barra en por razões invisíveis (whitespace, BOM, CRLF, data), e o drift de labels entre os até 4 consumidores por superfície (`.sh`, `.ps1`, template, prosa de agent) — drift que **já existe hoje** entre os gêmeos (footer URL divergente, branches de audiência ausentes no `.ps1`). Mitigações: fixtures primeiro e por geminho; fonte única de labels desenhada antes de traduzir a segunda superfície; checkpoint duro isolando "extração mudou bytes?" de "tradução boa?"; inventário explícito das 4 camadas de chrome (script, theme, prosa de agent, console — console fica em inglês no v1, decisão explícita); fail-closed em chave ausente; disciplina de encoding PS 5.1 (mojibake/BOM) verificada por fixture com diretório acentuado; e o limite upstream do Swagger UI (sem i18n oficial) escopado ao título + atributo `lang` e documentado, não "resolvido" por hack.

## Key Findings

### Recommended Stack (mecanismos, não pacotes)

A skill é bash + markdown sem dependências novas de runtime — o "stack" aqui são mecanismos de substituição de rótulos em tempo de geração e de informação de locale a cada consumidor (detalhes e seeds do glossário em [STACK.md](STACK.md)).

**Mecanismos core:**
- **Label maps `KEY=value`** (`en` + `pt-br`, um arquivo por idioma) — ponto de encontro mínimo entre bash (`set -a; . file`) e PowerShell (`ConvertFrom-StringData`); reproduz a arquitetura gettext (chave estável) sem binários nem compilação. Unidade de tradução = **frase inteira** com placeholder posicional, nunca concatenação.
- **`OUTPUT_LANG` na camada de contrato** — mesmo mecanismo já validado no milestone de qualidade; normalização na entrada (BCP 47 é case-insensitive → token canônico interno minúsculo `pt-br`), projeção para a forma canônica de cada consumidor (`pt-BR` para Material/pandoc/HTML, `pt_BR` para Pyphen) **numa única tabela no ponto de uso**; valor desconhecido → erro imediato com lista de suportados.
- **`theme.language: pt-BR`** (mkdocs-material 9.x) — traduz todo o chrome do tema nativamente (60+ locales incl. pt-BR); `en` **omite** a chave (default do Material já é en).
- **pandoc `-M lang=pt-BR -M toc-title=Sumário`** — hifenização babel/polyglossia, datas/aspas localizadas no PDF; só no branch pt-br.
- **Swagger UI: só o que o template controla** — sem i18n oficial upstream (feature request aberto); escopo = `<title>` + `<html lang>` (hoje ausente — gap também no en); o chrome do bundle fica em inglês e isso fica **documentado** (candidato a ADR).
- **Glossário anti-calque no CONTEXT.md** — regido pelas referências de estilo PT-BR (Manual da Folha, Estadão, Microsoft Localization Style Guide pt-BR do hub Globalization + VOLP como desempate verificável); o glossário manda sobre a prosa dos agents.
- **Disciplina de encoding nos 2 hosts** — PS 5.1: `Get-Content -Encoding UTF8` na leitura, preservar o comportamento atual na escrita (en `.ps1` já emite BOM — o wart é preservado, não "consertado"), `.ps1` com acentos salvos UTF-8 **com BOM**; bash: UTF-8 sem BOM e **nunca** `sed '\u'` para capitalizar chrome (em locale C só converte ASCII — corrupção reproduzida neste host).

**O que NÃO usar:** gettext/gettext.sh (toolchain binário + detecção de locale por env que conflita com parametrização explícita), mkdocs-static-i18n (projetado para multi-idioma por build; frozen — é evidência de padrões, não candidata a dependência), auto-detecção via `$LANG`/`Accept-Language` (inferência, não fato; já rejeitada no questioning), frameworks i18n, forks do Swagger UI.

### Expected Features (detalhe em [FEATURES.md](FEATURES.md))

**Must have (table stakes, todas P1):**
- T1 `OUTPUT_LANG` único de topo, default `pt-br` documentado
- T2 normalização de locale (aceita `pt-br`/`pt-BR`; emite canônico; desconhecido → erro)
- T3 catálogo externo por idioma, **strings en extraídas verbatim** (a base de tudo)
- T4 cobertura completa de chrome nas 5 superfícies — zero saída mista (o defeito de i18n mais visível que existe)
- T5 fallback fail-closed (erro duro nomeando a chave; fallback silencioso É o mecanismo da saída mista)
- T6 `lang` plumbed (theme.language, pandoc lang, html lang)
- T7 regressão `en` byte-idêntica — a barra objetiva do milestone
- T8 títulos-nunca-paths (traduzir path/anchor/filename quebra links, slugs do GitHub Wiki e page IDs do DokuWiki)
- T9 fronteira chrome/conteúdo documentada no contrato

**Should have (dentro do v1):**
- D1 glossário anti-calque auditável — tecnicamente um diferenciador (nenhum gerador mainstream enforce qualidade de tradução), **promovido a requisito ativo do v1 pelo PROJECT.md**

**Defer (v1.x / v2+):**
- D2 mais locales (custo = 1 arquivo novo após T3), D3 nomes de nav derivados de diretório via mapping explícito do usuário (toca autoria — não é chrome), D4 tipografia PDF completa, D5 override por formato
- v2+: D7 catálogo extensível pelo usuário, D8 hreflang + language switcher (o recurso "multilingual site" — outro produto), D9 RTL, D6 datas/numbers por locale

**Anti-features (não construir):** machine-translation de conteúdo (A1), auto-detecção de idioma (A2), memória por usuário/run (A3), fallback silencioso en (A4), traduzir paths (A5), sufixos de locale nas fontes `page.pt-br.md` (A6), conditionais inline por idioma (A7 — multiplica 2 shells × N idiomas × labels e mata T7).

### Architecture Approach (detalhe em [ARCHITECTURE.md](ARCHITECTURE.md))

OUTPUT_LANG **não é uma nova camada** — é um novo valor fluindo pelas camadas existentes (ADR 0001/0002), mais um novo artefato de dados (o catálogo de labels) na borda determinística. Não re-arquitetar; estender.

**Componentes maiores:**
1. **Contrato** (CONTEXT.md + onboarding) — registra `OUTPUT_LANG` (valores, default, token canônico, tabela de mapping por consumidor) + seção de glossário; onboarding ganha o passo de entrevista (default pt-br quando indiferente).
2. **Catálogo de labels** (novo, fonte única de chrome) — `key=value` UTF-8 sem BOM, chaves namespaced por superfície; en extraído mecanicamente das strings atuais (âncora de regressão).
3. **Camada determinística** (scripts `.sh`/`.ps1` + templates) — recebem OUTPUT_LANG como **argumento posicional trailing** (nunca env var); resolvem cada chrome-string por chave; hard-fail em chave ausente.
4. **Camada de agents** (8 agents) — prosa regida pelo glossário do CONTEXT.md; nouns canônicos de seção vêm do **mesmo mapa** (terminologia idêntica nas 5 superfícies); regra de fronteira: "se a string nomeia uma superfície gerada, vem do mapa; se explica, segue o glossário".
5. **tests/** (novo) — golden fixtures en commitados no repo (capturados da cadeia **não modificada**, com tree de teste incluindo `features/autenticação/`) + harness `diff -r`/`cmp` que roda **sem engines** (o host dev não tem mkdocs/pandoc — ADR 0003).

**Padrões-chave:** catálogo de mensagens por locale (forma gettext/Rails); whole-string patterns com placeholder (word order pertence ao catálogo, não ao código); normalização na fronteira + fail-loudly (desvio deliberado e justificado do gettext); hand-off por dispatch prompt (ADR 0001).

**Anti-padrões evidenciados pelo próprio repo:** inline `case "$OUTPUT_LANG"` (os gêmeos `.sh`/`.ps1` JÁ divergem hoje — generate-index.ps1 sem o braço developer, footer apontando para opencode.ai vs github.com, mkdocs.yml em path diferente); fallback silencioso; env var ambiente; fragmentação de frases; en catalog redigitado à mão.

### Critical Pitfalls (top de 9 — detalhe em [PITFALLS.md](PITFALLS.md))

1. **O refactor de extração quebra a barra en byte-idêntica** (não a tradução: whitespace/BOM/CRLF/trailing newline, e o token de data do footer que nunca será estável) → congelar goldens por geminho ANTES de tocar em qualquer script; byte-compare (`cmp`); máscara de data documentada; regra de refactor: en só troca literal por lookup do mesmo literal.
2. **Drift do label-map entre consumidores — os gêmeos JÁ divergem hoje** → UMA tabela consumida por todos (sh, ps1, template, agents); barra honesta: byte-idêntico é **por geminho contra si mesmo atual** (paridade cross-shell nunca existiu — não prometer agora); lint de paridade estrutural.
3. **Tradução parcial → saída mista pt/en** → cada superfície tem 4 camadas de chrome (script, theme, prosa de agent, console); inventário arquivo:linha ANTES de traduzir; gate grep com allowlist do glossário; **console fica em inglês no v1** (decisão explícita, não esquecimento).
4. **PowerShell 5.1 corrompe acentos** (leitura UTF-8 sem BOM como ANSI → mojibake no PDF; `Out-File utf8` grava BOM; `.ps1` sem BOM parseado como ANSI) → pinning `-Encoding UTF8` na leitura; preservar o BOM existente no path en; `.ps1` com literais acentuados salvos com BOM; fixture com diretório acentuado pega os 3 modos de uma vez.
5. **`sed` title-case corrompe acentos em locale C** (verificado neste host: `autenticação` → bytes mutilados) + Title Case é estilo errado em PT-BR + labels derivados de nomes de arquivo são autoria do usuário, não chrome → derived-label = passthrough sem transformação de case; chrome pt-br nasce pré-capitalizado no catálogo; nenhuma transformação de case em runtime.

Demais pitfalls (com prevenção e fase em PITFALLS.md): fragmentação do tag de locale (P5, resolve no contrato), PDF pt-br com tipografia en e o fix apressado que quebra o en (P7 — `-M lang` SÓ no branch pt-br; assert estrutural do comando sem precisar de pandoc), calques na prosa dos agents (P8 — convenção precisa estar **inline no dispatch**, referência consultada sob demanda é ignorada sob pressão; denylist grep no critério de completion), escopo Swagger (P9 — widget não tem i18n upstream; escopar e documentar).

## Implications for Roadmap

Estrutura sugerida: **5 fases**. As ordens de build de ARCHITECTURE (8 passos) e o mapeamento pitfall→fase de PITFALLS (4 blocos) convergem; a estrutura abaixo reconcilia as duas com um checkpoint duro explícito.

### Phase 1: Contrato & Golden Fixtures
**Rationale:** 5 dos 9 pitfalls se previnem **por decisão, não por código**; fixtures congelados são a definição de "comportamento atual" e pré-requisito de todo gate seguinte; o contrato fixa token canônico e default antes de qualquer código depender deles.
**Delivers:** `OUTPUT_LANG` no CONTEXT.md (valores `en|pt-br`, default, token canônico minúsculo, tabela de mapping por consumidor) + passo de onboarding; inventário de chrome (4 camadas × 5 superfícies, arquivo:linha); seeds do glossário + denylist de calques + decisões de vocabulário (ver Gaps); definição de escopo Swagger (título + `lang`, limite upstream documentado); golden fixtures `en` **por geminho** (`.sh` e `.ps1` separados), tree de teste com `features/autenticação/`, máscara de data documentada; decisão data=ISO 8601 nos dois idiomas.
**Addresses:** T1, T2, T5 (política), T9, D1 (desenho), define a barra de T7.
**Avoids:** P1 (fixtures antes), P3 (inventário), P5 (tag), P8 (decisões de vocabulário), P9 (escopo).

### Phase 2: Label Map & Consumo .sh — MkDocs/index + CHECKPOINT en
**Rationale:** valida a fonte única nas duas superfícies de maior risco (onde vivem o sed title-case, a divergência de gêmeos e o `theme.language`) **antes** de replicar; isola "extração mudou bytes?" de "tradução é boa?" — dois modos de falha que não se debugam juntos.
**Delivers:** catálogo en (extração mecânica, nunca redigitada) + esquema de chaves namespaced; helper de lookup `.sh` (~5 linhas, hard-fail em chave ausente); `generate-index.sh`, `generate-mkdocs.sh` e templates consumindo por chave; derived-label = passthrough (chrome fora do sed de title-case); emissão aditiva de `theme.language`. **Checkpoint duro: `OUTPUT_LANG=en` chain diff vs fixture Phase 1 vazio → commit aqui.**
**Addresses:** T3, T4 (parcial), T6 (mkdocs), T7 (verificada).
**Avoids:** P2 (fonte única antes da 2ª superfície), P6 (sed), P1 (barra efetivamente exercitada).

### Phase 3: pt-br + Superfícies Restantes (.sh)
**Rationale:** replica o padrão provado nas superfícies restantes, cada uma com sua gotcha específica (PDF/lang, Wiki/filenames, DokuWiki/footer mínimo, Swagger/limite upstream); autoria da tradução só depois da extração estar provada byte-estável.
**Delivers:** catálogo pt-br completo (prosa passando pelas referências de estilo — sem calques, sentence case); consumo em `to-pdf.sh`, `to-dokuwiki.sh`, `templates/swagger-ui.html` (+ `html lang`); `-M lang=pt-BR -M toc-title=Sumário` **somente** no branch pt-br; gates: grep allowlist por superfície na saída pt-br + assert estrutural do comando pandoc (contém `lang=pt-BR` só em pt-br) — ambos rodam sem engines.
**Addresses:** T4 (completa as 5 superfícies), T5, T6 (pdf/swagger), D4 (parcial — hifenização via lang), T8 (filenames preservados).
**Avoids:** P7 (lang no branch errado), P9 (impl), P3 (gates por superfície).

### Phase 4: Gêmeos PowerShell (.ps1)
**Rationale:** os gêmeos compartilham o mesmo mapa — divergências de **string** convergem por construção (mudança de comportamento aceita e anotada, não mistura silenciosa); divergências **estruturais** pré-existentes ficam fora do escopo (não virar "corrigir 4 divergências sem gate"); a disciplina de encoding PS 5.1 vs 7 é documentada em fonte HIGH e verificável por fixture acentuado por geminho.
**Delivers:** helper de lookup PS (parse do mesmo catálogo, `Get-Content -Encoding UTF8`); pinning de encoding na leitura; decisão BOM na escrita (en preserva o wart atual); `.ps1` tocados salvos UTF-8 com BOM quando carregarem acentos; goldens `.ps1` por geminho.
**Addresses:** T4/T7 no host Windows, paridade de gêmeos.
**Avoids:** P4 (mojibake/BOM), P2 (lint de paridade estrutural).

### Phase 5: Prosa dos Agents, Glossário & Release
**Rationale:** prosa de agent é governada por regra, não por lookup — e convenção que mora só em referência consultável é ignorada sob pressão; a nota de migração do default flip é obrigatória (usuário en existente atualiza e a documentação muda de idioma sem aviso).
**Delivers:** linha de OUTPUT_LANG + glossário **inline** nos dispatch prompts e nos `agents/format-*.md`; nouns canônicos de seção sourced do mesmo mapa; denylist de calques como gate grep no critério de completion dos agents; `tests/regress.sh` wired; README/README.pt-BR + rubric delta; nota de release ("`OUTPUT_LANG=en` preserva o comportamento anterior"); execução pt-br end-to-end num host com engines.
**Addresses:** T9 (enforcement), D1 (gates), T7 (harness completo), anti-features A1/A2/A3 respeitadas por construção.
**Avoids:** P8 (calques publicados), UX do default flip.

### Phase Ordering Rationale

- **Rede de segurança antes de mover strings** (fixture precede refactor), **decisões antes de código** (contrato precede consumo), **padrão provado antes de replicar** (MkDocs/index antes das demais superfícies), **verificação de engine isolada e tardia** (host dev sem engines — ADR 0003 — gates estruturais cobrem o interim).
- O agrupamento segue a arquitetura: uma fase por fronteira (contrato → determinístico .sh → determinístico .ps1 → agents), nunca por idioma — o idioma é um arquivo de dados, não uma fase.
- Todas as fases respeitam as anti-features: sem conditionais inline (A7), sem fallback silencioso (A4), sem tocar paths (A5), sem auto-detecção (A2), sem nova dependência (constraint MET-1).
- Recomendação transversal de arquitetura de dados: o catálogo en é **âncora de regressão** e o pt-br **override** com paridade de key-set checada por gate — qualquer label novo entra nos dois arquivos no mesmo commit.

### Research Flags

Fases que provavelmente precisam de `/gsd:plan-phase --research-phase <N>` (ou spike):
- **Phase 3 (PDF):** `toc-title` é writer-dependent — STACK avalia HIGH (manual lista LaTeX/EPUB/HTML/etc.) mas ARCHITECTURE avalia MEDIUM para o path weasyprint e pede verificação ao vivo; hifenização WeasyPrint (CSS `hyphens: auto` + dicionário Pyphen `pt_BR`) também merece confirmação prática num host com engines. Divergência de confiança entre pesquisadores = candidato natural a research-phase.
- **Phase 4 (PowerShell):** conhecimento é HIGH (`about_Character_Encoding`, oficial) — o gap não é pesquisa, é **host Windows** para execução real; se um host PS 5.1 não estiver disponível, tratar verificação ao vivo como spike separado.

Fases com padrões consolidados (pular research-phase):
- **Phase 1:** decisões internas do projeto + padrão de contrato já provado no milestone de qualidade.
- **Phase 2:** mecanismo de catálogo é o padrão universal da indústria (gettext/Rails/Hugo/Docusaurus em miniatura) e os fatos do repo foram verificados por leitura direta.
- **Phase 5:** convenções de prose/gates já decididas no PROJECT.md; enforcement é grep determinístico.

## Confidence Assessment

| Área | Confiança | Notas |
|------|-----------|-------|
| Stack | HIGH no mecanismo central; MEDIUM em detalhes | Label maps, `theme.language`, `lang` do pandoc: verificados em docs oficiais cruzadas. MEDIUM: grão fino de PS 5.1, comportamento `sed` em locale (corroborado por mantenedor + reproduzido no host), padrão bash de label maps sem spec formal — a validação real é o fixture + rubric |
| Features | HIGH | Padrão governante confirmado em 4+ fontes primárias independentes (Material, static-i18n, Docusaurus, Sphinx, Hugo). Rebaixados: Hugo (LOW-MEDIUM, search-mediated), DokuWiki config (LOW — fetch bloqueado HTTP 402) |
| Architecture | HIGH em fatos do repo; MEDIUM em padrões externos | Divergências .sh/.ps1 e inventário de chrome verificados por leitura direta de arquivo (com linha). Padrões gettext/Rails/BCP 47: MEDIUM multi-fonte |
| Pitfalls | HIGH em codebase + reprodução local; MEDIUM em claims externos | Corrupção do sed reproduzida NESTE host (2026-09-28); divergência dos gêmeos citada com arquivo:linha. Swagger UI sem i18n: claim negativa verificada contra docs/config master (issue refs divergem entre pesquisadores — #472 vs #4776 — a negativa é que importa) |

**Overall confidence:** HIGH — no que decide o roadmap (padrão governante, fatos do repo verificáveis, mecanismo de catálogo, barra de regressão) a pesquisa é convergente e bem-fontada; MEDIUM pontual em detalhes de engine a verificar ao vivo.

### Gaps to Address

Conflitos entre pesquisadores — **decidir na Phase 1** (mecanismo acordado, detalhe divergente):
- **Política de chave ausente:** STACK propõe overlay com fallback en (modelo gettext); FEATURES (T5), ARCHITECTURE (Pattern 3) e PITFALLS (Anti-pattern 2) pedem **erro duro fail-closed**. Recomendação: fail-closed (3 vs 1) — com catálogo pequeno e fechado, completude é barata e fallback silencioso é o mecanismo exato da saída mista. O overlay de carga do STACK pode coexistir como belt-and-suspenders, mas o gate de paridade de key-set deve hard-fail.
- **Localização/extensão do catálogo:** STACK propõe `templates/lang/*.lang`; ARCHITECTURE propõe `labels/*.lbl` (com racional de self-location via `$PSScriptRoot\..` e sem `readlink -f`). Escolher um na Phase 1; o formato `KEY=value` UTF-8 sem BOM é consenso.
- **Seeds de vocabulário:** STACK traduz "Spec"→"Especificação" e usa Title Case ("Início Rápido"); PITFALLS recomenda manter Spec/Design/Tasks untranslated (nomes de artefatos do método) e sentence case (convenção PT-BR). Decisão de glossário Phase 1 — recomendação: sentence case para headings; Spec/Design/Tasks a decidar com o glossário.
- **Escopo da convergência .sh/.ps1:** PITFALLS advoga goldens por geminho (preservar divergências atuais); ARCHITECTURE advoga normalização deliberada para as strings canônicas do `.sh`. Síntese: divergências de string convergem por construção da fonte única (aceita, anotada, nota de release); divergências estruturais ficam out of scope.

Gaps de verificação — tratar na fase indicada:
- **pandoc `toc-title` no path weasyprint:** verificar ao vivo na Phase 3 (host com engines); se não suportado, registrar "TOC heading do engine fica em inglês" como limitação aceita (nota ADR-worthy).
- **Execução end-to-end pt-br:** o host dev não tem engines (ADR 0003) — gates estruturais cobrem o interim; a execução real na Phase 5 exige host com mkdocs/pandoc/weasyprint.
- **Verificação PS 5.1 real:** fixture acentuado por geminho é o gate local; execução em Windows host confirmar quando disponível (gap conhecido anotado, não bloqueador).
- **DokuWiki config:** LOW (dokuwiki.org bloqueado) — direção segura (interface language é setting do servidor, não nossa); re-verificar só se a Phase 3 depender de detalhes (superfície é pequena: 1 linha de footer + prosa).
- **URL do Microsoft Localization Style Guide pt-BR:** hub Globalization verificado, URL exata de download não — resolver no primeiro uso do glossário.
- **Refs do Swagger UI:** issue numbers divergem entre pesquisadores (#472 vs #4776); a claim negativa (sem i18n oficial) foi verificada duas vezes contra docs/config — citar a negativa, conferir o número ao escrever a ADR.

## Sources

### Primary (HIGH confidence)
- MkDocs Material — Changing the language (squidfunk.github.io/mkdocs-material/setup/changing-the-language/) — `theme.language`, pt-BR built-in, default en
- pandoc User's Guide (pandoc.org/MANUAL.html) — `lang` → babel/polyglossia, `toc-title`, `-M/--metadata` (cruzado com issue jgm/pandoc#3318)
- Swagger UI configuration.md @ master (raw.githubusercontent.com) — claim negativa de i18n, verificada duas vezes por fetch direto
- PowerShell about_Character_Encoding (learn.microsoft.com, 5.1–7.6) — encodings por cmdlet/versão, BOM, scripts não-ASCII
- Código do repo (leitura direta 2026-09-28) — SKILL.md, CONTEXT.md, 8 agents, scripts .sh/.ps1, templates, ADR 0001; divergências dos gêmeos citadas com arquivo:linha
- Docusaurus i18n Introduction + Tutorial (docusaurus.io) — layout de catálogo por locale, default locale, write-translations
- mkdocs-static-i18n (3 páginas oficiais + repo) — nav_translations, fallback, single-locale build, status frozen

### Secondary (MEDIUM confidence)
- Rails i18n Guide (guides.rubyonrails.org) — frase inteira como unidade, interpolação, raise-on-missing
- GNU gettext (PHP manual, glibc, Lokalise, Oracle) — msgid como chave, cadeia LANGUAGE→LC_ALL→…→LANG, miss→msgid
- WeasyPrint docs + Pyphen — `hyphens: auto` exige `lang` + dicionário; `pt_BR` incluído (underscore); quotes CSS não implementadas
- RFC 5646 / IANA Language Subtag Registry + OpenID/Java Locale docs — case-insensitivity, convenção `pt-BR`
- BCP 47 anti-patterns — W3C "I18N Best Practices for Spec Developers" (concatenação) + SimpleLocalize (detecção é inferência)
- PT-BR: Novo Manual da Redação da Folha; Manual do Estadão (E. Martins); Microsoft Learn "Microsoft language resources" (Localization Style Guides + Terminology); VOLP/ABL como desempate

### Tertiary (LOW confidence — re-verificar antes de depender)
- DokuWiki lang config / translation plugin (dokuwiki.org bloqueado HTTP 402) — só busca + background
- Hugo i18n/multilingual (search-mediated, página oficial não fetchada) — padrão consistente com as demais fontes, grão fino não confirmado
- Microsoft Localization Style Guide pt-BR — URL exata não verificada (hub sim)
- Swagger UI issue number exato (#472 vs #4776 divergem entre pesquisadores; a negativa é HIGH)

---
*Research completed: 2026-09-28*
*Ready for roadmap: yes*
