# Changelog

Todas as mudanças notáveis deste projeto são registradas aqui, na ordem do milestone mais
recente primeiro. O formato segue a convenção [Keep a Changelog](https://keepachangelog.com/).

## [OUTPUT_LANG] — 2026-09-30

### Nota de release — o default passou a ser pt-br

O idioma de saída virou um parâmetro de contrato (`OUTPUT_LANG`), com valores `en` e
`pt-br`. **O default é `pt-br`** — quem quiser a saída anterior passa `en` explicitamente
no onboarding.

Com `OUTPUT_LANG=en` o comportamento anterior é preservado byte a byte no lado `.sh`. Não
é promessa de prosa: é gate executável — `tests/regress.sh` compara a saída fresca contra
golden fixtures congelados antes de qualquer refactor, com máscara de data simétrica.

A emissão de idioma é **aditiva**. A chave `theme.language` do tema MkDocs, as flags de
idioma do pandoc (`-M lang`, `-M toc-title`) e o atributo `lang` do HTML do Swagger
aparecem SOMENTE com `pt-br`; com `en` nenhuma linha extra é emitida, e é exatamente isso
que preserva os bytes.

O que a skill NÃO faz: nunca traduz conteúdo de spec do usuário; nunca traduz caminho,
nome de arquivo, âncora ou alvo de link gerado; e nunca faz fallback silencioso para `en`
quando uma chave de catálogo falta — chave ausente interrompe a geração nomeando a chave.

### Adicionado

- `OUTPUT_LANG` na camada de contrato, com normalização sem distinção de caso na entrada
  e tabela de projeção por consumidor (`pt-BR` para MkDocs Material/pandoc/HTML, `pt_BR`
  para Pyphen)
- Catálogos de rótulos por idioma em `templates/lang/en.lang` e `templates/lang/pt-br.lang`
  (formato `KEY=value`, UTF-8 sem BOM)
- O catálogo consumido pelas cinco superfícies publicáveis (MkDocs índice+nav, GitHub
  Wiki, DokuWiki, PDF, Swagger UI)
- O loader compartilhado dos gêmeos `.ps1` (`scripts/lib/catalog.ps1`): parser quote-aware,
  gate de allowlist antes da resolução de caminho, e gravador UTF-8 sem BOM
- O posicional `output_lang` nos quatro gêmeos `.ps1` catalog-driven (`generate-index.ps1`,
  `generate-mkdocs.ps1`, `to-pdf.ps1`, `to-dokuwiki.ps1`)
- O glossário anti-calque no `CONTEXT.md` — denylist de verbos anglicizados sem registro
  no VOLP, allowlist de formas consagradas, e a regra de desempate via VOLP (D-24)
- Os seis harnesses de teste criados neste milestone:
  - `tests/regress.sh` — a saída `en` reproduz os golden fixtures byte a byte, por
    geminho `.sh`/`.ps1`
  - `tests/fail-closed.sh` — falha fechada por chave ausente, paridade de keyset entre
    catálogos, gate de allowlist de idioma
  - `tests/no-mixed-output.sh` — zero saída mista de idioma nas cinco superfícies pt-br
  - `tests/ps1-contract.sh` — o contrato dos quatro gêmeos `.ps1`, com gates estruturais
    que rodam sem PowerShell instalado
  - `tests/no-calques.sh` — a denylist de calques na prosa e na saída pt-br
  - `tests/wiki-links.sh` — a conversão de link do fluxo GitHub Wiki

### Alterado

- O default de `OUTPUT_LANG` virou `pt-br` (era `en` implícito, sem parâmetro)
- As strings que divergiam entre os gêmeos `.sh`/`.ps1` convergiram por construção da
  fonte única — o caso concreto é a URL do rodapé do índice (`generated_by`), que o
  gêmeo `.ps1` emitia como `https://opencode.ai` e o `.sh` como a URL do repositório;
  hoje as duas leem a mesma chave do catálogo
- A gravação de saída dos gêmeos `.ps1` passou a UTF-8 sem BOM, nos dois idiomas
- A perna `.ps1` de `tests/regress.sh` deixou de ser stub e passou a rodar a cadeia real
  contra `tests/fixtures/golden-ps1/`

### Corrigido

- O slice de argumentos que indexava um elemento além do fim do array em
  `generate-index.ps1` e em `to-dokuwiki.ps1` (produzia um elemento nulo à direita da
  lista de diretórios/arquivos)
- O vazamento de caminho absoluto do host para dentro do `index.md`/`mkdocs.yml`
  publicado em hosts Unix (`generate-index.ps1` e, na mesma classe de defeito,
  `generate-mkdocs.ps1`)
- As duas expressões `sed` de conversão de link do fluxo GitHub Wiki: a primeira abortava
  com referência de grupo de captura inválida (CR-01) e a segunda descartava o texto
  visível original do link em vez de preservá-lo
- O laço de conversão de link do GitHub Wiki, que quebrava ao encontrar um nome de
  arquivo com espaço
- `to-pdf.ps1` ligava apenas o primeiro arquivo de qualquer invocação multi-arquivo ao
  parâmetro de array — todo o restante caía em silêncio no array de argumentos não
  usados, produzindo um livro de um arquivo só
- `to-dokuwiki.ps1` falhava ao criar o diretório-pai de um page-id contendo `:`
  (o separador de page-id do DokuWiki), porque `Split-Path -Parent` interpreta `:` no
  último segmento como qualificador de unidade Windows

### Limitações conhecidas

Cada limitação abaixo tem motivo registrado — nenhuma é omissão silenciosa.

| Limitação | Motivo | Onde está registrada |
|-----------|--------|----------------------|
| O chrome do bundle Swagger UI permanece em inglês | Upstream não tem i18n oficial; forkar para traduzir os botões reprova no gate MET-1 do rubric de qualidade | `CONTEXT.md`, política de idioma (D-11) |
| Windows PowerShell 5.1 não foi verificado num host real | Não existe host Windows neste ambiente; o `pwsh` disponível é PowerShell 7 e não exercita o fallback ANSI nem a adição de BOM do 5.1 | `.planning/STATE.md`, Blockers, desde a Phase 1 |
| `generate-mkdocs.ps1` grava `docs/mkdocs.yml`, não `mkdocs.yml` na raiz com `docs_dir` explícito | Divergência estrutural pré-existente; paridade estrutural de saída entre gêmeos não é critério de sucesso da Phase 4 (D-19) | não-objetivos do plano `04-03` |
| `generate-mkdocs.ps1` não copia a árvore de specs para dentro de `docs/specs` | mesma decisão D-19 | não-objetivos do plano `04-03` |
| `to-pdf.ps1` não emite heading por arquivo nem separador entre arquivos | mesma decisão D-19 | não-objetivos do plano `04-03` |
| `generate-index.ps1` emite as linhas da tabela de visão geral sem checagem de existência e sem glifo de célula ausente | mesma decisão D-19 | não-objetivos do plano `04-01` |
| `generate-mkdocs.ps1` itera o diretório de specs sem recursão — nunca alcança um diretório aninhado como `features/autenticação/` | defeito pré-existente, fora do escopo de correção do plano `04-03` | `04-03-SUMMARY.md` |
| Não há CI rodando os gates automaticamente | O repositório não tem workflow nenhum hoje; instalar um exigiria decidir o runner com `pandoc` e `pwsh`, e é escopo novo | esta tabela |
| O título e a descrição do esqueleto de `openapi.yml` escritos por `agents/format-swagger.md` continuam em inglês | Escopo Swagger fixado em título da página e atributo de idioma; o esqueleto é chrome de Camada 4 fora desse recorte | `docs/chrome-inventory.md`, Camada 4 |
| Este host de desenvolvimento não tem `mkdocs-material` nem engine de PDF (`weasyprint`/`wkhtmltopdf`) instalados | Ambiente de dev sem esses pacotes; a execução pt-br de ponta a ponta com todos os engines reais não foi exercitada neste host — evidência parcial do critério 5 do ROADMAP | `04-05-SUMMARY.md`, verificação dos critérios de sucesso |

Registro de reprodutibilidade das capturas: `tests/fixtures/manifest.md`. Mapa de chave
para sítio de todo o chrome publicado: `docs/chrome-inventory.md`.
