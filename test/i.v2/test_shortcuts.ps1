# test_shortcuts.ps1 - Shortcut syntax tests (S1-S2)

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$testDir\TestHelper.ps1"

Reset-TestCounters

Write-Host "Shortcut Tests" -ForegroundColor Yellow
Write-Host "==============" -ForegroundColor Yellow
Write-Host ""

$appDir = Get-FixturePath "root\app"

# S1: Shortcut runs command (i build = i run build)
Write-Host "S1: Shortcut runs command" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("build")
$passed = $output -match "app-build"
Write-TestResult "S1" "i <cmd> runs the command" $passed "Output: $output"

# S2: Shortcut with args (i build --flag passes --flag)
Write-Host "`nS2: Shortcut with args" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("test", "--verbose", "--extra")
$passed = $output -match "--verbose" -and $output -match "--extra"
Write-TestResult "S2" "i <cmd> <args> passes args through" $passed "Output: $output"

Write-TestSummary "Shortcut Tests"
