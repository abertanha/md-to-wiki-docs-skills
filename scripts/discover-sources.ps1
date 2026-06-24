param(
  [string]$Dir = ".specs",
  [string]$Format = "summary"
)

if (-not (Test-Path $Dir)) {
  Write-Output "ERROR: Directory not found: $Dir"
  exit 1
}

$projectFiles = @(Get-ChildItem "$Dir/project/*.md" -ErrorAction SilentlyContinue | Sort-Object Name)
$codebaseFiles = @(Get-ChildItem "$Dir/codebase/*.md" -ErrorAction SilentlyContinue | Sort-Object Name)
$featureDirs = @(Get-ChildItem "$Dir/features" -Directory -ErrorAction SilentlyContinue | Sort-Object Name)
$quickDirs = @(Get-ChildItem "$Dir/quick" -Directory -ErrorAction SilentlyContinue | Sort-Object Name)

switch ($Format) {
  "files" {
    $projectFiles | ForEach-Object { $_.FullName }
    $codebaseFiles | ForEach-Object { $_.FullName }
    foreach ($fd in $featureDirs) {
      Get-ChildItem "$($fd.FullName)/*.md" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    }
    foreach ($qd in $quickDirs) {
      Get-ChildItem "$($qd.FullName)/*.md" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
    }
  }
  "json" {
    $first = $true
    Write-Output "{"
    Write-Output '  "project": ['
    foreach ($f in $projectFiles) {
      if (-not $first) { Write-Output "," }
      $first = $false
      Write-Output "    `"$($f.FullName)`""
    }
    Write-Output "  ],"
    Write-Output '  "codebase": ['
    $first = $true
    foreach ($f in $codebaseFiles) {
      if (-not $first) { Write-Output "," }
      $first = $false
      Write-Output "    `"$($f.FullName)`""
    }
    Write-Output "  ],"
    Write-Output '  "features": ['
    $first = $true
    foreach ($fd in $featureDirs) {
      if (-not $first) { Write-Output "," }
      $first = $false
      $name = $fd.Name
      $files = @(Get-ChildItem "$($fd.FullName)/*.md" -ErrorAction SilentlyContinue | Sort-Object Name)
      Write-Output "    { `"name`": `"$name`", `"files`": ["
      $innerFirst = $true
      foreach ($f in $files) {
        if (-not $innerFirst) { Write-Output "," }
        $innerFirst = $false
        Write-Output "      `"$($f.FullName)`""
      }
      Write-Output "    ] }"
    }
    Write-Output "  ],"
    Write-Output '  "quick": ['
    $first = $true
    foreach ($qd in $quickDirs) {
      if (-not $first) { Write-Output "," }
      $first = $false
      $name = $qd.Name
      $files = @(Get-ChildItem "$($qd.FullName)/*.md" -ErrorAction SilentlyContinue | Sort-Object Name)
      Write-Output "    { `"name`": `"$name`", `"files`": ["
      $innerFirst = $true
      foreach ($f in $files) {
        if (-not $innerFirst) { Write-Output "," }
        $innerFirst = $false
        Write-Output "      `"$($f.FullName)`""
      }
      Write-Output "    ] }"
    }
    Write-Output "  ]"
    Write-Output "}"
  }
  default {
    $projectCount = $projectFiles.Count
    $codebaseCount = $codebaseFiles.Count
    $featureCount = $featureDirs.Count
    $quickCount = $quickDirs.Count
    $totalFiles = $projectCount + $codebaseCount
    foreach ($fd in $featureDirs) {
      $totalFiles += @(Get-ChildItem "$($fd.FullName)/*.md" -ErrorAction SilentlyContinue).Count
    }
    foreach ($qd in $quickDirs) {
      $totalFiles += @(Get-ChildItem "$($qd.FullName)/*.md" -ErrorAction SilentlyContinue).Count
    }

    Write-Output "Discovered in $Dir/"
    Write-Output "  Project  → $projectCount file(s)"
    Write-Output "  Codebase → $codebaseCount file(s)"
    Write-Output "  Features → $featureCount feature(s)"
    Write-Output "  Quick    → $quickCount task(s)"
    Write-Output "  Total    → $totalFiles markdown file(s)"
    Write-Output ""
    Write-Output "Feature list:"
    foreach ($fd in $featureDirs) {
      $count = @(Get-ChildItem "$($fd.FullName)/*.md" -ErrorAction SilentlyContinue).Count
      Write-Output "    • $($fd.Name) ($count file(s))"
    }
  }
}
