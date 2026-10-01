# Phase 1: Contrato & Golden Fixtures - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-28
**Phase:** 1-Contrato & Golden Fixtures
**Areas discussed:** Escopo dos goldens, Gêmeos .ps1 sem pwsh, Árvore de teste, Inventário de chrome

---

## Escopo dos goldens

### Quais saídas da cadeia atual entram nos golden fixtures?

| Option | Description | Selected |
|--------|-------------|----------|
| 5 superfícies | index.md, mkdocs.yml+docs/, mirror DokuWiki, livro-PDF (fallback markdown sem engine) e swagger-ui.html renderizado — tudo capturável sem engines; maximiza a rede de segurança antes do refactor | ✓ |
| Só MkDocs/index | Só a cadeia MkDocs/index (a validada em /tmp/mdw-sr3); DokuWiki/PDF/Swagger entram por assert estrutural — menos custo de captura, rede menor | |
| 5 + intermediários | 5 superfícies + intermediários (specs-book.md, merged-specs/) congelados também — rastreio total, mas golden maior e mais frágil a mudanças cosméticas | |

**User's choice:** 5 superfícies
**Notes:** Intermediários ficam de fora — só saídas publicáveis congelam.

### Como congelar a superfície Swagger UI no golden?

| Option | Description | Selected |
|--------|-------------|----------|
| Template + render | Harness aplica a substituição dos {{…}} com valores da fixture via sed e diffa contra a instância golden — congela também o contrato de renderização atual (título, url, estrutura) que a Phase 3 vai traduzir | ✓ |
| Só o template | Congelar só os bytes do template como está — mais simples, mas a Phase 3 mexe exatamente na instância renderizada (título/lang) e fica sem golden de referência | |

**User's choice:** Template + render
**Notes:** Swagger é a única superfície sem script determinístico no meio (agente substitui `{{…}}`) — o harness passa a fazer a substituição mecanicamente.

---

## Gêmeos .ps1 sem pwsh

### Como capturar os golden fixtures dos gêmeos .ps1 sem pwsh neste host?

| Option | Description | Selected |
|--------|-------------|----------|
| Instalar pwsh | Capturar os dois gêmeos agora: pwsh no Linux = baseline PS7 documentado (PS 5.1 segue como gap registrado no STATE.md); satisfaz o criterion 3 sem depender de host Windows | ✓ |
| Adiar p/ Windows | Só .sh congelado agora; harness detecta pwsh ausente e pula .ps1 com aviso documentado — desvia do criterion 3 da Phase 1 (fica registrado como desvio) | |
| Adiar p/ Phase 4 | Só .sh na Phase 1; .ps1 capturado na Phase 4 junto com o refactor — quebra a semântica "congelar antes de mover strings" para o lado .ps1 (refactor sem rede) | |

**User's choice:** Instalar pwsh
**Notes:** pwsh é dependência somente de dev (MET-1 conta custo por execução, não setup único). Baseline PS7; diferenças BOM/CRLF vs PS 5.1 são gap conhecido já registrado.

### Como o harness de regressão se comporta quando pwsh está ausente no host?

| Option | Description | Selected |
|--------|-------------|----------|
| Skip + exit 3 | Perna .ps1 marcada SKIPPED com motivo, mas o processo termina com exit code próprio (ex.: 3) — parcial é máquina-detectável, não silencioso; pwsh não vira obrigação global | ✓ |
| Fail-closed puro | Sem pwsh o harness falha — gate sempre completo ou vermelho; máximo fail-closed, mas torna pwsh obrigatório em qualquer host que rode a regressão | |
| Skip silencioso | Perna .ps1 pulada com aviso, exit 0 sempre que a parte .sh passar — mais conveniente, mas uma regressão .ps1 pode passar despercebida num host sem pwsh | |

**User's choice:** Skip + exit 3
**Notes:** Coerente com a filosofia fail-closed do milestone sem tornar pwsh obrigação global.

---

## Árvore de teste

### Qual a riqueza da tree de teste que alimenta os golden fixtures?

| Option | Description | Selected |
|--------|-------------|----------|
| sr3 + acento | Replicar a fixture /tmp/mdw-sr3 validada (5 seções, links internos) + features/autenticação/ acentuado — base já provada, acrescenta o requisito de acento da Phase 1 | ✓ |
| Mínima | Um feature + diretório acentuado — golden menor, mas exercita menos ramos do discover/index/nav | |
| Abrangente | sr3 + acento + edge cases (feature sem design.md, quick/ task, heading com pontuação) — mais cobertura, golden maior e mais sensível a ruído cosmético | |

**User's choice:** sr3 + acento
**Notes:** `features/autenticação/` é o mesmo nome que a Phase 3 usará no critério de corrupção de bytes — continuidade entre fases.

### A tree de teste vive commitada como arquivos ou é gerada pelo harness a cada execução?

| Option | Description | Selected |
|--------|-------------|----------|
| Commitada | A tree vive como arquivos .md reais em tests/fixtures/ — imutável, auditável, o diff do golden é revisável arquivo a arquivo; a fonte da verdade é conteúdo, não código | ✓ |
| Gerada na hora | Harness cria a tree a cada execução (script mkdir/printf) — menos arquivos no repo, mas a fonte da verdade vira código gerador (mudança no gerador muda a entrada silenciosamente) | |

**User's choice:** Commitada
**Notes:** —

---

## Inventário de chrome

### Qual o formato do inventário de chrome?

| Option | Description | Selected |
|--------|-------------|----------|
| Chave → sítio | Cada linha já usa a chave futura do catálogo (ex.: site_name_suffix → generate-mkdocs.sh:43) — a Phase 2 extrai verbatim conferindo contra o inventário, e o rubric audita par en/pt-br completo contra o mesmo mapa | ✓ |
| Descritivo só | Tabela camada×superfície com arquivo:linha, sem chaves — mais leve agora, mas a Phase 2 re-inventa o mapeamento chave→sítio na hora da extração | |

**User's choice:** Chave → sítio
**Notes:** As chaves são as da seed do glossário definida no stack do projeto — o inventário não inventa chaves novas.

### Onde o inventário de chrome vive?

| Option | Description | Selected |
|--------|-------------|----------|
| docs/ + contrato | Inventário em docs/chrome-inventory.md; o contrato (CONTEXT.md da skill) recebe só as decisões de escopo (fail-closed, catálogo, Swagger, datas ISO) e aponta para o mapa — contrato fica enxuto para leitura em runtime | ✓ |
| Tudo no contrato | Inventário como seção do CONTEXT.md da skill junto das decisões — casa única, mas incha o arquivo lido por agents a cada execução com dados de build de um milestone | |
| tests/ | Inventário junto do harness em tests/ — perto dos fixtures e do gate, mas longe das decisões de escopo que o critério 5 quer co-localizadas | |

**User's choice:** docs/ + contrato
**Notes:** —

---

## Claude's Discretion

- Mecânica da máscara de data (token simétrico aplicado no golden e na saída fresca antes do diff; 3 sítios: `generate-index.sh:105`, `generate-index.ps1:84`, `to-pdf.ps1:21`)
- Layout interno de `tests/` (harness em `tests/regress.sh` + `tests/fixtures/` com tree e goldens separados por geminho)
- Invocação canônica dos scripts na captura (args, cwd, ordem)
- Redação da seção de decisões de escopo no contrato da skill e da pergunta `OUTPUT_LANG` no onboarding (padrão AUDIENCE)

## Deferred Ideas

None — discussion stayed within phase scope.
