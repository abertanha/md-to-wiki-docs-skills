# to-dokuwiki.ps1 — Convert markdown files to DokuWiki syntax
# Usage: to-dokuwiki.ps1 <output_dir> <output_lang> <file1.md> [file2.md ...]

# Dot-source BEFORE anything else — the loader is the single source of the
# parser, the allowlist gate and the BOM-less writer (D-18).
. (Join-Path $PSScriptRoot 'lib/catalog.ps1')

$OutputDir = $args[0]
$OutputLangRaw = $args[1]

# D-16-class fix: the tail bound is the last VALID index ($args.Count - 1),
# not the count itself — the prior slice indexed one past the end of the
# array, producing a trailing null.
$Files = @()
if ($args.Count -gt 2) {
  $Files = $args[2..($args.Count - 1)]
}

if (-not $OutputDir -or -not $OutputLangRaw -or $Files.Count -eq 0) {
  Write-Output "Usage: to-dokuwiki.ps1 <output_dir> <output_lang> <file1.md> [file2.md ...] — output_lang required, supported: en, pt-br"
  exit 1
}

# Order is the security control (T-04-01): the allowlist gate runs BEFORE
# any path is built from the value, so a hostile output_lang never reaches
# the catalog path resolver below.
$OutputLang = Resolve-OutputLang -Value $OutputLangRaw
$CatalogPath = Get-CatalogPath -ScriptRoot $PSScriptRoot -OutputLang $OutputLang
$Catalog = Get-Catalog -CatalogPath $CatalogPath

# Bootstrap runs BEFORE the pandoc availability guard below (CHROME-03,
# T-03-08): on a host without pandoc, a missing key must halt NAMING THE
# KEY, never get masked by the "pandoc not found" error.
$RequiredKeys = @('dokuwiki_readme_heading', 'dokuwiki_readme_steps', 'dokuwiki_readme_footer')
Assert-CatalogKey -Catalog $Catalog -Keys $RequiredKeys

$dokuwikiReadmeHeading = $Catalog['dokuwiki_readme_heading']
$dokuwikiReadmeFooter = $Catalog['dokuwiki_readme_footer']

$pagesDir = "$OutputDir/data/pages"
New-Item -ItemType Directory -Path $pagesDir -Force | Out-Null

$pandoc = Get-Command "pandoc" -ErrorAction SilentlyContinue
if (-not $pandoc) {
  Write-Output "ERROR: pandoc not found. Install it: winget install pandoc"
  exit 1
}

foreach ($file in $Files) {
  if (-not (Test-Path $file)) {
    Write-Output "WARNING: $file not found, skipping"
    continue
  }

  # DokuWiki page-id path conversion is STRUCTURE, never translated in any
  # language (CHROME-04) — do not touch this block.
  $relative = $file -replace '^\.specs[\\/]', '' -replace '\.md$', ''
  $pageId = $relative -replace '[/\\]', ':'
  $pagePath = "$pagesDir/$pageId.txt"

  # [System.IO.Path]::GetDirectoryName, not Split-Path -Parent: the page-id
  # separator IS ':' (CHROME-04), and Split-Path mis-parses a relative path
  # whose last segment contains ':' as a provider-qualified drive, returning
  # an empty parent and failing New-Item. GetDirectoryName does plain string
  # splitting on the path separator, with no drive semantics, mirroring the
  # .sh twin's `dirname` (to-dokuwiki.sh:57).
  $parent = [System.IO.Path]::GetDirectoryName($pagePath)
  New-Item -ItemType Directory -Path $parent -Force | Out-Null

  pandoc "$file" -f markdown -t dokuwiki -o "$pagePath"
  Write-Output "Converted $file -> $pagePath"
}

# Apply the %b-style escape expansion (the .sh twin's `printf '%b'`
# counterpart) to this one value only — any other value would be a
# behavior change, not a mirror of the .sh twin.
$stepsBlock = Expand-CatalogEscapes -Value $Catalog['dokuwiki_readme_steps']

$readme = @"
# $dokuwikiReadmeHeading

$stepsBlock

$dokuwikiReadmeFooter
"@

Write-Utf8NoBom -Path "$OutputDir/README.md" -Content $readme

Write-Output "Done. Import $OutputDir/data/ into your DokuWiki data/ directory."
