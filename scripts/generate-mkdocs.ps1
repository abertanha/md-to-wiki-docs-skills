# generate-mkdocs.ps1 — Build a MkDocs Material site skeleton from a specs tree
# Usage: generate-mkdocs.ps1 [project_name] [specs_dir] <output_lang>

# Dot-source BEFORE anything else — the loader is the single source of the
# parser, the allowlist gate and the BOM-less writer (D-18).
. (Join-Path $PSScriptRoot 'lib/catalog.ps1')

$ProjectName = if ($args[0]) { $args[0] } else { "Project" }
# Strip newlines: a CR/LF in $ProjectName would inject a second YAML key (T-RETRO-02).
$ProjectName = ($ProjectName -replace '[\r\n]', ' ').Trim()
$SpecsDir = if ($args[1]) { $args[1] } else { ".specs" }
$OutputLangRaw = $args[2]

if (-not $OutputLangRaw) {
  Write-Output "Usage: generate-mkdocs.ps1 [project_name] [specs_dir] <output_lang> — output_lang required, supported: en, pt-br"
  exit 1
}

# Order is the security control (T-04-01): the allowlist gate runs BEFORE
# any path is built from the value, so a hostile output_lang never reaches
# the catalog path resolver below.
$OutputLang = Resolve-OutputLang -Value $OutputLangRaw
$CatalogPath = Get-CatalogPath -ScriptRoot $PSScriptRoot -OutputLang $OutputLang
$Catalog = Get-Catalog -CatalogPath $CatalogPath

# Bootstrap up front, before any byte of output is written — a gate covering
# only part of the keys this script expands would let partial output escape
# before the error surfaces.
$RequiredKeys = @('site_name_suffix', 'site_description', 'nav_home', 'nav_issues')
Assert-CatalogKey -Catalog $Catalog -Keys $RequiredKeys

$siteNameSuffix = $Catalog['site_name_suffix']
$siteDescription = $Catalog['site_description']
$navHome = $Catalog['nav_home']
$navIssues = $Catalog['nav_issues']

# theme.language projection (D-12, QUAL-01) — ADDITIVE, never unconditional:
# Material's own default is already `en`, so emitting the key on that branch
# would change the YAML's bytes without changing behavior. The pt-br branch
# below projects the BCP 47 region-cased form for this consumer, decided
# once at this single point of use.
switch ($OutputLang) {
  'en' { $ThemeLanguage = '' }
  'pt-br' { $ThemeLanguage = "  language: pt-BR`n" }
}

New-Item -ItemType Directory -Path "docs" -Force | Out-Null

$repoUrl = ""
$gitRemote = git remote get-url origin 2>$null
if ($gitRemote) {
  $repoUrl = $gitRemote -replace '\.git$', ''
}
if (-not $repoUrl -and (Test-Path ".specs/config.json")) {
  $repoUrl = (Get-Content ".specs/config.json" -Raw | ConvertFrom-Json).repo_url
}
# Strip newlines from repo_url — same YAML injection vector as $ProjectName (T-RETRO-02).
$repoUrl = ($repoUrl -replace '[\r\n]', '').Trim()

$nav = @"
  - ${navHome}: index.md
"@

# D-16-class fix (mirrors generate-index.ps1's Resolve-Path fix): derive a
# path relative to cwd instead of stripping a fixed-width prefix from
# $file.FullName, which Get-ChildItem always returns absolute — the previous
# regex (`^.[/\\]`) never matched a Unix absolute path (no single leading
# char is followed by a slash), so it silently left the full host temp-dir
# path in the published nav entry (T-04-08-class information disclosure).
$cwd = (Get-Location).ProviderPath

Get-ChildItem "$SpecsDir" -Directory | Sort-Object Name | ForEach-Object {
  $dir = $_.FullName
  $name = $_.Name
  $label = ($name -replace '-', ' ') -replace '\b\w', { $_.Value.ToUpper() }

  $mdFiles = Get-ChildItem $dir -Filter "*.md" | Where-Object { $_.Name -notlike '_*' } | Sort-Object Name
  if (-not $mdFiles) { return }

  $nav += "`n  - $label`:"
  foreach ($file in $mdFiles) {
    $fileLabel = (($file.BaseName -replace '-', ' ') -replace '\b\w', { $_.Value.ToUpper() })

    $relPath = $null
    try {
      $relPath = Resolve-Path -Relative -Path $file.FullName -ErrorAction Stop
    } catch {
      $relPath = $file.FullName
    }
    if ($relPath.StartsWith($cwd)) {
      $relPath = $relPath.Substring($cwd.Length)
    }
    $relPath = $relPath -replace '\\', '/'
    $relPath = $relPath -replace '^\./', ''
    $relPath = $relPath -replace '^/', ''

    $nav += "`n    - $fileLabel`: $relPath"
  }
  $nav += "`n"
}

$issuesEntry = ""
if (Test-Path ".specs/issues/cache") {
  $issuesCount = (Get-ChildItem ".specs/issues/cache/*.json").Count
  if ($issuesCount -gt 0) {
    $issuesEntry = "  - ${navIssues}: issues/"
  }
}

$content = @"
site_name: $ProjectName ${siteNameSuffix}
site_description: ${siteDescription}
repo_url: $repoUrl
edit_uri: blob/main/

theme:
  name: material
${ThemeLanguage}  features:
    - navigation.tabs
    - navigation.sections
    - toc.integrate

nav:
$nav
$issuesEntry
"@

# Single writer for all generated output (D-15) — never a redirection
# cmdlet that adds a BOM on Windows PowerShell 5.1. Output path stays
# docs/mkdocs.yml: a pre-existing structural divergence from the .sh twin
# (which writes mkdocs.yml at the project root), preserved as a non-goal of
# this plan.
Write-Utf8NoBom -Path "docs/mkdocs.yml" -Content $content

# Console stays in English: the console is not published output, per
# CONTEXT.md's language policy.
Write-Output "Generated docs/mkdocs.yml"
