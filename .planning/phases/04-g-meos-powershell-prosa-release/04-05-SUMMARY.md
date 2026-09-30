---
phase: 04-g-meos-powershell-prosa-release
plan: "05"
subsystem: docs
tags: [readme, changelog, release-notes, skill, documentation]
requires:
  - phase: 04-g-meos-powershell-prosa-release
    provides: "todos os 4 planos anteriores completos"
provides:
  - "README.md e README.pt-BR.md sem ressalva de .ps1 pendente"
  - "SKILL.md verificado (paridade posicional confirmada)"
  - "CHANGELOG.md com nota de release e flip de default"
affects: []
actuals:
  tokens: 6618
  tasks: 3
  commits: 2
  plan_head_before: 5a7052bc65e47f3045ea173ced4316f2ebd933d5
  plan_head_after: 333f9adf5a348e5c4921d18181f4e30e7e429119
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - CHANGELOG.md
  modified:
    - README.md
    - README.pt-BR.md
    - SKILL.md
    - CONTEXT.md
key-decisions:
  - "Task 3 não produziu diff de código: a bateria de gates, a auditoria delta e a verificação dos 5 critérios são trabalho de leitura/execução, não de escrita — o CHANGELOG.md já estava correto (golden-ps1 confirmado, engines ausentes registrados) desde a Task 2, então não há terceiro commit de código; o fechamento da fase vai no commit de metadados final (SUMMARY + STATE + ROADMAP)"
  - "A bateria completa só roda com pwsh de fato no PATH — o ambiente de execução desta sessão não herda /snap/bin por padrão (só o shell de login do usuário o inclui); adicionar /snap/bin ao PATH antes de rodar tests/regress.sh e tests/ps1-contract.sh foi necessário para reproduzir o resultado verde que o plano 04-04 já tinha alcançado, e não uma regressão nova"
requirements-completed: [QUAL-03, PARAM-01]
coverage:
  - id: D1
    description: "README.md e README.pt-BR.md sem ressalva sobre .ps1 e com seção de gates"
    verification:
      - kind: unit
        ref: "grep -ciE 'later phase|fase futura|ainda não aceit' README.md README.pt-BR.md == 0; grep -qE '^## (Tests|Testes)' nos dois"
        status: pass
    human_judgment: false
  - id: D2
    description: "SKILL.md verificado — paridade posicional .ps1/.sh verdadeira"
    verification:
      - kind: manual
        ref: "leitura linha a linha do cabeçalho Usage: dos 6 pares de scripts em scripts/ — as 6 assinaturas posicionais batem entre .sh e .ps1"
        status: pass
    human_judgment: true
    rationale: "Verificação de paridade de assinatura exige comparar prosa/código dos dois arquivos par a par; não é um grep de uma linha"
  - id: D3
    description: "CHANGELOG.md com nota de release explicando flip de default pt-br"
    verification:
      - kind: unit
        ref: "grep -ciE 'nota de release' CHANGELOG.md == 1; grep 'pt-br' CHANGELOG.md"
        status: pass
    human_judgment: false
duration: 62min
completed: 2026-09-30
status: complete
---

# Phase 04 Plan 05: Fechamento do milestone — release, READMEs e auditoria consolidada Summary

**Ressalva de paridade `.ps1` removida dos dois READMEs (substituída por documentação afirmativa de `OUTPUT_LANG` e uma seção `## Tests`/`## Testes` com os seis harnesses), `SKILL.md` verificado script por script contra o código (a afirmação de paridade posicional que era falsa agora é verdadeira), `CHANGELOG.md` criado com a nota de release do flip de default para `pt-br`, `CONTEXT.md` sem mais prosa de "fase futura", e a bateria completa dos seis harnesses rodando 100% verde com `pwsh` no `PATH` — os cinco critérios de sucesso da Phase 4 percorridos, quatro atendidos e um parcial (execução pt-br com engines reais, gap de ambiente de dev já conhecido).**

## Performance

- **Duration:** 62min
- **Started:** 2026-09-30T18:56:00Z
- **Completed:** 2026-09-30T19:58:00Z
- **Tasks:** 3
- **Files modified:** 5 (1 criado, 4 modificados)

## Accomplishments

- `README.md`/`README.pt-BR.md`: a ressalva "os gêmeos `.ps1` ainda não aceitam `output_lang` — chega em fase futura" removida sem deixar rastro; substituída por afirmação de que os quatro gêmeos (`generate-index`, `generate-mkdocs`, `to-pdf`, `to-dokuwiki`) recebem o posicional no mesmo slot nos dois hosts
- Nova subseção "Output Language"/"Idioma de saída" em cada README: `en`/`pt-br`, default `pt-br`, normalização sem distinção de caso, atribuição via onboarding/dispatch prompt (nunca env var), fail-closed sem fallback silencioso, `en` byte-idêntico — apontando para `CONTEXT.md` como autoridade, sem restate da tabela de projeção (PRU-1)
- Árvore de estrutura corrigida nos dois READMEs: catálogo `pt-br.lang` listado ao lado de `en.lang`, `scripts/lib/catalog.ps1` e o diretório `tests/` (com os seis harnesses + `fixtures/`) acrescentados, a linha do `prompt-tests.sh` removido (confirmado ausente do disco) eliminada
- Seção `## Tests`/`## Testes` nova em cada README, depois da seção de dependências por formato: uma linha por harness com comando, o que prova, e o significado dos códigos de saída (`0` verde, `1` divergência/gate reprovado, `3` perna `SKIPPED` por dependência de dev ausente); registrada a proibição de editar golden fixture à mão
- Compatibilidade Windows/PowerShell: duas linhas novas (catálogo compartilhado via `scripts/lib/catalog.ps1`, saída UTF-8 sem BOM) e a limitação do PowerShell 5.1 não verificado, apontando para o `CHANGELOG.md`
- `SKILL.md`: a afirmação "todos os scripts são chamados posicionalmente, de forma idêntica em `.sh` e `.ps1`" foi VERIFICADA (não reescrita) lendo o cabeçalho `Usage:`/bloco de parâmetros dos 6 pares de scripts no disco — os 6 pares batem exatamente; tabela de Companion Scripts ganhou a coluna "Positional signature"
- `CHANGELOG.md` criado na raiz, convenção Keep a Changelog: nota de release com os quatro pontos exigidos (default `pt-br`, byte-identidade de `en` provada por `tests/regress.sh`, emissão aditiva, o que a skill nunca faz), seções Adicionado/Alterado/Corrigido, e tabela de Limitações conhecidas com 10 linhas (motivo + sítio de registro cada)
- `CONTEXT.md`: as duas afirmações de "fase futura" (aplicação em scripts, arquivos de catálogo) removidas da seção "Output language policy"; linha nova registrando o loader `.ps1` compartilhado e a gravação sem BOM; glossário anti-calque e sentinelas intocados (balanceados: 1 início, 1 fim)
- Apontador de uma linha para `CHANGELOG.md` acrescentado perto do topo dos dois READMEs
- Bateria completa dos seis harnesses rodada com `pwsh` disponível no `PATH` (`/snap/bin`, instalado no plano `04-04`): `fail-closed.sh` 23/23 OK, `no-calques.sh` 6/6 OK, `no-mixed-output.sh` 10/10 OK, `ps1-contract.sh` 21/21 OK (zero SKIPPED — as nove pernas `pwsh_*` rodaram de verdade), `regress.sh` 7/7 OK (zero SKIPPED — a perna `.ps1` completa, incluindo a superfície PDF sob a exceção D-10), `wiki-links.sh` 4/4 OK — `total_fails=0` em toda a suíte
- `tests/fixtures/golden-sh/` confirmado sem um byte de diferença entre o commit que abriu a fase (`d3c8478`) e o `HEAD` atual

## Task Commits

1. **Tarefa 1: os dois READMEs e a afirmação de paridade do SKILL.md** - `f8d727e` (docs)
2. **Tarefa 2: CHANGELOG.md com a nota de release, e o CONTEXT.md sem prosa de fase futura** - `333f9ad` (docs)
3. **Tarefa 3: bateria completa de gates, auditoria delta do rubric e fechamento da fase** - sem commit de código próprio; o `CHANGELOG.md` já refletia o resultado real desde a Tarefa 2 (golden-ps1 confirmado, engines ausentes registrados) — a verificação e a consolidação desta tarefa são registradas neste SUMMARY e fecham no commit de metadados final

## Files Created/Modified

- `CHANGELOG.md` (novo) - nota de release, Adicionado/Alterado/Corrigido, limitações conhecidas
- `README.md` (modificado) - ressalva removida, Output Language, árvore corrigida, seção Tests, apontador CHANGELOG
- `README.pt-BR.md` (modificado) - espelho estrutural do README.md
- `SKILL.md` (modificado) - coluna de assinatura posicional na tabela de Companion Scripts
- `CONTEXT.md` (modificado) - política de idioma no presente, loader `.ps1` e regra de encoding registrados

## Decisions Made

- **Bateria completa exige `pwsh` no `PATH` explícito desta sessão.** O ambiente de execução do agente não herda `/snap/bin` (só o perfil de login do usuário o inclui); rodar `export PATH="/snap/bin:$PATH"` antes de `tests/regress.sh`/`tests/ps1-contract.sh` foi necessário para reproduzir o estado verde que o plano `04-04` já tinha alcançado nesta mesma máquina — não é uma correção de regressão, é reconciliar o `PATH` da sessão do agente com o `PATH` do shell interativo onde `pwsh` foi instalado.
- **Task 3 sem commit de código.** O único arquivo no escopo da Tarefa 3 (`CHANGELOG.md`) já estava correto desde a Tarefa 2 — a captura `golden-ps1` já registrada (ramo A do plano `04-04`, `pwsh` instalado) e a linha de engines ausentes já presente. Criar um commit vazio ou um commit cosmético só para ter "um commit por tarefa" seria ele mesmo uma violação do MET-1 (estrutura sem ganho de previsibilidade); o resultado da Tarefa 3 fecha no commit de metadados final junto do `SUMMARY.md`.

## Bateria completa de gates — resultado desta execução

| Harness | Comando | Status de saída | `OK:` | `FAIL:` | `SKIPPED:` (motivo) |
|---------|---------|:---:|:---:|:---:|---|
| `tests/fail-closed.sh` | `bash tests/fail-closed.sh` | 0 | 23 | 0 | — |
| `tests/no-calques.sh` | `bash tests/no-calques.sh` | 0 | 6 | 0 | — |
| `tests/no-mixed-output.sh` | `bash tests/no-mixed-output.sh` | 0 | 10 | 0 | — |
| `tests/ps1-contract.sh` | `bash tests/ps1-contract.sh` | 0 | 21 | 0 | — |
| `tests/regress.sh` | `bash tests/regress.sh` | 0 | 7 | 0 | — |
| `tests/wiki-links.sh` | `bash tests/wiki-links.sh` | 0 | 4 | 0 | — |
| **Total** | — | — | **71** | **0** | **0** |

Nenhum `SKIPPED:` nesta execução — `pwsh` estava disponível no `PATH` (instalado no plano `04-04`, `/snap/bin/pwsh` 7.6.5), então as nove pernas comportamentais de `tests/ps1-contract.sh` e a perna `.ps1` de `tests/regress.sh` rodaram de verdade em vez de pular. Confirmado também: nenhum `SKIPPED:` por motivo diferente de `pwsh`/`pandoc` ausente em nenhuma execução anterior desta fase (varredura `grep -vE 'pwsh|pandoc'` sobre a saída de todos os harnesses, vazia).

`tests/fixtures/golden-sh/` — `git diff --quiet d3c8478..HEAD -- tests/fixtures/golden-sh/` retorna `rc=0` (zero diff), onde `d3c8478` é o primeiro commit que tocou `04-RESEARCH.md` (abertura da fase). Byte-identidade preservada durante toda a Phase 4.

## Auditoria delta consolidada — `docs/skill-quality-rubric.md`

Consolidação de todas as auditorias já registradas nos SUMMARYs dos planos `04-01`/`04-02`, mais a auto-auditoria desta tarefa para os arquivos tocados nas Tarefas 1 e 2. Mesmo formato de `03-02-SUMMARY.md`.

| File | Dim | Verdict | Evidence | Nota |
|------|-----|---------|----------|------|
| `docs/chrome-inventory.md` | HIE-4 (co-location) | ✅ Pass | linhas 62-67 (Camada 2), registrado em `04-01-SUMMARY.md` | Nota de convergência na mesma linha/coluna da divergência original |
| `docs/chrome-inventory.md` | PRU-1 (duplicação) | ✅ Pass | `04-01-SUMMARY.md` | Aponta para `templates/lang/*.lang` como materialização, não reescreve valor |
| `docs/chrome-inventory.md` | PRU-3 (sediment) | ✅ Pass | `04-01-SUMMARY.md` | Nota de URL divergente removida quando ficou falsa |
| `docs/chrome-inventory.md` | PRU-4 (fonte única) | ✅ Pass | `04-01-SUMMARY.md` | Critério de precedência reafirmado, não duplicado |
| `CONTEXT.md` | HIE-4 (co-location) | ✅ Pass | `## Glossário anti-calque` logo após `## Output language policy` (`04-02`); nesta tarefa, a linha do loader `.ps1`/BOM entrou na MESMA seção "Output language policy", não numa seção nova | Consequência direta agrupada |
| `CONTEXT.md` | PRU-3 (sediment) | ✅ Pass | linha "enforcement in scripts is live in both the `.sh` and the `.ps1` twins" substitui "later phase" sem frase nova acrescida | Ressalva obsoleta removida, seção não engordou |
| `CONTEXT.md` | HIE-5 (external reference) | ✅ Pass | `04-02-SUMMARY.md` | Continua a casa externa única do vocabulário |
| `CONTEXT.md` | PRU-1 (duplicação) | ✅ Pass | nova linha do loader não restate o algoritmo do parser — aponta `scripts/lib/catalog.ps1` como autoridade do código | Sem redefinição de parser em prosa |
| `agents/format-github-wiki.md` | PRU-1 (duplicação) | ⚠️ Partial (deliberada, aprovada) | `04-02-SUMMARY.md` | Cópia inline do glossário é intencional (Pitfall 4: referência só sob demanda é ignorada sob pressão de geração) |
| `agents/references.md` | HIE-2 (rung placement) | ✅ Pass | `04-02-SUMMARY.md` | Contrato `OUTPUT_LANG` + glossário só nos dois agents que escrevem prosa autoral |
| `SKILL.md` | STE-6 (determinism substitution) | ✅ Pass | coluna de assinatura posicional escrita após leitura linha a linha do cabeçalho `Usage:`/`param()` dos 6 pares no disco, não de memória | A afirmação de paridade agora é verificável por qualquer leitor comparando a tabela ao código |
| `SKILL.md` | PRU-3 (sediment) | ✅ Pass | a afirmação "identically in `.sh` and `.ps1`" (linha 53) era falsa até o plano `04-03`; hoje é verdadeira e a tabela prova | Conteúdo desatualizado corrigido, não apenas mantido |
| `SKILL.md` | HIE-6 (sprawl) | ✅ Pass | arquivo permanece ~90 linhas após a coluna nova | Roteador fino preservado |
| `README.md` / `README.pt-BR.md` | PRU-3 (sediment) | ✅ Pass | ressalva "later phase"/"fase futura" removida; linha `prompt-tests.sh` (script removido do disco) eliminada da árvore | Duas fontes de sedimento fechadas na mesma tarefa |
| `README.md` / `README.pt-BR.md` | HIE-2 (rung placement) | ✅ Pass | subseção "Output Language"/"Idioma de saída" e seção `## Tests`/`## Testes` inlined logo após o conteúdo que toda chamada de script precisa | Conteúdo universal (todo script leva `output_lang`; todo contribuidor roda os gates) inlined, não escondido atrás de pointer |
| `README.md` / `README.pt-BR.md` | PRU-1 (duplicação) | ✅ Pass | subseção de idioma resume em 4 linhas e aponta para `CONTEXT.md`; não restate a tabela de projeção por consumidor | Autoridade única preservada |
| `CHANGELOG.md` | HIE-5 (external reference) | ✅ Pass | arquivo novo, único lugar que consolida a história de release do milestone | Não espalha a nota de release em múltiplos READMEs — cada um aponta uma linha para cá |
| `CHANGELOG.md` | PRU-3 (sediment) | ✅ Pass | primeira entrada do arquivo, sem histórico anterior para acumular | N/A por ser arquivo novo |

**Rollup por axis:** HIE 2✅ (co-location) + 3✅ (rung placement) + 2✅ (external reference) = 7✅; PRU 8✅ 1⚠️(deliberada/aprovada); STE 1✅. Nenhum achado ❌ em nenhum arquivo tocado nesta fase.

### Duplicações deliberadas — aprovadas, não são achados de PRU-1

1. **Cópia inline do glossário anti-calque** em `agents/format-github-wiki.md` e `agents/references.md` (registrada no plano `04-02`) — referência atrás de link não tem força de acionamento sob pressão de geração (Pitfall 4); os dois são os ÚNICOS agents que escrevem prosa autoral publicada, então a duplicação não se espalha além do necessário.
2. **Repetição da frase de contrato `OUTPUT_LANG`** nos sete agents que a citam (`onboarding.md`, `format-swagger.md`, `format-mkdocs.md`, `format-dokuwiki.md`, `references.md`, `format-pdf.md`, `format-github-wiki.md`, confirmado por `grep -l OUTPUT_LANG agents/*.md`) — mesma redação em todos, de propósito, para que o dispatch prompt nunca dependa de o agent abrir outro arquivo para saber como passar a variável.

### Oportunidades levantadas e rejeitadas pelo gate MET-1

Aplicado por último, à lista de oportunidades (não aos arquivos). Nenhuma implementada nesta tarefa — ficam registradas para o usuário decidir no fechamento do milestone:

| Oportunidade | Por que foi considerada | Por que foi rejeitada (MET-1) |
|--------------|--------------------------|-------------------------------|
| Unificar a seção `## Tests`/`## Testes` dos dois READMEs num único include compartilhado | Reduz superfície de duplicação entre os dois idiomas | Os dois READMEs já são espelhos estruturais por decisão de projeto (README.pt-BR.md existe justamente para não depender de include); um mecanismo de include novo é estrutura sem ganho de previsibilidade — o agente que edita um README já sabe (por convenção do repo) que precisa espelhar no outro. Sedimento futuro, não redução de risco. |
| Adicionar link cruzado de `CONTEXT.md` para a seção `## Tests` dos READMEs | `CONTEXT.md` é o arquivo mais lido; um pointer a mais poderia ajudar navegação | `CONTEXT.md` documenta política de domínio, não onboarding de contribuidor; a seção de testes já é alcançada por quem lê o README (ponto de entrada natural). Acrescentar o pointer engorda a seção mais lida do arquivo mais lido sem mudar o processo que o agente segue. |
| Gerar a tabela de assinaturas posicionais do `SKILL.md` a partir de um script de extração automática dos cabeçalhos `Usage:` | Eliminaria o risco de a tabela divergir do código no futuro | Custo permanente (mais um script de manutenção, mais um ponto de falha) para um benefício que o gate `tests/ps1-contract.sh`/self-audit manual já cobre a um custo menor; a tabela muda raramente (só quando uma assinatura de script muda, evento raro e já revisado por PR). Reprova o gate de custo-permanente-por-execução vs. ganho. |

## Verificação dos cinco critérios de sucesso da Phase 4 (ROADMAP.md)

| # | Critério | Veredito | Evidência |
|---|----------|----------|-----------|
| 1 | Gêmeos `.ps1` resolvem todo chrome por chave contra o mesmo catálogo (leitura com encoding pinado, parse `KEY=value`) — divergências convergem por construção da fonte única | **Atendido** | `scripts/lib/catalog.ps1` existe e é dot-sourced pelos 4 gêmeos (`04-01`/`04-03`); `tests/ps1-contract.sh` 21/21 `OK:` nesta execução, incluindo `no_hardcoded_chrome` e `catalog_keys_exist` para os 4 gêmeos; `docs/chrome-inventory.md` Camada 2 registra as divergências antigas (`generated_by`, `nav_issues`, `pdf_generated_on`) como convergidas |
| 2 | `OUTPUT_LANG=en` reproduz os golden fixtures byte-idêntico por geminho também no lado `.ps1`; fixture com diretório acentuado sem mojibake nem BOM inesperado no caminho `en` | **Atendido** | `tests/regress.sh` rodou 7/7 `OK:`, zero `SKIPPED:`, com a perna `.ps1` real contra `tests/fixtures/golden-ps1/` (captura feita no plano `04-04`, ramo A); `tests/fixtures/manifest.md` confirma zero BOM em todos os 11 arquivos capturados e o nome `autenticação` intacto |
| 3 | Glossário anti-calque no `CONTEXT.md` rege a prosa dos agents; dispatch prompts e `agents/format-*.md` carregam a linha de `OUTPUT_LANG` + glossário inline; nouns canônicos vêm do mesmo mapa de labels | **Atendido** | `CONTEXT.md` seção "Glossário anti-calque" (`04-02`); `agents/format-github-wiki.md` e `agents/references.md` com cópia inline; `grep -l OUTPUT_LANG agents/*.md` confirma os 7 agents; `tests/no-calques.sh` gate `glossary_is_inlined` `OK:` |
| 4 | Denylist de calques verificável por grep roda como critério de completion — zero ocorrência de calques na prosa dos agents e na saída pt-br | **Atendido** | `tests/no-calques.sh` 6/6 `OK:`, rc=0, incluindo os dois controles anti-vacuidade (`gate_is_load_bearing`, `allowlist_is_load_bearing`) — o gate não passa por vacuidade nem é largo demais |
| 5 | Release: `tests/regress.sh` wired no fluxo, README/README.pt-BR e rubric delta atualizados, nota de release documentando o default flip e que `OUTPUT_LANG=en` preserva o comportamento anterior; execução pt-br end-to-end num host com engines | **Parcialmente atendido** | `tests/regress.sh` documentado na seção `## Tests`/`## Testes` dos dois READMEs (wired = documentado onde um contribuidor olha, já que não há CI); `CHANGELOG.md` tem a nota de release completa; auditoria delta consolidada acima. **O que falta:** este host de desenvolvimento não tem `mkdocs-material` nem engine de PDF real (`weasyprint`/`wkhtmltopdf`/`xelatex` ausentes, confirmado por `command -v`) — a execução pt-br de ponta a ponta com o tema Material renderizado e um PDF real gerado não foi exercitada; o plano `04-04` já rodou a cadeia `.ps1` pt-br manualmente fora do harness (mkdocs.yml, index.md, fallback markdown do PDF, README DokuWiki) mas sem o tema Material nem um PDF binário real. Registrado como limitação conhecida em `CHANGELOG.md` (última linha da tabela) e no `<human-check>` do plano, para quando um host com os engines estiver disponível. |

Nenhum critério saiu **não atendido** — o critério 5 parcial é o próprio gap de ambiente de dev já antecipado e documentado desde a Phase 1 (`STATE.md`, Blockers), não uma surpresa desta tarefa.

## Deviations from Plan

None - o plano foi executado como escrito nas três tarefas. A única adaptação foi operacional (adicionar `/snap/bin` ao `PATH` desta sessão para reproduzir o estado com `pwsh` que o plano `04-04` já tinha alcançado), não uma mudança de escopo ou critério de aceite.

## Known Stubs

Nenhum.

## Threat Flags

Nenhuma superfície nova introduzida. As mitigações do `<threat_model>` deste plano (T-04-11: cada afirmação de paridade tocada tem critério de aceite que a checa contra o código; T-04-SC: nenhum pacote instalado) foram seguidas — nenhuma instalação de pacote ocorreu, e cada afirmação revisada (SKILL.md, READMEs) foi verificada contra o código antes de ser escrita ou mantida.

## User Setup Required

None — nenhuma configuração de serviço externo necessária. A verificação de PowerShell 5.1 num host Windows real e a instalação de `mkdocs-material`/engine de PDF neste host de dev continuam como limitações conhecidas, não bloqueadores.

## Next Phase Readiness

- Milestone `OUTPUT_LANG` fecha com os 9 requisitos v1 (`PARAM-01`, `PARAM-02`, `CHROME-01..04`, `QUAL-01..03`) completos por Phase, confirmados em `.planning/REQUIREMENTS.md`
- As três oportunidades do rubric levantadas e rejeitadas por MET-1 acima ficam registradas para o usuário decidir se alguma merece reconsideração num milestone futuro — nenhuma é bloqueio
- O critério 5 parcial (execução pt-br com engines reais) é o único item pendente de fechamento total da Phase 4, e depende de um host com `mkdocs-material` e um engine de PDF instalados — fora do alcance deste ambiente de desenvolvimento

## Self-Check: PASSED

Todos os arquivos declarados (`CHANGELOG.md`, `README.md`, `README.pt-BR.md`, `SKILL.md`, `CONTEXT.md`) e os 2 hashes de commit de tarefa (`f8d727e`, `333f9ad`) confirmados presentes no disco e no log.

---
*Phase: 04-g-meos-powershell-prosa-release*
*Completed: 2026-09-30*
