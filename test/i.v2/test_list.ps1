# test_list.ps1 - List command tests (L1-L2)

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$testDir\TestHelper.ps1"

Reset-TestCounters

Write-Host "List Tests" -ForegroundColor Yellow
Write-Host "==========" -ForegroundColor Yellow
Write-Host ""

$appDir = Get-FixturePath "root\app"

# L1: List commands shows merged commands
Write-Host "L1: List commands (merged)" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("list", "cmd")
# Should see: build (from app), test (from app), root_only (from root)
$passed = $output -match "build" -and $output -match "test" -and $output -match "root_only"
Write-TestResult "L1" "Shows merged commands from all configs" $passed "Output: $output"

# L2: List env shows merged profiles
Write-Host "`nL2: List env (merged)" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("list", "env")
# Should see: default, dev, extra (from app), root_profile (from root)
$passed = $output -match "default" -and $output -match "dev" -and $output -match "root_profile"
Write-TestResult "L2" "Shows merged env profiles from all configs" $passed "Output: $output"

Write-TestSummary "List Tests"
