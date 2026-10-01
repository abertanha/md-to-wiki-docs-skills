# Walking Skeleton — md-to-wiki (milestone OUTPUT_LANG)

**Phase:** 1
**Generated:** 2026-09-28

> Adaptado à realidade do projeto: esta skill é bash + markdown — não há banco de dados, framework de UI nem deployment no sentido web-app. O "stack completo" é a cadeia da skill: árvore de fixture commitada → scripts `.sh`/`.ps1` atuais → 5 superfícies publicáveis → harness de diff. As linhas do template que não se aplicam estão marcadas N/A com o seu equivalente neste repo.

## Capability Proven End-to-End

A árvore de specs commitada (`tests/fixtures/tree/`, com diretório acentuado `features/autenticação/`) atravessa a cadeia `.sh` atual NÃO modificada e o harness `tests/regress.sh` valida a saída contra golden fixtures byte-idênticos (máscara de data simétrica `__DATE__`) rodando sem engines — com exit code verde/vermelho/SKIPPED detectável por máquina (0/1/3). Com as dev-deps pwsh/pandoc instaladas, o mesmo harness fecha exit 0 cobrindo os dois geminhos.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Parametrização de idioma | `OUTPUT_LANG` (`en` \| `pt-br`, default `pt-br`, token canônico minúsculo) vive na camada de contrato: tabela §Variables do `CONTEXT.md`, atribuição exclusiva no `agents/onboarding.md`, transmissão exclusiva por dispatch prompt — NUNCA env var | Mesmo mecanismo já validado da variável `AUDIENCE`; casa única: agents referenciam o contrato, não reenunciam (PARAM-01) |
| Normalização e projeção de locale | Normalização case-insensitive na entrada (`pt-BR` ≡ `pt-br`); projeção por consumidor em UMA tabela no ponto de uso: `pt-BR` para MkDocs Material/pandoc/HTML, `pt_BR` para Pyphen; valor desconhecido = fail-closed listando os suportados | BCP 5646/RFC case-insensitive + fail-closed existente do projeto (to-dokuwiki.sh:11-12) — previsibilidade sobre conveniência (PARAM-02) |
| Rede de segurança antes de mover strings | Golden fixtures congelados POR GEMINHO (`.sh` e `.ps1` separados, nunca combinados) a partir da cadeia atual não modificada; diff é o guardião, golden nunca é editado à mão | Os gêmeos divergem por construção hoje; golden único esconderia as divergências que a Phase 4 precisa convergir. O diff byte-exato substitui qualquer validação semântica (ADR-0003) |
| Determinismo da captura/diff | `LC_ALL=C.UTF-8` pinado em tudo que roda a cadeia (sed de title-case corrompe acentos em locale C); cwd de captura `mktemp -d` FORA de qualquer repo git (origin não vaza para o golden); workdir fresco por perna | Reproduzido por execução no host (research Pitfalls 1-4); sem esses pins o golden não é reprodutível |
| Máscara de data | Token simétrico `__DATE__` (regex ISO 8601) aplicado ao golden E à saída fresca antes do diff; 3 sítios datados documentados no manifest; fixture sem datas ISO (a máscara só toca chrome) | 1 linha de sed cobre os 3 sítios conhecidos; faketime seria dependência + LD_PRELOAD (reprovado no MET-1) |
| Convenção de exit codes do harness | 0 = tudo verde; 1 = diff divergiu (nomeia arquivo); 3 = uma ou mais pernas SKIPPED com motivo impresso — parcial distinguível de falha | Exit 3 está livre na cadeia (scripts usam só 0/1); execução parcial nunca é silenciosa (D-04) |
| Dependências de captura | `pwsh` (PowerShell 7, Linux) e `pandoc` são dependências SOMENTE de dev — harness segue válido sem elas (perna SKIPPED/exit 3); baseline PS7/Linux sem BOM/LF documentado no manifest | MET-1 conta custo por execução, não setup único (D-03/D-09); PS 5.1 real permanece gap registrado no STATE.md |
| Catálogo de labels (decidido, implementação Phase 2) | `templates/lang/*.lang`, formato `KEY=value`, UTF-8 sem BOM, chaves da seed do glossário; fail-closed em chave ausente nomeando a chave | Ponto de encontro mínimo bash/PowerShell sem dependência nova de runtime; inventário `docs/chrome-inventory.md` é o mapa chave → sítio |
| Layout de testes | `tests/regress.sh` (harness) + `tests/fixtures/` com `tree/` (entrada commitada como .md reais), `golden-sh/` e `golden-ps1/` (por superfície), `manifest.md` (registro de captura) | Fonte da verdade é conteúdo, não código gerador (D-06); nome `regress.sh` é o que a Phase 4 wired no fluxo |

## Stack Touched in Phase 1

- [x] Entrada commitada — `tests/fixtures/tree/.specs/**` (réplica da fixture validada + diretório acentuado)
- [x] Cadeia real exercitada ponta a ponta — `generate-mkdocs`, `generate-index`, `to-pdf` (fallback), render Swagger por sed, `to-dokuwiki` (com pandoc), gêmeos `.ps1` sob pwsh
- [x] 5 superfícies publicáveis congeladas por geminho — MkDocs index+nav, DokuWiki, PDF (fallback `en`), Swagger UI, (GitHub Wiki é camada 4 de agent: só inventário, sem golden)
- [x] Verificação executável sem engines — `tests/regress.sh` com diff mascarado e exit codes 0/1/3
- [x] Contrato — `OUTPUT_LANG` em `CONTEXT.md` + `agents/onboarding.md`; decisões de escopo i18n registradas; `docs/chrome-inventory.md` commitado
- [ ] Database — N/A (equivalente: a fixture tree commitada é a fonte de dados imutável e auditável)
- [ ] UI — N/A (equivalente: as 5 superfícies publicáveis são a "UI" da skill; nenhuma framework)
- [ ] Deployment — N/A (equivalente: goldens commitados + harness que roda em qualquer host Unix com bash/coreutils; skill instalada por symlink local, sem pipeline externo)

## Out of Scope (Deferred to Later Slices)

- Extração/consumo do catálogo `templates/lang/*.lang` — Phase 2 (o inventário e a política já preparam o terreno)
- Qualquer chrome pt-br em saída — Phase 3 (default flip de fato nas superfícies)
- Gêmeos `.ps1` refatorados para consumir o catálogo + glossário anti-calque na prosa dos agents — Phase 4 (os warts congelados nos goldens são o insumo)
- Correção das divergências entre gêmeos (URL do rodapé, nav não-recursivo, links quebrados por `Split-Path`) — congeladas como estão; convergência por construção na Phase 4
- `templates/index.md` usar-ou-remover — decidir na Phase 2 (hoje: inventariado como unconsumed)
- PS 5.1 real (host Windows) — gap registrado no STATE.md, não bloqueador

## Subsequent Slice Plan

Cada fase seguinte adiciona uma fatia vertical sobre este skeleton SEM alterar suas decisões de arquitetura:

- Phase 2 — Catálogo de Labels & Cadeia MkDocs/index: strings `en` extraídas verbatim contra o inventário, superfícies MkDocs/index emitem chrome por lookup, checkpoint duro `en` byte-idêntico contra estes goldens antes de qualquer pt-br
- Phase 3 — pt-br nas 5 Superfícies: catálogo `pt-br` completo (paridade de key-set), locale projetado por consumidor (`theme.language: pt-BR`, `-M lang=pt-BR -M toc-title=Sumário`, `lang` no Swagger), diretório acentuado atravessando sem corrupção de bytes
- Phase 4 — Gêmeos PowerShell, Prosa & Release: catálogo na segunda shell com encoding disciplinado (UTF-8 sem BOM), prosa dos agents regida pelo glossário anti-calque com denylist verificável por grep, `tests/regress.sh` wired no fluxo de release e nota do default flip
