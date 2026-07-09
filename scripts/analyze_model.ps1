param(
  [Parameter(Mandatory = $true)]
  [string]$Path,
  [switch]$Json
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$resolvedPath = (Resolve-Path -LiteralPath $Path).Path
$modelText = Get-Content -LiteralPath $resolvedPath -Raw -Encoding UTF8

$oldModel = $env:MOONTRUSTFLOW_MODEL_TEXT
$oldSource = $env:MOONTRUSTFLOW_SOURCE_LABEL

try {
  $env:MOONTRUSTFLOW_MODEL_TEXT = $modelText
  $env:MOONTRUSTFLOW_SOURCE_LABEL = $resolvedPath

  if ($Json) {
    moon -C $repoRoot run cmd/main -- --json
  } else {
    moon -C $repoRoot run cmd/main
  }
}
finally {
  if ($null -ne $oldModel) {
    $env:MOONTRUSTFLOW_MODEL_TEXT = $oldModel
  } else {
    Remove-Item Env:MOONTRUSTFLOW_MODEL_TEXT -ErrorAction SilentlyContinue
  }
  if ($null -ne $oldSource) {
    $env:MOONTRUSTFLOW_SOURCE_LABEL = $oldSource
  } else {
    Remove-Item Env:MOONTRUSTFLOW_SOURCE_LABEL -ErrorAction SilentlyContinue
  }
}

