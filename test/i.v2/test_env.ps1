# test_env.ps1 - Environment profile tests (E1-E4)

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$testDir\TestHelper.ps1"

Reset-TestCounters

Write-Host "Env Profile Tests" -ForegroundColor Yellow
Write-Host "=================" -ForegroundColor Yellow
Write-Host ""

$iScript = Join-Path (Get-ScriptPath) "i.ps1"
$appDir = Get-FixturePath "root\app"
$rootDir = Get-FixturePath "root"

# E1: Set default (i set env loads env.default)
Write-Host "E1: Set default profile" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "Set-Location '$appDir'; & '$iScript' set env; Write-Host CHECK_VAR=`$env:APP_DEFAULT" 2>&1 | Out-String
$passed = $output -match "CHECK_VAR=app_default_value"
Write-TestResult "E1" "i set env loads env.default" $passed "Output: $output"

# E2: Set named profile
Write-Host "`nE2: Set named profile" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "Set-Location '$appDir'; & '$iScript' set env dev; Write-Host CHECK_VAR=`$env:DEV_MODE" 2>&1 | Out-String
$passed = $output -match "CHECK_VAR=true"
Write-TestResult "E2" "i set env dev loads env.dev" $passed "Output: $output"

# E3: Profile not found
Write-Host "`nE3: Profile not found" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("set", "env", "nonexistent_profile")
$passed = $output -match "not found" -or $output -match "No.*profile"
Write-TestResult "E3" "Shows error for missing profile" $passed "Output: $output"

# E4: Merged profiles from parent
Write-Host "`nE4: Merged profiles from parent" -ForegroundColor Cyan
# From app dir, should be able to use root_profile from parent
$output = & powershell -NoProfile -Command "Set-Location '$appDir'; & '$iScript' set env root_profile; Write-Host CHECK_VAR=`$env:ROOT_PROFILE_VAR" 2>&1 | Out-String
$passed = $output -match "CHECK_VAR=root_profile_value"
Write-TestResult "E4" "Can use env profile from parent config" $passed "Output: $output"

Write-TestSummary "Env Profile Tests"
