# TestHelper.ps1 - Common test utilities

$script:TestsPassed = 0
$script:TestsFailed = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )

    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }

    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message -and -not $Passed) {
        Write-Host "        $Message" -ForegroundColor Gray
    }

    if ($Passed) {
        $script:TestsPassed++
    } else {
        $script:TestsFailed++
    }
}

function Write-TestSummary {
    Write-Host ""
    $total = $script:TestsPassed + $script:TestsFailed
    $color = if ($script:TestsFailed -eq 0) { "Green" } else { "Red" }
    Write-Host "Results: $script:TestsPassed/$total passed" -ForegroundColor $color

    if ($script:TestsFailed -gt 0) {
        exit 1
    }
}

function Get-TestDir {
    return Split-Path -Parent $MyInvocation.PSCommandPath
}

function Get-ScriptDir {
    $testDir = Split-Path -Parent $MyInvocation.PSCommandPath
    return Split-Path -Parent (Split-Path -Parent $testDir)
}
