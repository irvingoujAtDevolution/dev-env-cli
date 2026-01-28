# test_init.ps1 - Tests for init functionality

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent (Split-Path -Parent $testDir)
$iScript = Join-Path $scriptDir "i.ps1"
$templatePath = Join-Path $scriptDir "template\.dev_env.json"

. "$testDir\TestHelper.ps1"

$script:TestsPassed = 0
$script:TestsFailed = 0

Write-Host "Running: i init tests" -ForegroundColor Yellow
Write-Host "Test dir: $testDir" -ForegroundColor Gray
Write-Host ""

# Create a temp directory for init tests
$tempTestDir = Join-Path $env:TEMP "i_init_test_$(Get-Random)"
New-Item -ItemType Directory -Path $tempTestDir -Force | Out-Null

$originalDir = Get-Location

try {
    # Test 1: Init from template
    Write-Host "Test 1: Init from template" -ForegroundColor Cyan
    Set-Location $tempTestDir

    $output = & powershell -NoProfile -File $iScript init 2>&1 | Out-String
    $devEnvPath = Join-Path $tempTestDir ".dev_env.json"
    $test1_1 = Test-Path $devEnvPath
    Write-TestResult "Creates .dev_env.json" $test1_1 "Path: $devEnvPath"

    if ($test1_1) {
        try {
            $content = Get-Content $devEnvPath -Raw | ConvertFrom-Json
            $test1_2 = $content.PSObject.Properties.Name -contains "quick_command"
            Write-TestResult "Contains quick_command" $test1_2
        } catch {
            Write-TestResult "Valid JSON" $false "Parse error: $_"
        }
    }

    # Test 2: Init when file exists
    Write-Host "`nTest 2: Init when file exists" -ForegroundColor Cyan
    $output = & powershell -NoProfile -File $iScript init 2>&1 | Out-String
    $test2 = $output -match "Already exists"
    Write-TestResult "Detects existing file" $test2 "Output: $output"

    # Test 3: Init with DEV_ENV_VARIABLES
    Write-Host "`nTest 3: Init with DEV_ENV_VARIABLES" -ForegroundColor Cyan

    # Create a new temp dir for this test
    $tempTestDir2 = Join-Path $env:TEMP "i_init_test2_$(Get-Random)"
    New-Item -ItemType Directory -Path $tempTestDir2 -Force | Out-Null
    Set-Location $tempTestDir2

    # Create custom config
    $customConfigPath = Join-Path $tempTestDir2 "custom.json"
    @{
        quick_command = @{ my_cmd = "echo custom" }
        target = "custom"
    } | ConvertTo-Json | Out-File $customConfigPath -Encoding UTF8

    $output = & powershell -NoProfile -Command "`$env:DEV_ENV_VARIABLES = '$customConfigPath'; & '$iScript' init" 2>&1 | Out-String
    $devEnvPath2 = Join-Path $tempTestDir2 ".dev_env.json"

    $test3_1 = Test-Path $devEnvPath2
    Write-TestResult "Creates from DEV_ENV_VARIABLES" $test3_1

    if ($test3_1) {
        try {
            $content = Get-Content $devEnvPath2 -Raw | ConvertFrom-Json
            $test3_2 = $content.target -eq "custom"
            Write-TestResult "Has custom content" $test3_2
        } catch {
            Write-TestResult "Valid JSON from custom" $false "Parse error: $_"
        }
    }

    # Cleanup temp dir 2
    Remove-Item -Path $tempTestDir2 -Recurse -Force -ErrorAction SilentlyContinue

    # Test 4: Fallback to empty (no template)
    Write-Host "`nTest 4: Fallback to empty" -ForegroundColor Cyan

    $tempTestDir3 = Join-Path $env:TEMP "i_init_test3_$(Get-Random)"
    New-Item -ItemType Directory -Path $tempTestDir3 -Force | Out-Null
    Set-Location $tempTestDir3

    # Temporarily rename template if it exists
    $templateBackup = $null
    if (Test-Path $templatePath) {
        $templateBackup = "$templatePath.backup"
        Move-Item $templatePath $templateBackup
    }

    try {
        $output = & powershell -NoProfile -Command "`$env:DEV_ENV_VARIABLES = `$null; & '$iScript' init" 2>&1 | Out-String
        $devEnvPath3 = Join-Path $tempTestDir3 ".dev_env.json"

        $test4_1 = Test-Path $devEnvPath3
        Write-TestResult "Creates empty file" $test4_1

        if ($test4_1) {
            $content = (Get-Content $devEnvPath3 -Raw).Trim()
            $test4_2 = $content -eq "{}"
            Write-TestResult "Contains empty JSON" $test4_2 "Content: $content"
        }
    } finally {
        # Restore template
        if ($templateBackup -and (Test-Path $templateBackup)) {
            Move-Item $templateBackup $templatePath
        }
    }

    # Cleanup temp dir 3
    Remove-Item -Path $tempTestDir3 -Recurse -Force -ErrorAction SilentlyContinue

    Write-TestSummary

} finally {
    Set-Location $originalDir
    # Cleanup main temp dir
    Remove-Item -Path $tempTestDir -Recurse -Force -ErrorAction SilentlyContinue
}
