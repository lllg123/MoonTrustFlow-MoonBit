param(
  [switch]$SkipMooncakes,
  [switch]$SkipRemote
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Invoke-Step {
  param(
    [string]$Name,
    [scriptblock]$Action
  )
  Write-Host "`n==> $Name" -ForegroundColor Cyan
  & $Action
}

function Test-CommandExists {
  param([string[]]$Names)
  foreach ($name in $Names) {
    if (Get-Command $name -ErrorAction SilentlyContinue) {
      return $true
    }
  }
  return $false
}

function Get-TrackedMoonBitLineCount {
  $files = rg --files -g "*.mbt" -g "*.mbti" -g "!_build/**" -g "!.mooncakes/**"
  if (-not $files) {
    return 0
  }
  return ($files | ForEach-Object {
    (Get-Content -LiteralPath $_ -Encoding UTF8).Count
  } | Measure-Object -Sum).Sum
}

function Get-WorkingTreeSignature {
  git status --porcelain=v1
}

Invoke-Step "Toolchain" {
  moon version --all
  moon update
}

Invoke-Step "Static checks" {
  moon check --target all --deny-warn
}

Invoke-Step "Tests" {
  moon test --deny-warn
  if (Test-CommandExists @("cl", "gcc", "clang", "cc")) {
    moon test --target all --deny-warn
  } else {
    Write-Warning "No system C compiler found. Skipping local native target test; CI must cover moon test --target all."
  }
}

Invoke-Step "Formatter cleanliness" {
  $before = Get-WorkingTreeSignature
  moon fmt
  $after = Get-WorkingTreeSignature
  if (($before -join "`n") -ne ($after -join "`n")) {
    throw "moon fmt changed the working tree."
  }
}

Invoke-Step "Public API cleanliness" {
  $before = Get-WorkingTreeSignature
  moon info
  $after = Get-WorkingTreeSignature
  if (($before -join "`n") -ne ($after -join "`n")) {
    throw "moon info changed the working tree."
  }
}

Invoke-Step "CLI sample" {
  moon run cmd/main
}

Invoke-Step "Real .mtf fixture via wrapper" {
  powershell -ExecutionPolicy Bypass -File scripts\analyze_model.ps1 -Path fixtures\models\webapp_taint.mtf -Json
}

Invoke-Step "Representative fixture corpus" {
  python scripts\verify_fixture_corpus.py
}

Invoke-Step "Call-graph adapter smoke test" {
  $outDir = Join-Path $repoRoot "_build\acceptance"
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  $outPath = Join-Path $outDir "service_callgraph_imported.mtf"
  python scripts\import_callgraph.py fixtures\adapters\service_callgraph.json -o $outPath
  python scripts\analyze_model.py $outPath --json
}

Invoke-Step "Performance smoke test" {
  python scripts\benchmark_analysis.py --hops 64
}

Invoke-Step "Required files" {
  $required = @(
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    "NOTICE",
    "CONTRIBUTING.md",
    ".github/workflows/ci.yml",
    "docs/competition/acceptance-checklist.md",
    "docs/competition/completion-report.md",
    "docs/competition/source-attribution.md",
    "scripts/analyze_model.ps1",
    "scripts/analyze_model.py",
    "scripts/import_callgraph.py",
    "scripts/benchmark_analysis.py",
    "scripts/verify_fixture_corpus.py",
    "fixtures/benchmarks/manifest.json",
    "docs/competition/benchmark-corpus.md",
    "scripts/check_contributor_identity.ps1"
  )
  foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path)) {
      throw "Missing required file: $path"
    }
  }
}

Invoke-Step "Tracked README mode" {
  $modeLine = git ls-files -s README.md
  if (-not $modeLine.StartsWith("100644")) {
    throw "README.md is not a normal tracked file: $modeLine"
  }
  $modeLine
}

Invoke-Step "Contributor identities" {
  powershell -ExecutionPolicy Bypass -File scripts\check_contributor_identity.ps1 -FailOnUnexpected
}

Invoke-Step "MoonBit source scale" {
  $lineCount = Get-TrackedMoonBitLineCount
  Write-Host "Tracked .mbt/.mbti lines: $lineCount"
}

if (-not $SkipRemote) {
  Invoke-Step "Remote HEAD checks" {
    $remotes = @(git remote)
    foreach ($remote in @("origin", "github", "gitlink")) {
      if ($remotes -contains $remote) {
        Write-Host "[$remote]"
        git ls-remote --symref $remote HEAD
      } else {
        Write-Host "[skip] remote '$remote' is not configured"
      }
    }
  }
}

if (-not $SkipMooncakes) {
  Invoke-Step "Mooncakes visibility" {
    Invoke-RestMethod -Uri "https://mooncakes.io/api/v0/modules/llgllg/moontrustflow" | ConvertTo-Json -Depth 4
  }
}

Invoke-Step "Commit history summary" {
  git rev-list --count --all
  git shortlog -sne --all
}
