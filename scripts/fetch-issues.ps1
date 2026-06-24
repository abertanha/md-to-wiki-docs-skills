# fetch-issues.ps1 — Fetch GitHub issues/PRs with gh (preferred) or Invoke-RestMethod (fallback)
$OwnerRepo = $args[0]
$Numbers = $args[1..$args.Count] | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }

if (-not $OwnerRepo -or $Numbers.Count -eq 0) {
  Write-Output "Usage: fetch-issues.ps1 <owner/repo> <number> [number...]"
  exit 1
}

$owner, $repo = $OwnerRepo -split '/'
$cacheDir = ".specs/issues/cache"
New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null

$summary = @()

foreach ($num in $Numbers) {
  $cacheFile = "$cacheDir/$num.json"

  if (Test-Path $cacheFile) {
    $title = (Get-Content $cacheFile -Raw | ConvertFrom-Json).title
    $summary += "CACHED|$num|$title"
    continue
  }

  # Try gh
  $ghAvailable = Get-Command "gh" -ErrorAction SilentlyContinue
  if ($ghAvailable) {
    $found = $false
    foreach ($type in @("issue", "pr")) {
      $data = gh "$type" view $num --repo "$OwnerRepo" `
        --json number,title,body,state,url,labels,createdAt,closedAt,mergedAt,comments 2>$null
      if ($data -and $data -ne "null") {
        $data | Out-File -FilePath $cacheFile -Encoding utf8
        $parsed = $data | ConvertFrom-Json
        $summary += "GH|$num|$($parsed.title)"
        $found = $true
        break
      }
    }
    if ($found) { continue }
  }

  # Fallback: Invoke-RestMethod
  try {
    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$OwnerRepo/issues/$num" `
      -Method Get -ErrorAction Stop
    $response | ConvertTo-Json -Depth 10 | Out-File -FilePath $cacheFile -Encoding utf8
    $summary += "CURL|$num|$($response.title)"
    continue
  } catch {
    if ($_.Exception.Response.StatusCode -eq 401 -or $_.Exception.Response.StatusCode -eq 403 -or $_.Exception.Response.StatusCode -eq 404) {
      $summary += "AUTH_NEEDED|$num|"
      continue
    }
    $summary += "NOT_FOUND|$num|"
    continue
  }
}

Write-Output "---SUMMARY---"
$summary | Where-Object { $_ }
