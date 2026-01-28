# test_env.ps1 - Tests for environment functionality

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent (Split-Path -Parent $testDir)
$iScript = Join-Path $scriptDir "i.ps1"

. "$testDir\TestHelper.ps1"

$script:TestsPassed = 0
$script:TestsFailed = 0

Write-Host "Running: i env tests" -ForegroundColor Yellow
Write-Host "Test dir: $testDir" -ForegroundColor Gray
Write-Host ""

$originalDir = Get-Location
Set-Location $testDir

try {
    # Test 1: List env configs
    Write-Host "Test 1: List env configs" -ForegroundColor Cyan
    $output = & powershell -NoProfile -File $iScript list env 2>&1 | Out-String
    $test1 = $output -match "env.*default" -and $output -match "env 1" -and $output -match "env 2"
    Write-TestResult "Lists env configs" $test1 "Output: $output"

    # Test 2: Set default env (temp_env)
    Write-Host "`nTest 2: Set default env" -ForegroundColor Cyan
    $output = & powershell -NoProfile -Command "Set-Location '$testDir'; & '$iScript' set env; Write-Host `"CHECK: `$env:DEFAULT_VAR`"" 2>&1 | Out-String
    $test2 = $output -match "DEFAULT_VAR=default_value" -and $output -match "CHECK: default_value"
    Write-TestResult "Sets temp_env vars" $test2 "Output: $output"

    # Test 3: Set numbered env (temp_env_1)
    Write-Host "`nTest 3: Set numbered env" -ForegroundColor Cyan
    $output = & powershell -NoProfile -Command "Set-Location '$testDir'; & '$iScript' set env 1; Write-Host `"CHECK: `$env:ENV1_VAR`"" 2>&1 | Out-String
    $test3 = $output -match "ENV1_VAR=env1_value" -and $output -match "CHECK: env1_value"
    Write-TestResult "Sets temp_env_1 vars" $test3 "Output: $output"

    # Test 4: Set another numbered env (temp_env_2)
    Write-Host "`nTest 4: Set temp_env_2" -ForegroundColor Cyan
    $output = & powershell -NoProfile -Command "Set-Location '$testDir'; & '$iScript' set env 2; Write-Host `"CHECK1: `$env:ENV2_VAR`"; Write-Host `"CHECK2: `$env:ENV2_SECOND`"" 2>&1 | Out-String
    $test4 = $output -match "ENV2_VAR=env2_value" -and $output -match "CHECK1: env2_value" -and $output -match "CHECK2: second_value"
    Write-TestResult "Sets temp_env_2 vars" $test4 "Output: $output"

    # Test 5: Missing env config
    Write-Host "`nTest 5: Missing env config" -ForegroundColor Cyan
    $output = & powershell -NoProfile -Command "Set-Location '$testDir'; & '$iScript' set env 99" 2>&1 | Out-String
    $test5 = $output -match "No.*temp_env_99.*found"
    Write-TestResult "Handles missing env config" $test5 "Output: $output"

    # Test 6: Invalid set command
    Write-Host "`nTest 6: Invalid set command" -ForegroundColor Cyan
    $output = & powershell -NoProfile -File $iScript set foo 2>&1 | Out-String
    $test6 = $output -match "Usage"
    Write-TestResult "Shows usage for invalid set" $test6 "Output: $output"

    Write-TestSummary

} finally {
    Set-Location $originalDir
}
