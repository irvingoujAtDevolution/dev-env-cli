# Simple test runner for individual test suites
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("set_env", "init_env", "run", "show_env")]
    [string]$TestSuite,
    
    [switch]$Verbose
)

$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$suiteDir = Join-Path $testDir $TestSuite
$testScript = Join-Path $suiteDir "test_$TestSuite.ps1"

if (-not (Test-Path $testScript)) {
    Write-Host "Test script not found: $testScript" -ForegroundColor Red
    exit 1
}

Write-Host "Running $TestSuite test suite..." -ForegroundColor Yellow
Write-Host "Test script: $testScript" -ForegroundColor Gray
Write-Host ""

try {
    $verboseFlag = if ($Verbose) { "-Verbose" } else { "" }
    & powershell -NoProfile -File $testScript @($verboseFlag)
    
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and $exitCode -ne $null) {
        exit $exitCode
    }
    
} catch {
    Write-Host "Error running test: $_" -ForegroundColor Red
    exit 1
}