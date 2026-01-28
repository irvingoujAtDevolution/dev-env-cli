# test_init.ps1 - Init command tests (I1-I2)

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$testDir\TestHelper.ps1"

Reset-TestCounters

Write-Host "Init Tests" -ForegroundColor Yellow
Write-Host "==========" -ForegroundColor Yellow
Write-Host ""

$iScript = Join-Path (Get-ScriptPath) "i.ps1"

# I1: Create new config with v2 structure
Write-Host "I1: Create new v2 config" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_test_init_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    $output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' init" 2>&1 | Out-String
    $configPath = Join-Path $tempDir ".dev_env.json"

    $fileExists = Test-Path $configPath
    Write-TestResult "I1a" "Creates .dev_env.json" $fileExists "Path: $configPath"

    if ($fileExists) {
        $content = Get-Content $configPath -Raw | ConvertFrom-Json
        # Check v2 structure: should have 'commands' not 'quick_command'
        $hasCommands = $content.PSObject.Properties.Name -contains "commands"
        $hasEnv = $content.PSObject.Properties.Name -contains "env"
        $noQuickCommand = -not ($content.PSObject.Properties.Name -contains "quick_command")

        Write-TestResult "I1b" "Has 'commands' section" $hasCommands
        Write-TestResult "I1c" "Has 'env' section" $hasEnv
        Write-TestResult "I1d" "No old 'quick_command' section" $noQuickCommand
    }
} finally {
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}

# I2: Already exists - should skip
Write-Host "`nI2: Already exists" -ForegroundColor Cyan
$tempDir2 = Join-Path $env:TEMP "i_test_init2_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir2 -Force | Out-Null
# Create existing file
'{"existing": true}' | Out-File (Join-Path $tempDir2 ".dev_env.json") -Encoding UTF8

try {
    $output = & powershell -NoProfile -Command "Set-Location '$tempDir2'; & '$iScript' init" 2>&1 | Out-String
    $passed = $output -match "exists" -or $output -match "Already"
    Write-TestResult "I2" "Detects existing file and skips" $passed "Output: $output"

    # Verify content wasn't changed
    $content = Get-Content (Join-Path $tempDir2 ".dev_env.json") -Raw | ConvertFrom-Json
    $unchanged = $content.existing -eq $true
    Write-TestResult "I2b" "Doesn't overwrite existing file" $unchanged
} finally {
    Remove-Item -Path $tempDir2 -Recurse -Force -ErrorAction SilentlyContinue
}

Write-TestSummary "Init Tests"
