# run_all_tests.ps1 - Run all i.ps1 tests

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  i.ps1 Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$tests = @(
    "test_run.ps1",
    "test_env.ps1",
    "test_init.ps1"
)

$allPassed = $true

foreach ($test in $tests) {
    $testPath = Join-Path $testDir $test
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    & powershell -NoProfile -File $testPath
    if ($LASTEXITCODE -ne 0) {
        $allPassed = $false
    }
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "  All test suites passed!" -ForegroundColor Green
} else {
    Write-Host "  Some tests failed!" -ForegroundColor Red
    exit 1
}
Write-Host "========================================" -ForegroundColor Cyan
