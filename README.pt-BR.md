<p align="center">
  <img src="assets/md-to-wikis.png" alt="md-to-wiki" width="600">
</p>

# md-to-wiki — Publicador de Especificações Multi-Formato

Converte arquivos markdown gerados por sessões _spec-driven_ (tlc-spec-driven, ai-harness-engineer, etc.) em documentação no formato que você escolher.

## Formatos suportados

| Formato | Descrição |
|---------|-----------|
| **HTML puro (MkDocs Material)** | Site estático com busca, modo escuro/claro, visual GitHub Docs |
| **Swagger / OpenAPI** | Gera spec OpenAPI 3.0 a partir de contratos de API nos markdowns e serve com Swagger UI ou ReDoc |
| **GitHub Tab Wiki** | Publica os markdowns direto na aba Wiki do repositório GitHub |
| **DokuWiki** | Converte para sintaxe DokuWiki e gera diretório pronto para importação |
| **PDF** | Compila todos os markdowns em um único documento PDF |

## Fluxo

1. **Onboarding** — O skill entrevista você para entender público-alvo, objetivos, escopo, quais arquivos incluir e se deseja vincular issues/PRs do GitHub
2. **Busca de issues/PRs** — Escaneia os markdowns por referências `#123`, pergunta se você tem mais links, então busca via `gh` CLI (fallback `curl`). Faz cache local. Apenas o repositório principal é buscado; referências entre repositórios são apenas mencionadas.
3. **Recomendação de formato** — Sugere o melhor formato baseado nas respostas
4. **Execução** — Gera a documentação no formato escolhido, anexando um **apêndice de Referências** com as issues/PRs buscadas
5. **Deploy** — Oferece opções de publicação (GitHub Pages, servidor local, etc.)

## Regras rígidas

- **Nenhum diagrama em ASCII.** Todo fluxo, arquitetura, sequência ou estado deve usar Mermaid (` ```mermaid ... ``` `)
- Diagramas ASCII encontrados nos markdowns de origem são convertidos para Mermaid automaticamente
- **Issues são cacheadas para sempre** — só refetch se o usuário pedir explicitamente

## Detecção de SO

O sistema operacional é detectado **uma única vez** durante a verificação de versão (etapa 1a). Todas as chamadas de script subsequentes reutilizam as mesmas variáveis:

| SO / Ambiente | `SCRIPT_EXT` | `SCRIPT_RUNNER` | Comportamento |
|---------------|-------------|-----------------|---------------|
| Linux / macOS | `.sh` | (vazio) | Executa `.sh` diretamente |
| Git Bash (MINGW/MSYS/CYGWIN) | `.sh` | (vazio) | Executa `.sh` nativamente (bash disponível) |
| PowerShell puro | `.ps1` | `powershell -File` | Executa `.ps1` via PowerShell |

As chamadas seguem o padrão:
```bash
$SCRIPT_RUNNER "$SKILL_DIR/scripts/<nome>$SCRIPT_EXT" <args_posicionais>
```

Os scripts aceitam os mesmos argumentos posicionais entre `.sh` e `.ps1`, sem exceção: quatro deles (`generate-index`, `generate-mkdocs`, `to-pdf`, `to-dokuwiki`) recebem um posicional obrigatório `output_lang` (`en`, `pt-br`) no mesmo slot nos dois hosts. Sem flags, sem sintaxe específica de SO fora isso.

### Idioma de saída

`output_lang` aceita `en` ou `pt-br`. O **default é `pt-br`**; o valor é normalizado sem distinção de caso na entrada (`pt-BR` ≡ `pt-br`). Ele é atribuído no onboarding e transmitido pelo dispatch prompt — nunca lido de variável de ambiente, o mesmo mecanismo de `AUDIENCE`. Valor desconhecido interrompe a geração e lista os valores suportados; não há fallback silencioso. `en` preserva o comportamento anterior byte a byte. Veja [CONTEXT.md](./CONTEXT.md) para a política de idioma completa (projeção por consumidor, formato do catálogo, regras de fail-closed).

## Valores de público-alvo

Os scripts `generate-index.sh` e `generate-index.ps1` aceitam os seguintes valores (singular e plural funcionam):

| Valor | Seções incluídas |
|-------|------------------|
| `developer`, `developers`, `devs` | Quick Start, tabela de funcionalidades, Arquitetura, Getting Started, Desenvolvimento |
| `stakeholder`, `stakeholders` | Overview com Roadmap, tabela de funcionalidades, Arquitetura, Getting Started |
| `general` (padrão) | Tabela Overview, tabela de funcionalidades, Arquitetura, Getting Started |

## Estrutura do Skill Set

```
md-to-wiki/
├── SKILL.md                  # Roteador fino (~80 linhas, ~600 tokens)
├── README.md                 # Documentação em inglês (principal)
├── README.pt-BR.md           # Este arquivo
├── CHANGELOG.md              # Notas de release, milestone mais recente primeiro
├── LICENSE                   # MIT
├── scripts/                  # Scripts auxiliares (.sh + .ps1 emparelhados)
│   ├── discover-sources.sh   # Escaneia diretório .specs/
│   ├── discover-sources.ps1  # (PowerShell)
│   ├── fetch-issues.sh       # Busca issues/PRs via gh + curl
│   ├── fetch-issues.ps1      # (PowerShell)
│   ├── generate-mkdocs.sh    # Gera mkdocs.yml com navegação
│   ├── generate-mkdocs.ps1   # (PowerShell)
│   ├── generate-index.sh     # Gera landing page personalizada
│   ├── generate-index.ps1    # (PowerShell)
│   ├── to-pdf.sh             # Concatena + gera PDF
│   ├── to-pdf.ps1            # (PowerShell)
│   ├── to-dokuwiki.sh        # Converte para sintaxe DokuWiki
│   ├── to-dokuwiki.ps1       # (PowerShell)
│   └── lib/
│       └── catalog.ps1       # scripts/lib/catalog.ps1 — loader .ps1 compartilhado (parser, gate de allowlist, gravador sem BOM)
├── templates/                # Templates reutilizáveis
│   ├── lang/
│   │   ├── en.lang           # Catálogo EN de rótulos de chrome
│   │   └── pt-br.lang        # Catálogo PT-BR de rótulos de chrome (default)
│   └── swagger-ui.html       # Wrapper Swagger UI
├── tests/                    # Harnesses de teste — o gate que um contribuidor roda (ver ## Testes)
│   ├── regress.sh            # saída en/.sh/.ps1 reproduz os golden fixtures byte a byte
│   ├── fail-closed.sh        # falha fechada por chave ausente, paridade de keyset, allowlist de idioma
│   ├── no-mixed-output.sh    # zero saída mista de idioma nas 5 superfícies pt-br
│   ├── ps1-contract.sh       # contrato dos gêmeos .ps1; gates estruturais rodam sem PowerShell
│   ├── no-calques.sh         # denylist anti-calque na prosa e na saída pt-br
│   ├── wiki-links.sh         # conversão de link do fluxo GitHub Wiki
│   └── fixtures/             # golden-sh/, golden-ps1/, tree/, manifest.md
└── agents/                   # Subagentes carregados sob demanda
    ├── onboarding.md         # Entrevista de descoberta + detecção de SO
    ├── format-mkdocs.md      # Geração de site MkDocs Material
    ├── format-swagger.md     # Geração de OpenAPI 3.0 + Swagger UI
    ├── format-github-wiki.md # Publicação no GitHub Wiki
    ├── format-dokuwiki.md    # Conversão para sintaxe DokuWiki
    ├── format-pdf.md         # Geração de PDF com Pandoc
    ├── references.md         # Apêndice de issues/PRs do GitHub
    └── deploy.md             # Opções de deploy
```

## Instalação

### Opção 1 — npx (recomendado)

```bash
npx github:abertanha/md-to-wiki-docs-skills scripts/install.sh
```

Para atualizar depois:
```bash
npx github:abertanha/md-to-wiki-docs-skills scripts/update.sh
```

### Opção 2 — Clone e link simbólico

```bash
git clone https://github.com/abertanha/md-to-wiki-docs-skills
ln -s "$(pwd)/md-to-wiki-docs-skills/md-to-wiki" ~/.config/opencode/skills/md-to-wiki
```

### Opção 3 — Cópia direta

```bash
git clone https://github.com/abertanha/md-to-wiki-docs-skills
cp -r md-to-wiki-docs-skills/md-to-wiki ~/.config/opencode/skills/md-to-wiki
```

### Locais de instalação

| Escopo | Caminho |
|--------|---------|
| Global (todas as sessões) | `~/.config/opencode/skills/md-to-wiki/` |
| Por projeto | `.opencode/skills/md-to-wiki/` |
| Cursor skills | `.cursor/skills/md-to-wiki/` ou `.cursor/skills-cursor/md-to-wiki/` |

## Dependências por formato

- **HTML:** `pip install mkdocs mkdocs-material`
- **Swagger:** Node.js + npx (ou apenas um navegador)
- **GitHub Wiki:** git
- **DokuWiki:** `sudo apt install pandoc` (Linux) ou `winget install pandoc` (Windows)
- **PDF:** `pip install weasyprint` + `sudo apt install pandoc`

## Compatibilidade Windows / PowerShell

Todos os scripts possuem versões `.sh` (Linux/macOS) e `.ps1` (Windows PowerShell). O skill detecta automaticamente o SO e executa o script correto. No Windows:

- **Git Bash** (MINGW/MSYS/CYGWIN) executa `.sh` diretamente — igual ao Linux
- **PowerShell puro** executa `.ps1` — **WSL não é necessário**
- gh CLI funciona no Windows: `winget install GitHub.cli`
- Pandoc no Windows: `winget install pandoc`
- mkdocs funciona via `pip install mkdocs mkdocs-material`
- Os gêmeos `.ps1` leem o mesmo catálogo de rótulos que os scripts `.sh` (`templates/lang/*.lang`), pelo loader compartilhado `scripts/lib/catalog.ps1`
- Toda saída gravada pelos gêmeos `.ps1` é UTF-8 sem BOM
- **Limitação conhecida:** Windows PowerShell 5.1 não foi verificado num host real — só PowerShell 7 (`pwsh`) em Linux/WSL. Veja [CHANGELOG.md](./CHANGELOG.md) para a lista completa de limitações conhecidas.

## Testes

Este repositório não tem CI — os harnesses abaixo são o gate que um contribuidor roda antes de abrir um PR. Cada um imprime uma linha `OK:`/`FAIL:`/`SKIPPED:` por afirmação e nunca passa em silêncio: um harness que não pode rodar imprime `SKIPPED:` com o motivo e encerra com status 3. **Golden fixture não se edita à mão — sob `tests/fixtures/golden-sh/` e `tests/fixtures/golden-ps1/`, `tests/regress.sh capture` é o único escritor.**

| Comando | O que prova |
|---------|-------------|
| `bash tests/regress.sh` | A saída `en` (`.sh` e `.ps1`) reproduz os golden fixtures byte a byte, com máscara de data simétrica |
| `bash tests/fail-closed.sh` | Falha fechada por chave ausente no catálogo, paridade de keyset entre os catálogos `en`/`pt-br`, o gate de allowlist de idioma e o passthrough de rótulo derivado |
| `bash tests/no-mixed-output.sh` | Zero saída mista de idioma nas cinco superfícies pt-br |
| `bash tests/ps1-contract.sh` | O contrato dos quatro gêmeos `.ps1` catalog-driven — os gates estruturais rodam mesmo sem PowerShell instalado |
| `bash tests/no-calques.sh` | A denylist de calques na prosa e na saída pt-br |
| `bash tests/wiki-links.sh` | A conversão de link do fluxo GitHub Wiki |

Códigos de saída: `0` tudo verde, `1` alguma divergência ou gate reprovado, `3` uma ou mais pernas `SKIPPED` por dependência somente-de-dev ausente (`pwsh` ou `pandoc`).

## Exemplos de uso

Durante uma sessão, diga algo como:

- "Build wiki from specs"
- "Publica os specs como site HTML"
- "Gera documentação no formato GitHub Wiki"
- "Exporta para DokuWiki"
- "Gera PDF dos specs"
- "Draw diagrama de arquitetura" → ativa a regra de Mermaid

## Entrada de múltiplos diretórios

Você pode especificar diretórios personalizados contendo arquivos markdown além de (ou em vez de) `.specs/`. O skill escaneia todos os diretórios informados e mescla os resultados.

## Compartilhamento

O skill set pode ser compartilhado como:
- Um repositório git — clone para sua pasta de skills
- Cópia direta — copie a pasta entre máquinas da equipe
- Via linguagem natural — cole a URL do repositório em qualquer sessão de agente e diga: *"Instala este skill de https://github.com/abertanha/md-to-wiki-docs-skills"*

## Licença

MIT
