# run_all_tests.ps1 - Run all v2 tests

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  i.ps1 v2 Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tests = @(
    "test_merge.ps1",
    "test_commands.ps1",
    "test_env.ps1",
    "test_list.ps1",
    "test_init.ps1",
    "test_shortcuts.ps1",
    "test_migrate.ps1"
)

$totalPassed = 0
$totalFailed = 0

foreach ($test in $tests) {
    $testPath = Join-Path $testDir $test
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    & powershell -NoProfile -File $testPath
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Suite Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
