# TestHelper.ps1 - Common test utilities for v2 tests

$script:TestsPassed = 0
$script:TestsFailed = 0
$script:TestsSkipped = 0

function Write-TestResult {
    param(
        [string]$TestId,
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )

    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }

    Write-Host "[$status] $TestId - $TestName" -ForegroundColor $color
    if ($Message -and -not $Passed) {
        Write-Host "        $Message" -ForegroundColor Gray
    }

    if ($Passed) {
        $script:TestsPassed++
    } else {
        $script:TestsFailed++
    }
}

function Write-TestSkipped {
    param(
        [string]$TestId,
        [string]$TestName,
        [string]$Reason = "Not implemented"
    )

    Write-Host "[SKIP] $TestId - $TestName" -ForegroundColor Yellow
    Write-Host "        $Reason" -ForegroundColor Gray
    $script:TestsSkipped++
}

function Write-TestSummary {
    param([string]$SuiteName = "Tests")

    Write-Host ""
    $total = $script:TestsPassed + $script:TestsFailed
    if ($script:TestsFailed -eq 0 -and $total -gt 0) {
        Write-Host "$SuiteName : $script:TestsPassed/$total passed" -ForegroundColor Green
    } elseif ($total -eq 0) {
        Write-Host "$SuiteName : No tests ran" -ForegroundColor Yellow
    } else {
        Write-Host "$SuiteName : $script:TestsPassed/$total passed, $script:TestsFailed failed" -ForegroundColor Red
    }

    if ($script:TestsSkipped -gt 0) {
        Write-Host "         $script:TestsSkipped skipped" -ForegroundColor Yellow
    }

    return $script:TestsFailed -eq 0
}

function Reset-TestCounters {
    $script:TestsPassed = 0
    $script:TestsFailed = 0
    $script:TestsSkipped = 0
}

function Get-FixturePath {
    param([string]$RelativePath = "")
    $testDir = Split-Path -Parent $PSScriptRoot
    $fixturesDir = Join-Path $testDir "i.v2\fixtures"
    if ($RelativePath) {
        return Join-Path $fixturesDir $RelativePath
    }
    return $fixturesDir
}

function Get-ScriptPath {
    $testDir = Split-Path -Parent $PSScriptRoot
    return Split-Path -Parent $testDir
}

function Invoke-ICommand {
    param(
        [string]$WorkingDir,
        [string[]]$Arguments
    )

    $iScript = Join-Path (Get-ScriptPath) "i.ps1"
    $argString = $Arguments -join "' '"
    if ($argString) { $argString = "'$argString'" }

    $output = & powershell -NoProfile -Command "Set-Location '$WorkingDir'; & '$iScript' $argString" 2>&1 | Out-String
    return $output
}
