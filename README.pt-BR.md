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

Todos os scripts aceitam **argumentos posicionais idênticos** entre `.sh` e `.ps1` — sem flags, sem sintaxe específica de SO.

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
├── SKILL.md                  # Orquestrador principal
├── README.md                 # Este arquivo (pt-BR)
├── README.en.md              # Documentação em inglês
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
│   └── to-dokuwiki.ps1       # (PowerShell)
├── templates/                # Templates reutilizáveis
│   ├── index.md              # Template da landing page
│   └── swagger-ui.html       # Wrapper Swagger UI
└── agents/                   # Subagentes para formatos complexos
    ├── swagger-builder.md    # Geração de OpenAPI 3.0
    └── pdf-builder.md        # Geração de PDF com Pandoc
```

## Instalação

### Opção 1 — Clone e link simbólico

```bash
git clone <url-do-repo>
ln -s "$(pwd)/md-to-wiki" ~/.config/opencode/skills/md-to-wiki
```

### Opção 2 — Cópia direta

```bash
git clone <url-do-repo>
cp -r md-to-wiki ~/.config/opencode/skills/md-to-wiki
```

### Opção 3 — Carregar via URL (opencode apenas)

Adicione ao seu `opencode.json`:
```json
{
  "skills": {
    "urls": ["https://raw.githubusercontent.com/<user>/<repo>/main/skills/md-to-wiki/SKILL.md"]
  }
}
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
