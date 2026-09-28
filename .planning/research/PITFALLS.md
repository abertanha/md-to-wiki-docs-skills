# Pitfalls Research

**Domain:** Retrofit de i18n/output-language (`OUTPUT_LANG`, default `pt-br`, `en` byte-idêntico) sobre um tool bash+markdown existente e em produção (md-to-wiki)
**Researched:** 2026-09-28
**Confidence:** HIGH para evidência de codebase e fatos reproduzidos localmente; MEDIUM para claims externos (official-doc backed, verificados via web)

Evidência direta: 10 arquivos carregam chrome em inglês hoje (`generate-index.{sh,ps1}`, `generate-mkdocs.{sh,ps1}`, `to-pdf.{sh,ps1}`, `to-dokuwiki.{sh,ps1}`, `templates/index.md`, `templates/swagger-ui.html`), além da prosa delegada a agents (`agents/format-github-wiki.md` manda escrever `Home.md`/`_Sidebar.md` "yourself — judgment work"). Cada pitfall abaixo cita arquivo/linha onde o risco já existe hoje.

---

## Critical Pitfalls

### Pitfall 1: O refactor de extração de labels quebra a barra byte-idêntica de `en`

**What goes wrong:**
A exigência "`OUTPUT_LANG=en` reproduz a saída atual byte-idêntica" é quebrada não pela tradução, mas pelo refactor em si: re-flow de heredoc, `printf` → `echo`, normalização de aspas, trailing newline a menos, BOM a mais. O diff do fixture deixa de ser vazio por razões invisíveis.

**Why it happens:**
Extrair string hardcoded para label-map é um refactor textual — e todo refactor textual toca whitespace. Além disso o footer já contém um token não-determinístico: `generate-index.sh:105` e `generate-index.ps1:84` embutem `$(date +%Y-%m-%d)` / `Get-Date -Format yyyy-MM-dd` — um fixture gerado em dia diferente nunca será byte-idêntico.

**How to avoid:**
1. Congelar os fixtures `en` ANTES de tocar em qualquer script: rodar cada par de scripts num tree de teste e commitar a saída como golden file — per script, per shell (`.sh` e `.ps1` têm saíadas DIFERENTES hoje; congelar uma por geminho, ver Pitfall 2).
2. Byte-compare (`cmp`, não `diff`) como gate: `cmp fixture-en-golden docs/index.md`.
3. Neutralizar a data com decisão explícita e documentada: ou gerar fixture e comparação no mesmo dia, ou mascarar exatamente o token de data (`sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}/DATE/'` em ambos os lados) e registrar no gate que só esse token é mascarado.
4. Regra de refactor: o path `en` só troca `"...texto..."` literal por `"${LABEL[...]}"` onde `LABEL[...]="...mesmo texto..."` — zero mudança de whitespace, quoting ou comando de emissão.

**Warning signs:**
Diff do fixture `en` mostra mudança só de linhas em branco/BOM/CRLF; diff mostra só a linha do footer; `file` reporta "with BOM" onde antes não havia.

**Phase to address:**
Phase 1 (Contrato & Fixtures) — fixtures congelados são pré-requisito de todo o resto; sem eles nenhuma fase seguinte tem gate.

---

### Pitfall 2: Drift do label-map entre consumidores — os gêmeos `.sh`/`.ps1` JÁ divergem hoje

**What goes wrong:**
O mesmo chrome é emitido por até 4 consumidores por superfície (`.sh`, `.ps1`, template, prosa de agent). Se cada um ganhar sua própria tabela de tradução, elas divergem. Não é hipótese: `generate-index.sh` tem 3 branches de audiência (developer/stakeholder/general, linhas 38–63) e emite células "—"/Spec/Design/Tasks; `generate-index.ps1` tem 1 branch só, emite link com `$name` em vez de "Spec/Design/Tasks", e footer apontando para `https://opencode.ai` enquanto o `.sh` aponta para o repo GitHub. A i18n multiplicará essa divergência por 2 idiomas.

**Why it happens:**
Cada geminho foi escrito/mantido de forma independente; não existe hoje nenhum mecanismo que compare as saídas dos dois. Adicionar `if [ "$OUTPUT_LANG" = pt-br ]` inline em cada arquivo replica a estrutura que produziu o drift.

**How to avoid:**
1. Fonte única de labels: UMA tabela (ex.: `templates/labels.sh` emitindo `LABEL_<CHAVE>=...` sourcing em bash, e equivalente parseável pelo `.ps1` — ex.: arquivo `.properties`/par `chave=valor` que os dois leem), consumida por todos.
2. Definir escopo honesto da barra de regressão: byte-idêntico é *por geminho contra si mesmo no estado atual* — `en` via `.sh` == fixture `.sh`-golden; `en` via `.ps1` == fixture `.ps1`-golden. Cross-shell parity nunca existiu; não prometer agora (senão o milestone vira "corrigir 4 divergências pré-existentes" sem gate MET-1).
3. Lint de paridade estrutural: um check que roda ambos os geminhos no mesmo tree `en` e falha se a *estrutura* (linhas, targets de link) divergir além do já documentado.

**Warning signs:**
`grep -r` por um label traduzido encontra o termo em `.sh` mas não no `.ps1` (ou em versão diferente); issue de usuário Windows vendo estrutura de índice diferente de usuário Linux.

**Phase to address:**
Phase 2 (Extração de labels — superfícies MkDocs/index primeiro): desenhar a fonte única ANTES de traduzir a segunda superfície.

---

### Pitfall 3: Tradução parcial — saída mista em português e inglês

**What goes wrong:**
Cada superfície tem CAMADAS de chrome e o i18n típico cobre só a primeira: (a) strings geradas pelos scripts, (b) chrome do theme/website em volta (MkDocs Material traduz search placeholder, footer, next/prev via `theme.language`), (c) prosa escrita por agents, (d) mensagens de console dos scripts (`Generated`, `WARNING:`, `Usage:`). Resultado comum: site com `site_name` em PT-BR mas UI de busca em inglês, ou PDF com título "Especificações" e rodapé "Generated on 2026-09-28".

**Why it happens:**
As camadas são de donos diferentes (script bash, config de theme, prompt de agent) e vivem em arquivos diferentes; o checklist mental "traduzi o que vejo" não enumera camadas.

**How to avoid:**
1. Inventário de strings ANTES de traduzir: enumerate por superfície as 4 camadas (script-chrome, theme-chrome, agent-prose, console) com arquivo:linha. O inventário parcial desta pesquisa (10 arquivos + agents/format-github-wiki.md:47–56) é o ponto de partida; completá-lo é tarefa da Phase 1.
2. Gate grep por superfície: em saída `pt-br`, `grep -nP '[A-Za-z]{4,}'` nas linhas de chrome (não no conteúdo dos specs — esse nunca é traduzido, é decisão do projeto) deve retornar só termos do glossário (allowlist técnico).
3. Decisão explícita sobre console: RECOMENDADO não traduzir mensagens de console no v1 (stdout dos scripts é consumido por agents, não pelo usuário final; traduzi-las cria +10 superfícies e fica fora da barra byte-idêntica trivialmente). Registrar como decisão, não como esquecimento.

**Warning signs:**
Screenshot/preview da saída pt-br mostra qualquer string de UI em inglês; revisão de PR encontra `site_description` ainda em inglês (`generate-mkdocs.sh:44`).

**Phase to address:**
Phase 1 (inventário) + gate por superfície nas Phases 2–3.

---

### Pitfall 4: PowerShell corrompe acentos — mojibake na leitura, BOM na escrita, `.ps1` sem BOM parseado como ANSI

**What goes wrong:**
Três modos distintos, todos aplicáveis aos `.ps1` existentes:
1. **Leitura:** `to-pdf.ps1:29` usa `Get-Content -Raw` sem `-Encoding`. No Windows PowerShell 5.1, arquivo UTF-8 sem BOM é lido como Windows-1252 → "Especificação" vira "EspecificaÃ§Ã£o" e vai direto pro PDF (com conteúdo pt-br nos specs, isso passa a ocorrer em TODA execução Windows).
2. **Escrita:** `Out-File -Encoding utf8` (`generate-index.ps1:87`, `to-pdf.ps1:33`) escreve COM BOM no PS 5.1. Nota: a saída `en` atual via `.ps1` JÁ tem BOM — a barra byte-idêntica manda PRESERVAR esse wart no path `en`, não "consertá-lo".
3. **Código-fonte:** um `.ps1` salvo UTF-8 sem BOM com literais acentuados (`"Especificações"`) é decodificado como ANSI pelo parser do PS 5.1 — os labels pt-br nascem corrompidos dentro do script.

**Why it happens:**
No PowerShell 7 tudo isso "funciona" (default `utf8NoBOM` em tudo) — desenvolvedor testa no PS7, usuário roda no Windows PowerShell 5.1 que ships com o Windows.

**How to avoid:**
1. Pinning explícito bidirecional: `Get-Content -Raw -Encoding UTF8` para ler sources sem BOM; para escrever, decidir por saída: manter `Out-File -Encoding utf8` (com BOM, igual ao en atual) ou usar `[IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))` — mas aí o path `en` muda e quebra a barra. Regra: en preserva o comportamento atual; pt-br pode usar o mesmo (BOM em .md gerado é inócuo para MkDocs/pandoc).
2. Salvar os próprios `.ps1` editados como UTF-8 **com BOM** (única forma do PS 5.1 não corromper literais acentuados).
3. Fixture com acento: o tree de teste precisa ter `features/autenticação/` (nome de diretório acentuado) — é o caso de teste que pega os três modos de uma vez.

**Warning signs:**
`Ã£`, `Ã©` em qualquer saída; `file scripts/*.ps1` mostra "UTF-8 Unicode (with BOM)" faltando nos arquivos com literais pt; diff en `.ps1` vs golden muda nos primeiros 3 bytes.

**Phase to address:**
Phase 2–3, no primeiro toque em cada `.ps1`; o fixture acentuado entra na Phase 1.

---

### Pitfall 5: Fragmentação do tag de locale — `pt-br` vs `pt-BR` vs `pt_BR` vs `pt`

**What goes wrong:**
O projeto escolheu `pt-br` como tag canônica interna. Cada consumidor final espera um formato diferente: MkDocs Material usa `theme.language` com códigos BCP-47 hífen (`pt` e `pt-BR` ambos completos); POSIX/locale de ambiente usa underscore (`pt_BR.UTF-8` — o próprio host dev está em `pt_BR.UTF-8`); pandoc `lang` espera BCP-47; HTML `lang` é case-insensitive; env var comparada em bash com `=` é case-sensitive. Se cada script improvisar a conversão, um usa `pt-br`, outro `pt_BR`, outro não reconhece `pt-BR` digitado pelo usuário e cai silenciosamente no default.

**Why it happens:**
Não existe "o formato de locale"; existe um por camada (IETF/BCP-47, POSIX, convenção do tool). O time escolheu a forma canônica sem ainda definir o mapping de saída por consumidor.

**How to avoid:**
1. Normalização na entrada: aceitar case/underscore/hífen (`pt-br`, `pt-BR`, `pt_BR`, `pt`) → forma canônica interna, definida UMA vez (função em bash + snippet PS).
2. Tabela de mapping por consumidor no `CONTEXT.md` (é exatamente o tipo de coisa que o CONTEXT.md existe para hospedar): interno `pt-br` → Material `language: pt-BR`, HTML `lang="pt-BR"`, pandoc `--metadata lang=pt-BR`, POSIX `pt_BR.UTF-8`.
3. Rejeitar (com erro claro) tags fora do set suportado — v1 suporta só `en` e `pt-br`; erro explícito bate fallback silencioso.

**Warning signs:**
`grep -rn 'pt' scripts/ | grep -v 'pt-br'` encontra variantes dispersas; usuário reporta "configurei pt-BR e não aconteceu nada".

**Phase to address:**
Phase 1 (Contrato): `OUTPUT_LANG` entra no CONTEXT.md com normalização + tabela de mapping antes de qualquer script consumi-la.

---

### Pitfall 6: `sed` de title-case corrompe acentos em C locale — e Title Case é estilo errado em PT-BR; nomes derivados de arquivos não são traduzíveis

**What goes wrong:**
`generate-index.sh:79` e `generate-mkdocs.sh:29,35` geram labels via `sed 's/-/ /g; s/\b\(.\)/\u\1/g'`. Dois defeitos, ambos verificados NESTE host (2026-09-28):
1. **Corrupção de bytes:** com `LC_ALL=C`, `autenticação` → `Autentica\xFF\xA7\xC3\xA3O` (bytes mutilados + "o" final capitalizado por `\b` entre byte multibyte e ASCII). O sed em C locale processa octeto a octeto.
2. **Estilo:** mesmo em locale UTF-8, o resultado é Title Case por palavra ("Início Rápido"); PT-BR usa sentence case em headings ("Início rápido").
E um erro conceitual em potencial: labels derivados de nomes de arquivo/diretório do usuário NÃO são chrome — são naming do usuário; "traduzi-los" seria reescrever autoria (o projeto já decidiu que conteúdo/specs não se traduzem; o mesmo princípio vale para nomes derivados).

**Why it happens:**
A expressão é invisível e pré-existente; ninguém a testa com acento até o primeiro fixture pt-br com diretório acentuado.

**How to avoid:**
1. Separar chrome-label (traduz) de derived-label (passthrough): derived = `basename` sem transformação de case, sem tradução — só o `s/-/ /` se quiser.
2. Para chrome pt-br, escrever os labels já na forma final ("Início rápido") na tabela; nenhuma transformação de case em runtime.
3. Se algum transform permanecer: `LC_ALL=C.UTF-8` explícito no script (ou detectar e abortar), e teste com diretório acentuado no fixture.

**Warning signs:**
Labels de nav/índice com bytes quebrados ou capitalização inglesa na saída pt-br; `locale` do ambiente de CI/produção diferente do dev.

**Phase to address:**
Phase 2 (extração de labels das superfícies MkDocs/index — é onde as duas expressões vivem).

---

### Pitfall 7: PDF em pt-br com hifenização, aspas e datas em inglês — e o fix que quebra o `en` byte-idêntico

**What goes wrong:**
Pandoc decide hyphenation, smart quotes e localização de data pela variável de metadata `lang` (BCP-47). `to-pdf.sh`/`to-pdf.ps1` não passam `lang` nenhum → PDF pt-br hifeniza como inglês, quebra linhas errado em palavras acentuadas, e qualquer `\today`/data gerada pelo template sai em inglês ("September 28, 2026" dentro de um documento "Especificações"). O segundo erro é a correção apressada: adicionar `--metadata lang=en` "para consistência" no path `en` muda a saída atual (babel/polyglossia passa a carregar) e quebra a barra byte-idêntica.

**Why it happens:**
O defeito é invisível no markdown intermediário e só aparece na tipografia do PDF final — e o host dev não tem pandoc/mkdocs instalados (ADR 0003), então ninguém vê localmente.

**How to avoid:**
1. `--metadata lang=pt-BR` SOMENTE no branch pt-br (`OUTPUT_LANG != en`); branch `en` não ganha flag nenhuma.
2. Como não há verificação ao vivo do PDF no host (ADR 0003), o gate viável no v1 é estrutural: assert de que o comando pandoc montado contém `lang=pt-BR` quando `OUTPUT_LANG=pt-br` e não contém quando `en` (testável sem pandoc — ecoar o comando).
3. Registrar a limitação weasyprint: hyphenation via weasyprint é CSS (`hyphens: auto` + `lang` no HTML), não babel — engines diferentes honram `lang` de forma diferente; não prometer hifenização perfeita multi-engine no v1.

**Warning signs:**
Review do comando pandoc gerado; PDF de teste com palavras acentuadas quebradas em posição de hifen inglês; data em inglês no PDF pt-br.

**Phase to address:**
Phase 3 (superfície PDF), com o assert estrutural já escrito na Phase 1 como critério de aceite.

---

### Pitfall 8: Calques na prosa dos agents — convenção em prosa é inauditável; LLM ignora glossário que não está no prompt dele

**What goes wrong:**
A prosa gerada pelos agents (overview do Home.md, _Sidebar, resumos) sai com "deployar/printar/commitar", tiques de LLM ("é importante notar", superlativos, listas performáticas), ou inglês intacto onde devia haver equivalente consagrado. O glossário existe no CONTEXT.md, mas o subagent de formato recebe só o dispatch prompt — se a convenção mora só no CONTEXT.md referenciado, o subagent não a aplica consistentemente (referência consultada sob demanda é referência ignorada sob pressão).

**Why it happens:**
Dois vetores: (a) instrução de estilo em prosa é subjetiva — dois reviewers divergem, não há gate; (b) a arquitetura de agents do skill (SKILL.md dispatch → agents/*.md) não propaga variáveis além das listadas; `OUTPUT_LANG` e o glossário precisam entrar no fluxo de dispatch explicitamente.

**How to avoid:**
1. Glossário como LISTA CHECÁVEL no CONTEXT.md (decisão já tomada no PROJECT.md): coluna termo-inglês → forma canônica; incluir os calques proibidos como denylist explícita.
2. Cada `agents/format-*.md` ganha linha de instrução inline ("prosa que você escreve em `$OUTPUT_LANG`; termos do glossário do CONTEXT.md são obrigatórios") — não só a referência ao arquivo.
3. Gate grep no critério de completion do agent: saída pt-br não contém denylist (`deployar|printar|commitar|linkar|salvar save|é importante notar|in summary` etc.); o grep é determinístico e entra no critério de conclusão do milestone (o rubric de 22 dimensões já exige critérios checáveis — mesma filosofia).
4. Definir o par de-decisão por termo ambíguo AGORA (Spec → "Spec" mesmo? → recomendo manter "Spec/Design/Tasks" untranslated: são nomes de artefatos do método, não prosa) — caso contrário cada agent decide diferente por execução = drift de vocabulário.

**Warning signs:**
Review de saída pt-br encontra calque; dois agents traduzem o mesmo termo diferentemente na mesma execução; instruction de idioma só no CONTEXT.md, ausente nos agents.

**Phase to address:**
Phase 4 (prosa/glossário), mas o desenho da denylist e a decisão Spec/Design/Tasks são Phase 1 (contrato) — são decisões de vocabulário, não de implementação.

---

### Pitfall 9: Assumir que a superfície Swagger pode ser localizada — o widget não tem i18n

**What goes wrong:**
O milestone promete "chrome gerado pelos scripts em PT-BR nas 5 superfícies (... Swagger)". Mas o Swagger UI não tem suporte a i18n — feature request aberto swagger-api/swagger-ui#4776, sem solução upstream; workarounds são hacks (override de strings pós-bundle, patch de DOM, forks). Quem promete "Swagger em PT-BR" entrega no máximo título e HTML em volta; "Authorize", "Try it out out", "Schemas" ficam em inglês — e o milestone parece incompleto.

**Why it happens:**
"Superfície" ambíguo: o que o skill gera (templates/swagger-ui.html: `<title>{{PROJECT_NAME}} — API Docs</title>`) é localizável; o que o CDN entrega (swagger-ui-dist) não é.

**How to avoid:**
1. Escopar a superfície Swagger ao chrome do skill: `<title>`, e adicionar `<html lang="pt-BR">` (hoje ausente — templates/swagger-ui.html:2 não tem `lang`, o que também é gap de acessibilidade/SEO no en).
2. Documentar o limite (candidato a ADR): widget permanece em inglês por limitação upstream; revisar se #4776 fechar.
3. Não construir override de strings do widget no v1 — custo permanente por execução, falha no gate MET-1.

**Warning signs:**
Item de roadmap com verbo "traduzir Swagger UI"; scope creep para forks/CDN self-hosted.

**Phase to address:**
Phase 3 (superfície Swagger), com o limite documentado na Phase 1 (escopo do que "5 superfícies" significa).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Tradução inline (`if OUTPUT_LANG=pt-br` com strings hardcoded) por script | Primeira superfície traduzida em horas | N tabelas divergentes × 10 arquivos; todo label novo exige 4+ edits | Nunca além de um spike descartável de 1 superfície |
| Fazer só os `.sh`, deixar `.ps1` "para depois" | Metade do esforço | Usuário Windows com saída mista EN/PT; drift composto (já existente) volta a crescer | Nunca — CONTEXT.md promete paridade entre gêmeos |
| Fixture golden só para a superfície MkDocs | Gate rápido | Regressões em PDF/Wiki/Doku/Swagger saem sem detecção (byte-bar é o requisito central do milestone) | Nunca para a barra byte-idêntica; no máximo, durante a Phase 1 antes de completar o conjunto |
| Traduzir labels em bulk via LLM sem revisão contra glossário | Velocidade | Calques assados no chrome de 10 arquivos; retrabalho total | Aceitável como rascunho; não aceitável sem o gate grep da Pitfall 8 |
| Aceitar qualquer tag de entrada sem normalizar (`pt-BR`, `PT_BR`, `pt`) | Menos código | Comportamento diferente por script/caller; bugs "funciona na minha shell" | Nunca — normalização é ~5 linhas |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| MkDocs Material | Só traduzir `site_name`; esquecer `theme.language` → placeholder de busca, footer, next/prev em inglês; ou usar formato errado (`locale: pt_br`) que falha silencioso | `theme.language: pt-BR` no branch pt-br (ambos `pt` e `pt-BR` completos segundo docs oficiais); branch `en` NÃO ganha a key (hoje não existe — manter para byte-identity do mkdocs.yml); confirmar código exato na página oficial ao implementar (ADR 0003: sem mkdocs no host) |
| pandoc (PDF) | Omitir `lang` (Pitfall 7); ou adicionar em todos os paths | `--metadata lang=pt-BR` só no branch pt-br; assert estrutural do comando |
| weasyprint | Assumir que honra `lang` como LaTeX | Hyphenation é CSS (`hyphens: auto` + lang); sem CSS custom, sem hifenização pt — documentar, não prometer |
| GitHub Wiki | Traduzir filenames de páginas ("Início.md") → URLs percent-encoded, links `[[ ]]` frágeis; ou esquecer que Home/_Sidebar são prosa de agent (Pitfall 8) | Filenames preservados como hoje; traduzir só labels do _Sidebar e a prosa do Home |
| DokuWiki | Assumir chrome próprio — `to-dokuwiki.sh` é quase todo passthrough pandoc; o chrome é 1 linha de footer (`to-dokuwiki.sh:37`) + o que o agent escreve | Inventariar antes: superfície menor do que parece; esforço está no footer e na prosa |
| Windows PowerShell 5.1 | Testar só no PS7 (Pitfall 4) | Pinning `-Encoding UTF8` na leitura; preservar BOM existente na escrita; `.ps1` com literais acentuados salvos com BOM |

## Performance Traps

Não há hot path aqui (runs são one-shot por projeto); as "traps de escala" são de superfície de verificação:

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Verificação manual (rodar e olhar) por superfície | Humano pula camadas; regressões invisíveis até usuário reportar | Harness de fixture: script que roda os 10 consumers × 2 langs contra o tree de teste e faz byte-compare | ≥ 2 superfícies × 2 idiomas (já no fim da Phase 2) |
| Depender de `mkdocs build --strict` ao vivo como único gate | Nunca roda no host dev (ADR 0003); CI não existe no projeto | Gates estruturais (fixtures + asserts de comando) que não precisam das deps instaladas | Desde o dia 1 do milestone |
| Fixture sem diretório acentuado | Sed/encoding bugs (Pitfalls 4 e 6) passam despercebidos | `features/autenticação/` no tree de teste | Primeira execução pt-br |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Interpolar `PROJECT_NAME`/labels traduzidos em YAML sem quoting (`site_name: $PROJECT_NAME — ...`, generate-mkdocs.sh:43) | Nome com `:`/`#` quebra ou injeta config YAML (pre-existente; strings pt aumentam o espaço de caracteres, não o vetor) | Quoting explícito ao tocar a linha; validação de entrada do nome na onboarding |
| Interpolar em HTML sem escape (`<title>{{PROJECT_NAME}}` no swagger-ui.html) | `<`/`"` no nome quebra ou injeta HTML | Escape ao inserir labels pt-br; caso de teste com nome hostil no fixture |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|------------------|
| Default flip silencioso para pt-br no update | Usuário inglês existente atualiza a skill e a documentação sai em português sem aviso | Nota de release explícita + instrução "OUTPUT_LANG=en preserva o comportamento anterior" no README; é decisão do projeto (público lusófono), mas o aviso é obrigatório |
| Router do SKILL.md só entende inglês ("pdf", "deploy", "not sure") com default pt-br | Pedido em PT ("gera um pdf do projeto") cai no onboarding genérico; fricção em todo usuário-alvo | Fora do escopo do milestone (router é input, não output) — mas registrar como decisão consciente em Out of Scope, não como acidente; candidato ao próximo milestone |
| "Localizar" datas para dd/mm/yyyy no pt-br | Fixture nunca-estável, bar byte-idêntica frágil, formato ambíguo para tooling | Manter ISO `YYYY-MM-DD` nos dois idiomas (locale-neutral, é o formato atual); documentar |
| Console dos scripts misto (mensagens en, docs pt) | Baixo — agents retransmitem ao usuário na língua da conversa | Manter console em inglês no v1 (decisão explícita, Pitfall 3) |

## "Looks Done But Isn't" Checklist

- [ ] **Fixtures en:** golden files byte-idênticos por geminho (.sh e .ps1 separados) congelados ANTES do primeiro refactor — verificar `cmp` vazio
- [ ] **Data:** token de data mascarado (ou same-day) documentado no gate — verificar que o diff vazio não depende de sorte
- [ ] **Acento:** tree de teste inclui `features/autenticação/` e roda nos DOIS shells — verificar ausência de mojibake/bytes quebrados nos dois idiomas
- [ ] **Camadas:** cada superfície checada nas 4 camadas (script-chrome, theme-chrome, agent-prose, console) — verificar gate grep com allowlist do glossário
- [ ] **mkdocs.yml en:** sem key `language` (ausente hoje) — verificar diff vazio do arquivo gerado
- [ ] **mkdocs.yml pt-br:** com `theme.language` no formato que o Material aceita — verificar contra docs oficiais na implementação
- [ ] **Comando pandoc:** contém `lang=pt-BR` só no branch pt-br — assert estrutural sem precisar de pandoc
- [ ] **Swagger:** escopo = título + `lang` attribute; widget documentado como limite upstream — verificar ADR/nota
- [ ] **Prosa:** denylist de calques sem hits na saída pt-br — gate grep no critério de completion
- [ ] **Tag:** `OUTPUT_LANG=pt-BR`, `=pt_BR`, `=PT-br` todas normalizam para o mesmo comportamento; valor inválido dá erro claro — teste de 4 entradas

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| 1. Barra byte-idêntica quebrada | LOW | Reintroduzir fixtures se perdidos: `git checkout` do commit pré-refactor, regenerar goldens, re-apply refactor com discipline |
| 2. Label-map drift | MEDIUM | Consolidar para a fonte única tarde = retradução + reconciliação de 10 arquivos; quanto mais superfícies traduzidas inline, mais caro |
| 3. Tradução parcial | LOW | Inventário tardio pega strings residuais com grep; retrabalho pontual por string perdida |
| 4. Mojibake PowerShell | HIGH (se publicado) | Docs publicados com mojibake precisam regeneração completa; detectar cedo com fixture acentuado torna o custo LOW |
| 5. Fragmentação de tag | MEDIUM | Refactor de normalização é mecânico, mas usuários com configs quebradas (pt-BR não reconhecido) já ficaram sem efeito — nota de release |
| 6. sed/case corruption | LOW | Derived-labels passthrough elimina a expressão; regenerar saídas |
| 7. PDF lang | LOW | Adicionar flag no branch certo; outputs PDF são regeneráveis por natureza |
| 8. Calques publicados | MEDIUM | Prosa já entregue ao usuário com calque mancha reputação da skill; denylist + regeneração das saídas afetadas |
| 9. Escopo Swagger | LOW | Redefinir escopo no roadmap + ADR antes de implementar; custo alto só se hack de override já foi construído |

## Pitfall-to-Phase Mapping

Fases pressupostas (a criar pelo roadmap; nomes propostos):

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| 1. Byte-identical bar | Phase 1 — Contrato & Fixtures | `cmp` vazio en-vs-golden em CI-less gate script |
| 2. Label-map drift | Phase 2 — Extração de labels (fonte única desenhada aqui) | Lint de paridade estrutural entre gêmeos; uma única tabela no repo |
| 3. Tradução parcial | Phase 1 (inventário) + 2/3 (gates) | Gate grep por superfície com allowlist |
| 4. Encoding PowerShell | Phase 2 (primeiro .ps1 tocado) | Fixture acentuado byte-check nos dois shells |
| 5. Fragmentação de tag | Phase 1 — Contrato (CONTEXT.md) | Teste das 4 variantes de entrada → mesmo comportamento |
| 6. sed title-case | Phase 2 (MkDocs/index) | Label derived = passthrough; saída pt-br sem Title Case inglês |
| 7. PDF lang | Phase 3 — Superfícies restantes | Assert estrutural do comando pandoc |
| 8. Calques/glossário | Phase 4 — Prosa & gates (decisões de vocabulário na Phase 1) | Denylist grep no critério de completion dos agents |
| 9. Escopo Swagger | Phase 1 (definição de "5 superfícies") + Phase 3 (impl.) | ADR registrando limite upstream |

**Ordering rationale:** Phase 1 (contrato: OUTPUT_LANG no CONTEXT.md, normalização de tag, tabela de mapping, glossário/denylist, inventário de strings, fixtures goldens) é pré-requisito de todas — é onde 5 dos 9 pitfalls se previnem por decisão, não por código. Phase 2 valida a fonte única de labels nas duas superfícies de maior risco (MkDocs/index, onde vivem o sed e a divergência de gêmeos). Phase 3 replica o padrão provado nas superfícies restantes, cada uma com sua gotcha específica (PDF/lang, Wiki/filenames, Swagger/limite). Phase 4 fecha prosa de agents e a nota de migração do default flip.

## Sources

- **Codebase (HIGH — leitura direta):** `scripts/generate-index.sh` (linhas 38–63 branches, 79 sed, 105 data/footer), `scripts/generate-index.ps1` (84 footer URL divergente, 87 Out-File utf8), `scripts/generate-mkdocs.sh` (29,35 sed; 43–44 site_name/description), `scripts/generate-mkdocs.ps1`, `scripts/to-pdf.ps1` (29 Get-Content -Raw, 33 Out-File), `scripts/to-pdf.sh`, `scripts/to-dokuwiki.sh` (37 footer), `templates/swagger-ui.html` (2 sem lang, 6 title), `templates/index.md`, `SKILL.md` (router inglês), `CONTEXT.md`, `agents/format-mkdocs.md`, `agents/format-github-wiki.md` (47–56)
- **Reprodução local 2026-09-28 (HIGH p/ este host):** sed title-case em `LC_ALL=C` corrompendo `autenticação`; correto em locale UTF-8; host em `pt_BR.UTF-8`
- Material for MkDocs — Changing the language (`pt` e `pt-BR` completos; key `language`): https://squidfunk.github.io/mkdocs-material/setup/changing-the-language — MEDIUM
- MkDocs user-guide configuration (`locale` em built-in themes): https://www.mkdocs.org/user-guide/configuration — MEDIUM
- mkdocs-static-i18n issue 196 (convenções locale/language divergentes no ecossistema): https://github.com/ultrabug/mkdocs-static-i18n/issues/196 — LOW/MEDIUM
- Microsoft about_Character_Encoding (PS 5.1: BOM em qualquer Unicode write; ANSI default p/ BOM-less; PS7 utf8NoBOM): via PowerShell-Docs — MEDIUM
- Pandoc User's Guide (variável `lang`: babel/polyglossia hyphenation, smart quotes, dates): https://pandoc.org/MANUAL.html — MEDIUM
- Swagger UI issue #4776 (i18n não suportado, aberto): https://github.com/swagger-api/swagger-ui/issues/4776 — MEDIUM; corroboração SmartBear community (LOW)
- GNU sed manual (C locale processa por octeto): MEDIUM

---
*Pitfalls research for: retrofit de output-language (pt-br default, en byte-idêntico) em skill bash+markdown existente*
*Researched: 2026-09-28*
