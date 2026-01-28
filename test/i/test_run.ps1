# test_run.ps1 - Tests for run functionality

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent (Split-Path -Parent $testDir)
$iScript = Join-Path $scriptDir "i.ps1"

. "$testDir\TestHelper.ps1"

$script:TestsPassed = 0
$script:TestsFailed = 0

Write-Host "Running: i run tests" -ForegroundColor Yellow
Write-Host "Test dir: $testDir" -ForegroundColor Gray
Write-Host ""

$originalDir = Get-Location
Set-Location $testDir

try {
    # Test 1: List commands (no arg)
    Write-Host "Test 1: List commands" -ForegroundColor Cyan
    $output = & powershell -NoProfile -File $iScript list cmd 2>&1 | Out-String
    $test1 = $output -match "echo_test" -and $output -match "complex_test"
    Write-TestResult "Lists available commands" $test1 "Output: $output"

    # Test 2: Run simple string command
    Write-Host "`nTest 2: Run string command" -ForegroundColor Cyan
    $output = & powershell -NoProfile -File $iScript run echo_test 2>&1 | Out-String
    $test2 = $output -match "Hello from i test"
    Write-TestResult "Runs string command" $test2 "Output: $output"

    # Test 3: Run with extra args
    Write-Host "`nTest 3: Run with extra args" -ForegroundColor Cyan
    $output = & powershell -NoProfile -File $iScript run args_test extra_arg_here 2>&1 | Out-String
    $test3 = $output -match "extra_arg_here"
    Write-TestResult "Passes extra arguments" $test3 "Output: $output"

    # Test 4: Run complex command (object format)
    Write-Host "`nTest 4: Run complex command" -ForegroundColor Cyan
    $output = & powershell -NoProfile -File $iScript run complex_test 2>&1 | Out-String
    $test4 = $output -match "Complex" -and $output -match "command"
    Write-TestResult "Runs object command" $test4 "Output: $output"

    # Test 5: Command with env vars
    Write-Host "`nTest 5: Command with env vars" -ForegroundColor Cyan
    $output = & powershell -NoProfile -File $iScript run env_cmd_test 2>&1 | Out-String
    $test5 = $output -match "test_value_123"
    Write-TestResult "Sets command env vars" $test5 "Output: $output"

    # Test 6: Shortcut syntax
    Write-Host "`nTest 6: Shortcut syntax" -ForegroundColor Cyan
    $output = & powershell -NoProfile -File $iScript echo_test 2>&1 | Out-String
    $test6 = $output -match "Hello from i test"
    Write-TestResult "Shortcut works (i <cmd>)" $test6 "Output: $output"

    # Test 7: Non-existent command
    Write-Host "`nTest 7: Non-existent command" -ForegroundColor Cyan
    $output = & powershell -NoProfile -File $iScript run nonexistent_cmd 2>&1 | Out-String
    $test7 = $output -match "not found"
    Write-TestResult "Handles missing command" $test7 "Output: $output"

    Write-TestSummary

} finally {
    Set-Location $originalDir
}
