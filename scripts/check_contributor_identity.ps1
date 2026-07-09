param(
  [string[]]$Refs = @("HEAD", "origin/master", "origin/main", "github/master", "github/main"),
  [switch]$FailOnUnexpected
)

$ErrorActionPreference = "Stop"

function Test-GitRefExists {
  param([string]$Ref)
  git rev-parse --verify --quiet $Ref 2>$null 1>$null
  return $LASTEXITCODE -eq 0
}

function Get-RefIdentities {
  param([string]$Ref)
  git log --format="%an <%ae>" $Ref | Sort-Object -Unique
}

$known = @(
  "llgllg <1357801557@qq.com>",
  "lllglllg <1357801557@qq.com>",
  "lllg123 <1357801557@qq.com>",
  "lllgllg <1357801557@qq.com>",
  "lllglllg <lllglllg@example.org>"
)

$foundUnexpected = $false

foreach ($ref in $Refs) {
  if (-not (Test-GitRefExists $ref)) {
    Write-Host "[skip] $ref does not exist"
    continue
  }

  $identities = Get-RefIdentities $ref
  Write-Host "[$ref]"
  foreach ($identity in $identities) {
    $tag = if ($known -contains $identity) { "known" } else { "unexpected" }
    Write-Host "  - $identity [$tag]"
    if ($tag -eq "unexpected") {
      $foundUnexpected = $true
    }
  }
}

if ($FailOnUnexpected -and $foundUnexpected) {
  throw "Unexpected contributor identities were found."
}
