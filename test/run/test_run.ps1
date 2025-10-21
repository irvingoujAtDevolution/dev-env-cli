# Test script for run.ps1
param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent (Split-Path -Parent $testDir)
$runScript = Join-Path $scriptDir "run.ps1"

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

Write-Host "Running run.ps1 tests..." -ForegroundColor Yellow
Write-Host "Test directory: $testDir" -ForegroundColor Gray
Write-Host ""

try {
    # Test 1: List available commands (no arguments)
    Write-Host "Test 1: List available commands" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $runScript 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test1_1 = $output -match "Available commands:"
    $test1_2 = $output -match "simple_test"
    $test1_3 = $output -match "complex_test"
    $test1_4 = $output -match "env_test"
    
    Write-TestResult "Shows 'Available commands'" $test1_1
    Write-TestResult "Lists simple_test command" $test1_2
    Write-TestResult "Lists complex_test command" $test1_3
    Write-TestResult "Lists env_test command" $test1_4

    # Test 2: Run simple string command
    Write-Host "`nTest 2: Run simple string command" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $runScript simple_test 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test2_1 = $output -match "Running command: echo 'Simple command test'"
    $test2_2 = $output -match "Simple command test"
    
    Write-TestResult "Shows command execution" $test2_1
    Write-TestResult "Command produces expected output" $test2_2

    # Test 3: Run complex object command
    Write-Host "`nTest 3: Run complex object command" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $runScript complex_test 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test3_1 = $output -match "Running command:.*echo Complex command test"
    $test3_2 = $output -match "Complex command test"
    
    Write-TestResult "Shows complex command execution" $test3_1
    Write-TestResult "Complex command produces expected output" $test3_2

    # Test 4: Run command with environment variables
    Write-Host "`nTest 4: Run command with environment variables" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $runScript env_test 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test4_1 = $output -match "Setting environment variable: TEST_RUN_VAR=test_value"
    $test4_2 = $output -match "ENV_VAR: test_value"
    
    Write-TestResult "Shows environment variable setting" $test4_1
    Write-TestResult "Environment variable is available in command" $test4_2

    # Test 5: Run command with working directory change
    Write-Host "`nTest 5: Run command with working directory change" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $runScript cwd_test 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test5_1 = $output -match "Running command.*in directory:.*C:\\"
    $test5_2 = $output -match "C:\\"
    
    Write-TestResult "Shows directory change" $test5_1
    Write-TestResult "Command runs in specified directory" $test5_2

    # Test 6: Non-existent command
    Write-Host "`nTest 6: Non-existent command" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $runScript nonexistent_command 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test6 = $output -match "No quick command found matching 'nonexistent_command'"
    
    Write-TestResult "Handles non-existent command" $test6

    # Test 7: Another simple command to verify multiple commands work
    Write-Host "`nTest 7: Run another simple command" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $runScript echo_hello 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test7_1 = $output -match "Running command: echo 'Hello from run test'"
    $test7_2 = $output -match "Hello from run test"
    
    Write-TestResult "Shows second command execution" $test7_1
    Write-TestResult "Second command produces expected output" $test7_2

    Write-Host "`nAll run.ps1 tests completed!" -ForegroundColor Green

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