param(
  [string[]]$Refs = @("HEAD", "origin/master", "origin/main", "github/master", "github/main"),
  [string[]]$AllowedGitHubLogins = @("lllg123"),
  [string]$GitHubRepo = "lllg123/MoonTrustFlow-MoonBit",
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

function Test-GhExists {
  return $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
}

function Get-GitHubContributorLogins {
  param([string]$Repo)
  if (-not (Test-GhExists)) {
    Write-Host "[skip] gh is not available; skipping GitHub contributor API audit"
    return @()
  }

  $raw = gh api "repos/$Repo/contributors" --paginate --jq ".[].login" 2>$null
  if (-not $raw) {
    Write-Host "[skip] unable to query GitHub contributors for $Repo"
    return @()
  }

  ($raw -split "`r?`n" | Where-Object { $_ -and $_.Trim() -ne "" } | Sort-Object -Unique)
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

$unexpectedGitHubLogins = @()
$contributorLogins = Get-GitHubContributorLogins -Repo $GitHubRepo
if ($contributorLogins.Count -gt 0) {
  Write-Host "[github contributors api]"
  foreach ($login in $contributorLogins) {
    $tag = if ($AllowedGitHubLogins -contains $login) { "known" } else { "unexpected" }
    Write-Host "  - $login [$tag]"
    if ($tag -eq "unexpected") {
      $foundUnexpected = $true
      $unexpectedGitHubLogins += $login
    }
  }
}

if ($FailOnUnexpected -and $foundUnexpected) {
  $detail = if ($unexpectedGitHubLogins.Count -gt 0) {
    " Unexpected GitHub logins: " + ($unexpectedGitHubLogins -join ", ")
  } else {
    ""
  }
  throw "Unexpected contributor identities were found.$detail"
}
