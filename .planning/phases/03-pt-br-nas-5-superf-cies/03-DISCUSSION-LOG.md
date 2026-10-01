# Phase 3: pt-br nas 5 Superfícies - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-29
**Phase:** 03-pt-br-nas-5-Superfícies
**Areas discussed:** Assinatura dos scripts novos, dokuwiki_readme multilinhas, lang no Swagger

---

## Assinatura dos scripts novos

| Opção | Descrição | Selecionada |
|-------|-----------|-------------|
| A — segundo arg, antes dos arquivos | `to-pdf.sh <output.pdf> <output_lang> <file1.md>...` — consistente com pattern Phase 2; quebra call sites atuais nos agents | ✓ |
| B — primeiro arg | `output_lang` antes do output path — menos natural para scripts que produzem um arquivo de saída | |

**Escolha:** Opção A
**Notas:** Padrão da Phase 2 preservado. Agents `format-pdf.md` e `format-dokuwiki.md` atualizam call sites.

---

## dokuwiki_readme multilinhas

| Opção | Descrição | Selecionada |
|-------|-----------|-------------|
| A — múltiplas chaves granulares | Uma chave por linha (`dokuwiki_readme_step1`...) — muitas chaves, script monta com múltiplos printf | |
| B — 3 chaves por seção semântica | `heading` + `steps` (com `\n` literais) + `footer` — manuseável, `printf '%b'` expande os `\n` | ✓ |
| C — bloco hardcoded fora do catálogo | Não traduzível; reprova em CHROME-02 | |

**Escolha:** Opção B
**Notas:** `dokuwiki_readme_steps` usa `\n` literais; script usa `printf '%b\n'`. Wart de aspas simples no possessivo `DokuWiki's` documentado nos specifics.

---

## lang no Swagger

| Opção | Descrição | Selecionada |
|-------|-----------|-------------|
| A — placeholder `{{LANG}}` no template | `<html lang="{{LANG}}">` no template; `format-swagger.md` injeta o valor projetado via sed | ✓ |
| B — condicional no agent | `if pt-br → sed s/<html>/<html lang="pt-BR">/` — lógica de idioma no agent, frágil | |

**Escolha:** Opção A
**Notas:** Valor projetado `pt-BR` (BCP 47); normalização acontece no ponto de uso em `format-swagger.md`. Chrome do bundle Swagger UI permanece em inglês (sem i18n oficial).

---

## Deferred Ideas

- Gate `no-mixed-output` como harness dedicado vs extensão de `fail-closed.sh` — delegado ao planner
- Mais locales (v2)
- `pdf_generated_on` e `nav_issues` (Phase 4, gêmeos `.ps1`)
