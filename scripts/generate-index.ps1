# generate-index.ps1 — Create landing page from discovered sources
# Usage: generate-index.ps1 <project_name> <audience> <output_lang> [feature_base_dirs...]

# Dot-source BEFORE anything else — the loader is the single source of the
# parser, the allowlist gate and the BOM-less writer (D-18).
. (Join-Path $PSScriptRoot 'lib/catalog.ps1')

$ProjectName = $args[0]
$Audience = if ($args[1]) { $args[1] } else { "general" }
$OutputLangRaw = $args[2]

if (-not $ProjectName -or -not $OutputLangRaw) {
  Write-Output "Usage: generate-index.ps1 <project_name> <audience> <output_lang> [feature_base_dirs...] — output_lang required, supported: en, pt-br"
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
$RequiredKeys = @(
  'site_name_suffix', 'index_tagline', 'section_overview', 'table_section',
  'table_description', 'label_project_overview', 'desc_project_overview',
  'label_roadmap', 'desc_roadmap', 'label_architecture', 'desc_architecture',
  'section_features', 'table_feature', 'table_spec', 'table_design', 'table_tasks',
  'section_architecture', 'index_architecture_body', 'section_getting_started',
  'index_getting_started_body', 'section_development', 'index_development_body',
  'generated_by'
)
Assert-CatalogKey -Catalog $Catalog -Keys $RequiredKeys

$siteNameSuffix = $Catalog['site_name_suffix']
$indexTagline = $Catalog['index_tagline']
$sectionOverview = $Catalog['section_overview']
$tableSection = $Catalog['table_section']
$tableDescription = $Catalog['table_description']
$labelProjectOverview = $Catalog['label_project_overview']
$descProjectOverview = $Catalog['desc_project_overview']
$labelRoadmap = $Catalog['label_roadmap']
$descRoadmap = $Catalog['desc_roadmap']
$labelArchitecture = $Catalog['label_architecture']
$descArchitecture = $Catalog['desc_architecture']
$sectionFeatures = $Catalog['section_features']
$tableFeature = $Catalog['table_feature']
$tableSpec = $Catalog['table_spec']
$tableDesign = $Catalog['table_design']
$tableTasks = $Catalog['table_tasks']
$sectionArchitecture = $Catalog['section_architecture']
$indexArchitectureBody = $Catalog['index_architecture_body']
$sectionGettingStarted = $Catalog['section_getting_started']
$indexGettingStartedBody = $Catalog['index_getting_started_body']
$sectionDevelopment = $Catalog['section_development']
$indexDevelopmentBody = $Catalog['index_development_body']
$generatedBy = $Catalog['generated_by']

# D-16 #1: feature base dirs are every positional after slot 2 — output_lang
# now occupies slot 2, so the lower bound moved from 2 to 3. The upper bound
# is the last VALID index ($args.Count - 1), not the count itself: the old
# `$args[2..$args.Count]` indexed one past the end of the array.
$FeatureBaseDirs = @()
if ($args.Count -gt 3) {
  $FeatureBaseDirs = $args[3..($args.Count - 1)]
}

# Expand base dirs to subdirectories
$FeatureDirs = @()
foreach ($base in $FeatureBaseDirs) {
  if (Test-Path $base) {
    Get-ChildItem $base -Directory | ForEach-Object { $FeatureDirs += $_.FullName }
  }
}

$output = "docs/index.md"
New-Item -ItemType Directory -Path "docs" -Force | Out-Null

$content = @"
# $ProjectName $siteNameSuffix

> $indexTagline

"@

$hasProject = (Test-Path "specs/project/PROJECT.md") -or (Test-Path "specs/project/ROADMAP.md")

if ($hasProject) {
  $content += @"

## $sectionOverview

| $tableSection | $tableDescription |
|---------|-------------|
| [$labelProjectOverview](specs/project/PROJECT.md) | $descProjectOverview |
| [$labelRoadmap](specs/project/ROADMAP.md) | $descRoadmap |
| [$labelArchitecture](specs/codebase/ARCHITECTURE.md) | $descArchitecture |

"@
}

if ($FeatureDirs.Count -gt 0) {
  $content += @"

## $sectionFeatures

| $tableFeature | $tableSpec | $tableDesign | $tableTasks |
|---------|------|--------|-------|
"@
  # D-16 #2: derive a path relative to the site's docs dir instead of
  # `Split-Path -NoQualifier`, which returns the WHOLE absolute path on
  # Unix ("qualifier" means the Windows drive letter there) — that leaked
  # the host's filesystem path into a published document (T-04-03).
  $cwd = (Get-Location).ProviderPath
  foreach ($dir in $FeatureDirs) {
    $name = (Split-Path $dir -Leaf) -replace '-', ' '

    $relDir = $null
    try {
      $relDir = Resolve-Path -Relative -Path $dir -ErrorAction Stop
    } catch {
      $relDir = $dir
    }
    if ($relDir.StartsWith($cwd)) {
      $relDir = $relDir.Substring($cwd.Length)
    }
    $relDir = $relDir -replace '\\', '/'
    $relDir = $relDir -replace '^\./', ''
    $relDir = $relDir -replace '^/', ''
    $relDir = $relDir -replace '^docs/', ''
    $relDir = $relDir.TrimEnd('/') + '/'

    $spec = "${relDir}spec.md"
    $design = "${relDir}design.md"
    $tasks = "${relDir}tasks.md"
    $content += "`n| $name | [$name]($spec) | [$name]($design) | [$name]($tasks) |"
  }
}

if (Test-Path "specs/codebase/ARCHITECTURE.md") {
  $content += @"

## $sectionArchitecture

$indexArchitectureBody

"@
}

$developmentBlock = ""
if ($Audience -eq "developer") {
  $developmentBlock = @"

## $sectionDevelopment

$indexDevelopmentBody
"@
}

$content += @"

## $sectionGettingStarted

$indexGettingStartedBody
$developmentBlock

---

"@

$today = Get-Date -Format yyyy-MM-dd
$generatedByLine = $generatedBy.Replace('%s', $today)
$content += "*$generatedByLine*"

# Single writer for all generated output (D-15) — never a redirection
# cmdlet that adds a BOM on Windows PowerShell 5.1.
Write-Utf8NoBom -Path $output -Content $content

# Console stays in English: the console is not published output, per
# CONTEXT.md's language policy.
Write-Output "Generated $output"
