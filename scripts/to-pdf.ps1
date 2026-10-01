# to-pdf.ps1 — Generate PDF from selected markdown files
# Usage: to-pdf.ps1 <output.pdf> <output_lang> <file1.md> [file2.md ...]
#
# `ValueFromRemainingArguments` is REQUIRED on $Files: a simple (non-bound)
# positional array parameter in PowerShell does NOT slurp trailing args the
# way every other twin's `$args[N..]` slice does — without this attribute,
# `$Files` silently binds ONLY THE FIRST file and every remaining path
# spills into the unused `$args` array with no error, so `to-pdf.ps1`
# quietly produced a one-file book for every multi-file invocation. This
# was flagged as the lowest-confidence claim in the phase research and
# turned out to be backwards; confirmed empirically via tests/ps1-contract.sh's
# pwsh_accented_dir_survives leg during plan 04-04.
param(
  [string]$Output,
  [string]$OutputLangRaw,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Files
)

# Dot-source BEFORE anything else — the loader is the single source of the
# parser, the allowlist gate and the BOM-less writer (D-18).
. (Join-Path $PSScriptRoot 'lib/catalog.ps1')

if (-not $Output -or -not $OutputLangRaw -or $Files.Count -eq 0) {
  Write-Output "Usage: to-pdf.ps1 <output.pdf> <output_lang> <file1.md> [file2.md ...] — output_lang required, supported: en, pt-br"
  exit 1
}

# Order is the security control (T-04-01): the allowlist gate runs BEFORE
# any path is built from the value, so a hostile output_lang never reaches
# the catalog path resolver below.
$OutputLang = Resolve-OutputLang -Value $OutputLangRaw
$CatalogPath = Get-CatalogPath -ScriptRoot $PSScriptRoot -OutputLang $OutputLang
$Catalog = Get-Catalog -CatalogPath $CatalogPath

# Bootstrap up front, before any byte of output is written. pdf_toc_title
# is declared only in the pt-br branch below: it has no `en` counterpart by
# design (D-06) — declaring it unconditionally would halt the `en` branch.
$RequiredKeys = @('pdf_title', 'pdf_generated_on')
Assert-CatalogKey -Catalog $Catalog -Keys $RequiredKeys

$pdfTitle = $Catalog['pdf_title']
$pdfGeneratedOn = $Catalog['pdf_generated_on']

# PandocLangOpts: empty on en (no flags — behavior preserved, D-06); on
# pt-br, project the locale into the pandoc consumer (D-13/QUAL-01). Each
# flag/value pair is TWO array elements, never one with an embedded space —
# a single element would collapse into one argument and pandoc would
# reject it.
switch ($OutputLang) {
  'pt-br' {
    Assert-CatalogKey -Catalog $Catalog -Keys @('pdf_toc_title')
    $pdfTocTitle = $Catalog['pdf_toc_title']
    $PandocLangOpts = @('-M', 'lang=pt-BR', '-M', "toc-title=$pdfTocTitle")
  }
  default {
    $PandocLangOpts = @()
  }
}

$buildDir = Split-Path $Output -Parent
if (-not $buildDir) { $buildDir = "." }
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# Build ordered markdown
$book = "$buildDir/specs-book.md"
$date = Get-Date -Format "yyyy-MM-dd"
$generatedOnLine = $pdfGeneratedOn.Replace('%s', $date)
# The pandoc newpage literal (backslash + "newpage") is NOT a PowerShell
# escape (the escape character here is the backtick), so it survives
# unmodified inside this double-quoted here-string.
$content = @"
# $pdfTitle

*$generatedOnLine*

\newpage

"@

foreach ($f in $Files) {
  if (-not (Test-Path $f)) { Write-Output "WARNING: $f not found, skipping"; continue }
  $content += Get-Content $f -Raw
  $content += "`n`n\newpage`n`n"
}

# Single writer for the book (D-15). The book also doubles as this twin's
# golden for the PDF surface — to-pdf.ps1 has no markdown fallback for the
# publishable PDF, a pre-existing exception already registered in
# tests/fixtures/manifest.md.
Write-Utf8NoBom -Path $book -Content $content

# Try weasyprint first, then wkhtmltopdf
$found = $false

try {
  $pandoc = Get-Command "pandoc" -ErrorAction Stop
  $weasyprint = Get-Command "weasyprint" -ErrorAction SilentlyContinue

  if ($weasyprint) {
    & $pandoc $book -f markdown --pdf-engine=weasyprint `
      -o $Output --metadata "title=$pdfTitle" `
      --toc --toc-depth=3 @PandocLangOpts 2>&1
    if ($LASTEXITCODE -ne 0) {
      Write-Error "pandoc (weasyprint) failed with exit code $LASTEXITCODE" 2>&1
      exit 1
    }
    Write-Output "PDF generated via weasyprint: $Output"
    $found = $true
  } else {
    $wkhtmltopdf = Get-Command "wkhtmltopdf" -ErrorAction SilentlyContinue
    if ($wkhtmltopdf) {
      & $pandoc $book -f markdown --pdf-engine=wkhtmltopdf `
        -o $Output --metadata "title=$pdfTitle" `
        --toc --toc-depth=3 @PandocLangOpts 2>&1
      if ($LASTEXITCODE -ne 0) {
        Write-Error "pandoc (wkhtmltopdf) failed with exit code $LASTEXITCODE" 2>&1
        exit 1
      }
      Write-Output "PDF generated via wkhtmltopdf: $Output"
      $found = $true
    }
  }
} catch {}

if (-not $found) {
  Write-Output "ERROR: Neither weasyprint nor wkhtmltopdf found."
  Write-Output "Install one: pip install weasyprint  or  choco install wkhtmltopdf"
  exit 1
}
