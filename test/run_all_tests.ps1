# Test runner script for all PowerShell utilities
param(
    [switch]$Verbose,
    [string[]]$TestSuite = @("set_env", "init_env", "run", "show_env"),
    [switch]$StopOnFailure
)

$ErrorActionPreference = "Continue"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $testDir

function Write-TestSuiteResult {
    param(
        [string]$SuiteName,
        [bool]$Passed,
        [int]$TestCount = 0,
        [string]$Message = ""
    )
    
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    $countText = if ($TestCount -gt 0) { " ($TestCount tests)" } else { "" }
    
    Write-Host "[$status] $SuiteName$countText" -ForegroundColor $color
    if ($Message -and ($Verbose -or -not $Passed)) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

function Invoke-TestSuite {
    param(
        [string]$SuiteName
    )
    
    $suiteDir = Join-Path $testDir $SuiteName
    $testScript = Join-Path $suiteDir "test_$SuiteName.ps1"
    
    if (-not (Test-Path $testScript)) {
        Write-TestSuiteResult $SuiteName $false 0 "Test script not found: $testScript"
        return $false
    }
    
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor DarkGray
    Write-Host "Running $SuiteName test suite" -ForegroundColor Yellow
    Write-Host "=" * 60 -ForegroundColor DarkGray
    
    try {
        $verboseFlag = if ($Verbose) { "-Verbose" } else { "" }
        $output = & powershell -NoProfile -File $testScript @($verboseFlag) 2>&1
        
        # Count test results in output
        $passCount = ($output | Select-String "\[PASS\]" | Measure-Object).Count
        $failCount = ($output | Select-String "\[FAIL\]" | Measure-Object).Count
        $totalTests = $passCount + $failCount
        
        # Display the output
        $output | ForEach-Object { Write-Host $_ }
        
        # Determine suite result
        $suitePassed = $failCount -eq 0 -and $totalTests -gt 0
        
        Write-Host "`nSuite Summary:" -ForegroundColor Cyan
        Write-Host "  Total tests: $totalTests" -ForegroundColor Gray
        Write-Host "  Passed: $passCount" -ForegroundColor Green
        Write-Host "  Failed: $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
        
        Write-TestSuiteResult $SuiteName $suitePassed $totalTests
        
        return $suitePassed
        
    } catch {
        Write-Host "Exception during test execution: $_" -ForegroundColor Red
        Write-TestSuiteResult $SuiteName $false 0 "Exception: $_"
        return $false
    }
}

# Main test execution
$originalDir = Get-Location

Write-Host "PowerShell Utilities Test Runner" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor Magenta
Write-Host "Test directory: $testDir" -ForegroundColor Gray
Write-Host "Script directory: $scriptDir" -ForegroundColor Gray
Write-Host "Test suites: $($TestSuite -join ', ')" -ForegroundColor Gray
Write-Host ""

$results = @{}
$overallSuccess = $true

try {
    foreach ($suite in $TestSuite) {
        $suiteResult = Invoke-TestSuite -SuiteName $suite
        $results[$suite] = $suiteResult
        
        if (-not $suiteResult) {
            $overallSuccess = $false
            if ($StopOnFailure) {
                Write-Host "`nStopping test execution due to failure in $suite suite" -ForegroundColor Red
                break
            }
        }
        
        Start-Sleep -Milliseconds 500  # Brief pause between suites
    }
    
    # Overall results summary
    Write-Host "`n"
    Write-Host "=" * 60 -ForegroundColor DarkGray
    Write-Host "OVERALL TEST RESULTS" -ForegroundColor Magenta
    Write-Host "=" * 60 -ForegroundColor DarkGray
    
    $passedSuites = 0
    $failedSuites = 0
    
    foreach ($suite in $TestSuite) {
        if ($results.ContainsKey($suite)) {
            if ($results[$suite]) {
                Write-Host "✓ $suite" -ForegroundColor Green
                $passedSuites++
            } else {
                Write-Host "✗ $suite" -ForegroundColor Red
                $failedSuites++
            }
        } else {
            Write-Host "? $suite (not run)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Test suites passed: $passedSuites" -ForegroundColor Green
    Write-Host "  Test suites failed: $failedSuites" -ForegroundColor $(if ($failedSuites -eq 0) { "Green" } else { "Red" })
    Write-Host "  Overall result: $(if ($overallSuccess) { "SUCCESS" } else { "FAILURE" })" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Red" })
    
    # Set exit code based on results
    if ($overallSuccess) {
        Write-Host "`nAll tests passed! 🎉" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`nSome tests failed. Please review the output above. ❌" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "`nUnexpected error in test runner: $_" -ForegroundColor Red
    exit 1
} finally {
    Set-Location $originalDir
}