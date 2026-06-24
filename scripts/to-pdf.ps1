param(
  [string]$Output,
  [string[]]$Files
)

if (-not $Output -or $Files.Count -eq 0) {
  Write-Output "Usage: to-pdf.ps1 <output.pdf> <file1.md> [file2.md ...]"
  exit 1
}

$buildDir = Split-Path $Output -Parent
if (-not $buildDir) { $buildDir = "." }
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# Build ordered markdown
$book = "$buildDir/specs-book.md"
$date = Get-Date -Format "yyyy-MM-dd"
$content = @"
# Specifications

*Generated on $date*

\newpage

"@

foreach ($f in $Files) {
  if (-not (Test-Path $f)) { continue }
  $content += Get-Content $f -Raw
  $content += "`n`n\newpage`n`n"
}

$content | Out-File -FilePath $book -Encoding utf8

# Try weasyprint first, then wkhtmltopdf
$found = $false

try {
  $pandoc = Get-Command "pandoc" -ErrorAction Stop
  $weasyprint = Get-Command "weasyprint" -ErrorAction SilentlyContinue

  if ($weasyprint) {
    & $pandoc $book -f markdown --pdf-engine=weasyprint `
      -o $Output --metadata title="Specifications" `
      --toc --toc-depth=3 2>&1
    Write-Output "PDF generated via weasyprint: $Output"
    $found = $true
  } else {
    $wkhtmltopdf = Get-Command "wkhtmltopdf" -ErrorAction SilentlyContinue
    if ($wkhtmltopdf) {
      & $pandoc $book -f markdown --pdf-engine=wkhtmltopdf `
        -o $Output --metadata title="Specifications" `
        --toc --toc-depth=3 2>&1
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
