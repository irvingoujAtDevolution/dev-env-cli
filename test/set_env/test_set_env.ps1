# Test script for set_env.ps1
param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent (Split-Path -Parent $testDir)
$setEnvScript = Join-Path $scriptDir "set_env.ps1"

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message -and ($Verbose -or -not $Passed)) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

# Save current directory and change to test directory
$originalDir = Get-Location
Set-Location $testDir

Write-Host "Running set_env.ps1 tests..." -ForegroundColor Yellow
Write-Host "Test directory: $testDir" -ForegroundColor Gray
Write-Host ""

try {
    # Test 1: Default temp_env loading
    Write-Host "Test 1: Loading default temp_env" -ForegroundColor Cyan
    
    $testScript = @"
Set-Location '$testDir'
& '$setEnvScript'
Write-Host "TEST_VAR_1: `$env:TEST_VAR_1"
Write-Host "TEST_VAR_2: `$env:TEST_VAR_2"
Write-Host "API_KEY: `$env:API_KEY"
"@
    
    $output = powershell -NoProfile -Command $testScript 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test1_1 = $output -match "TEST_VAR_1: value1"
    $test1_2 = $output -match "TEST_VAR_2: value2"
    $test1_3 = $output -match "API_KEY: test-api-key"
    
    Write-TestResult "Default temp_env - TEST_VAR_1" $test1_1 "Expected 'value1' in output"
    Write-TestResult "Default temp_env - TEST_VAR_2" $test1_2 "Expected 'value2' in output"
    Write-TestResult "Default temp_env - API_KEY" $test1_3 "Expected 'test-api-key' in output"

    # Test 2: Numbered temp_env loading (temp_env_1)
    Write-Host "`nTest 2: Loading temp_env_1" -ForegroundColor Cyan
    
    $testScript = @"
Set-Location '$testDir'
& '$setEnvScript' -number 1
Write-Host "DATABASE_URL: `$env:DATABASE_URL"
Write-Host "REDIS_URL: `$env:REDIS_URL"
"@
    
    $output = powershell -NoProfile -Command $testScript 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test2_1 = $output -match "DATABASE_URL: postgresql://localhost:5432/testdb"
    $test2_2 = $output -match "REDIS_URL: redis://localhost:6379"
    
    Write-TestResult "temp_env_1 - DATABASE_URL" $test2_1 "Expected database URL in output"
    Write-TestResult "temp_env_1 - REDIS_URL" $test2_2 "Expected Redis URL in output"

    # Test 3: Numbered temp_env loading (temp_env_2)
    Write-Host "`nTest 3: Loading temp_env_2" -ForegroundColor Cyan
    
    $testScript = @"
Set-Location '$testDir'
& '$setEnvScript' -number 2
Write-Host "STAGING_ENV: `$env:STAGING_ENV"
Write-Host "DEBUG_MODE: `$env:DEBUG_MODE"
"@
    
    $output = powershell -NoProfile -Command $testScript 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test3_1 = $output -match "STAGING_ENV: true"
    $test3_2 = $output -match "DEBUG_MODE: enabled"
    
    Write-TestResult "temp_env_2 - STAGING_ENV" $test3_1 "Expected 'true' in output"
    Write-TestResult "temp_env_2 - DEBUG_MODE" $test3_2 "Expected 'enabled' in output"

    # Test 4: Non-existent numbered temp_env
    Write-Host "`nTest 4: Non-existent temp_env_99" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $setEnvScript -number 99 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test4 = $output -match "temp_env_99.*does not exist"
    
    Write-TestResult "Non-existent temp_env_99" $test4 "Should show error message about missing temp_env_99"

    # Test 5: Script execution validation
    Write-Host "`nTest 5: Script execution validation" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $setEnvScript 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test5_1 = $output -match "Setting environment variable.*TEST_VAR_1.*value1"
    $test5_2 = $output -match "Setting environment variable.*API_KEY.*test-api-key"
    
    Write-TestResult "Shows environment variable setting messages" $test5_1 "Expected setting message for TEST_VAR_1"
    Write-TestResult "Shows API_KEY setting message" $test5_2 "Expected setting message for API_KEY"

    Write-Host "`nAll set_env.ps1 tests completed!" -ForegroundColor Green

} catch {
    Write-Host "Error during testing: $_" -ForegroundColor Red
    if ($Verbose) {
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
    }
} finally {
    # Restore original directory
    Set-Location $originalDir
}