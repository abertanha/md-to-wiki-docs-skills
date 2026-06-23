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

1. **Onboarding** — O skill entrevista você para entender público-alvo, objetivos, escopo e quais arquivos incluir
2. **Recomendação de formato** — Baseado nas respostas, sugere o formato mais adequado
3. **Execução** — Gera a documentação no formato escolhido
4. **Deploy** — Oferece opções de publicação (GitHub Pages, servidor local, etc.)

## Regras rígidas

- **Nenhum diagrama em ASCII.** Todo fluxo, arquitetura, sequência ou estado deve usar Mermaid (` ```mermaid ... ``` `)
- Diagramas ASCII encontrados nos markdowns de origem são convertidos para Mermaid automaticamente

## Instalação

Copie a pasta `md-to-wiki/` para um dos locais abaixo:

- **Global (todas as sessões):** `~/.config/opencode/skills/md-to-wiki/`
- **Projeto específico:** `.opencode/skills/md-to-wiki/`
- **Cursor:** `.cursor/skills-cursor/md-to-wiki/`

## Dependências por formato

- HTML: `pip install mkdocs mkdocs-material`
- Swagger: Node.js + npx (ou apenas um navegador)
- GitHub Wiki: git
- DokuWiki: `sudo apt install pandoc`
- PDF: `pip install weasyprint` + `sudo apt install pandoc`

## Como usar

Durante uma sessão, diga algo como:

- "Build wiki from specs"
- "Publica os specs como site HTML"
- "Gera documentação no formato GitHub Wiki"
- "Draw diagrama de arquitetura"  → ativa a regra de Mermaid
