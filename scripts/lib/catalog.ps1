# scripts/lib/catalog.ps1 — dot-sourced by the .ps1 companion twins.
# Single source of the catalog parser, the output_lang allowlist gate, the
# catalog path resolution, the fail-closed key assertion and the BOM-less
# writer (D-18). PowerShell has no equivalent of bash's `set -a; . file`
# sourcing, so this parser is real code shared by every twin — never copy
# these functions into a twin script.

function Resolve-OutputLang {
  param([Parameter(Mandatory = $true)][string]$Value)
  $lang = $Value.ToLowerInvariant()
  if ($lang -ne 'en' -and $lang -ne 'pt-br') {
    Write-Output "ERROR: unsupported output_lang '$lang' — supported: en, pt-br"
    exit 1
  }
  return $lang
}

function Get-CatalogPath {
  param(
    [Parameter(Mandatory = $true)][string]$ScriptRoot,
    [Parameter(Mandatory = $true)][string]$OutputLang
  )
  $catalogPath = Join-Path $ScriptRoot "../templates/lang/$OutputLang.lang"
  if (-not (Test-Path -LiteralPath $catalogPath)) {
    Write-Output "ERROR: catalog not found for output_lang '$OutputLang': $catalogPath"
    exit 1
  }
  return $catalogPath
}

function Get-Catalog {
  param([Parameter(Mandatory = $true)][string]$CatalogPath)
  # -Encoding UTF8 is pinned on purpose: without it, Windows PowerShell 5.1
  # assumes ANSI for a BOM-less file and the pt-br catalog's accented values
  # turn into mojibake.
  $catalog = @{}
  foreach ($line in Get-Content -LiteralPath $CatalogPath -Encoding UTF8) {
    if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }

    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { continue }

    $key = $line.Substring(0, $eq)
    if ($key -notmatch '^[a-z][a-z0-9_]*$') { continue }

    $rest = $line.Substring($eq + 1)
    if ($rest.Length -lt 2 -or $rest[0] -ne "'") { continue }

    $sb = New-Object System.Text.StringBuilder
    $closed = $false
    $i = 1
    while ($i -lt $rest.Length) {
      $ch = $rest[$i]
      if ($ch -eq "'") {
        # Bash's close-quote/escaped-quote/reopen-quote idiom ('\'') embeds a
        # literal apostrophe (e.g. "DokuWiki's"). Detected by CHARACTER
        # COMPARISON, never Substring, to avoid boundary arithmetic. Any
        # other quote is the real closing quote — the rest of the line
        # (a trailing comment, e.g. pt-br.lang's pdf_toc_title) is discarded.
        if (($i + 3) -lt $rest.Length -and $rest[$i + 1] -eq '\' -and $rest[$i + 2] -eq "'" -and $rest[$i + 3] -eq "'") {
          [void]$sb.Append("'")
          $i += 4
          continue
        } else {
          $closed = $true
          break
        }
      }
      [void]$sb.Append($ch)
      $i += 1
    }

    # A value that never closes is not recorded — the missing key is what
    # makes Assert-CatalogKey halt naming it, instead of a silent empty label.
    if (-not $closed) { continue }

    $catalog[$key] = $sb.ToString()
  }
  return $catalog
}

function Assert-CatalogKey {
  param(
    [Parameter(Mandatory = $true)][hashtable]$Catalog,
    [Parameter(Mandatory = $true)][string[]]$Keys
  )
  foreach ($key in $Keys) {
    if (-not $Catalog.ContainsKey($key)) {
      Write-Output "ERROR: key $key not found in catalog"
      exit 1
    }
  }
}

function Write-Utf8NoBom {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Content
  )
  # The .NET API resolves a relative path against the PROCESS working
  # directory, which does not track Set-Location in PowerShell — resolve to
  # an absolute path first, from the provider's own notion of "here".
  $resolvedPath = $Path
  if (-not [System.IO.Path]::IsPathRooted($resolvedPath)) {
    $cwd = (Get-Location).ProviderPath
    $resolvedPath = [System.IO.Path]::GetFullPath((Join-Path $cwd $resolvedPath))
  }

  $parent = Split-Path -Path $resolvedPath -Parent
  if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  $noBomEncoding = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText($resolvedPath, $Content, $noBomEncoding)
}

function Expand-CatalogEscapes {
  param([Parameter(Mandatory = $true)][string]$Value)
  # Counterpart of the `printf '%b'` the .sh twin applies to
  # dokuwiki_readme_steps — call this ONLY where that twin applies `%b`,
  # never on any other catalog value.
  return $Value.Replace('\n', "`n")
}
