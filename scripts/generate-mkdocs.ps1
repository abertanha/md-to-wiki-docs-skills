# generate-mkdocs.ps1 — Generate mkdocs.yml from .specs tree
$ProjectName = if ($args[0]) { $args[0] } else { "Project" }
$SpecsDir = if ($args[1]) { $args[1] } else { ".specs" }

New-Item -ItemType Directory -Path "docs" -Force | Out-Null

$repoUrl = ""
$gitRemote = git remote get-url origin 2>$null
if ($gitRemote) {
  $repoUrl = $gitRemote -replace '\.git$', ''
}
if (-not $repoUrl -and (Test-Path ".specs/config.json")) {
  $repoUrl = (Get-Content ".specs/config.json" -Raw | ConvertFrom-Json).repo_url
}

$nav = @"
  - Home: index.md
"@

Get-ChildItem "$SpecsDir" -Directory | Sort-Object Name | ForEach-Object {
  $dir = $_.FullName
  $name = $_.Name
  $label = ($name -replace '-', ' ') -replace '\b\w', { $_.Value.ToUpper() }

  $mdFiles = Get-ChildItem $dir -Filter "*.md" | Where-Object { $_.Name -notlike '_*' } | Sort-Object Name
  if (-not $mdFiles) { return }

  $nav += "`n  - $label`:"
  foreach ($file in $mdFiles) {
    $fileLabel = (($file.BaseName -replace '-', ' ') -replace '\b\w', { $_.Value.ToUpper() })
    $relPath = $file.FullName -replace '^.[/\\]', '' -replace '\\', '/'
    $nav += "`n    - $fileLabel`: $relPath"
  }
  $nav += "`n"
}

$issuesEntry = ""
if (Test-Path ".specs/issues/cache") {
  $issuesCount = (Get-ChildItem ".specs/issues/cache/*.json").Count
  if ($issuesCount -gt 0) {
    $issuesEntry = "  - Issues: issues/"
  }
}

@"
site_name: $ProjectName — Specifications
site_description: Auto-generated documentation from spec-driven development
repo_url: $repoUrl
edit_uri: blob/main/

theme:
  name: material
  features:
    - navigation.tabs
    - navigation.sections
    - toc.integrate

nav:
$nav
$issuesEntry
"@ | Out-File -FilePath "docs/mkdocs.yml" -Encoding utf8

Write-Output "Generated docs/mkdocs.yml"
