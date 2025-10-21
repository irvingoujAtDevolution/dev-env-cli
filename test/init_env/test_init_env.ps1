# Test script for init_env.ps1
param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent (Split-Path -Parent $testDir)
$initEnvScript = Join-Path $scriptDir "init_env.ps1"
$templatePath = Join-Path $scriptDir "template\.dev_env.json"

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message -and ($Verbose -or -not $Passed)) {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

# Save current directory and change to test directory
$originalDir = Get-Location
Set-Location $testDir

Write-Host "Running init_env.ps1 tests..." -ForegroundColor Yellow
Write-Host "Test directory: $testDir" -ForegroundColor Gray
Write-Host ""

try {
    # Test 1: Initialize from template (no existing file)
    Write-Host "Test 1: Initialize from template" -ForegroundColor Cyan
    
    # Remove any existing .dev_env.json
    $devEnvPath = Join-Path $testDir ".dev_env.json"
    if (Test-Path $devEnvPath) {
        Remove-Item $devEnvPath -Force
    }
    
    # Clear DEV_ENV_VARIABLES environment variable
    $env:DEV_ENV_VARIABLES = $null
    
    $output = & powershell -NoProfile -File $initEnvScript 2>&1
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test1_1 = Test-Path $devEnvPath
    Write-TestResult "File created" $test1_1 "Expected .dev_env.json to be created"
    
    if ($test1_1) {
        try {
            $content = Get-Content $devEnvPath -Raw | ConvertFrom-Json
            $test1_2 = $content.PSObject.Properties.Name -contains "quick_command"
            $test1_3 = $content.PSObject.Properties.Name -contains "target"
            $test1_4 = $content.PSObject.Properties.Name -contains '$schema'
            
            Write-TestResult "Contains quick_command" $test1_2
            Write-TestResult "Contains target" $test1_3
            Write-TestResult "Contains schema reference" $test1_4
        } catch {
            Write-TestResult "Valid JSON" $false "Failed to parse JSON: $_"
        }
    }

    # Test 2: File already exists
    Write-Host "`nTest 2: File already exists" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $initEnvScript 2>&1
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test2 = $output -match "already exists"
    Write-TestResult "Detects existing file" $test2 "Should show message about existing file"

    # Test 3: Initialize with DEV_ENV_VARIABLES
    Write-Host "`nTest 3: Initialize with DEV_ENV_VARIABLES" -ForegroundColor Cyan
    
    # Create a custom config file
    $customConfigPath = Join-Path $testDir "custom_config.json"
    $customConfig = @{
        quick_command = @{
            custom_test = "echo 'custom test'"
        }
        target = "rdp"
    }
    $customConfig | ConvertTo-Json | Out-File $customConfigPath -Encoding UTF8
    
    # Remove existing .dev_env.json
    if (Test-Path $devEnvPath) {
        Remove-Item $devEnvPath -Force
    }
    
    # Set DEV_ENV_VARIABLES
    $env:DEV_ENV_VARIABLES = $customConfigPath
    
    $output = & powershell -NoProfile -File $initEnvScript 2>&1
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test3_1 = Test-Path $devEnvPath
    Write-TestResult "File created from DEV_ENV_VARIABLES" $test3_1
    
    if ($test3_1) {
        try {
            $content = Get-Content $devEnvPath -Raw | ConvertFrom-Json
            $test3_2 = $content.quick_command.custom_test -eq "echo 'custom test'"
            $test3_3 = $content.target -eq "rdp"
            
            Write-TestResult "Custom content copied" $test3_2
            Write-TestResult "Target set correctly" $test3_3
        } catch {
            Write-TestResult "Valid JSON from DEV_ENV_VARIABLES" $false "Failed to parse JSON: $_"
        }
    }

    # Test 4: Fallback to empty file
    Write-Host "`nTest 4: Fallback to empty file" -ForegroundColor Cyan
    
    # Remove existing files
    if (Test-Path $devEnvPath) {
        Remove-Item $devEnvPath -Force
    }
    if (Test-Path $customConfigPath) {
        Remove-Item $customConfigPath -Force
    }
    
    # Clear DEV_ENV_VARIABLES and temporarily rename template
    $env:DEV_ENV_VARIABLES = $null
    $templateBackup = $templatePath + ".backup"
    if (Test-Path $templatePath) {
        Move-Item $templatePath $templateBackup
    }
    
    $output = & powershell -NoProfile -File $initEnvScript 2>&1
    if ($Verbose) {
        Write-Host "Output: $output" -ForegroundColor Gray
    }
    
    $test4_1 = Test-Path $devEnvPath
    Write-TestResult "Empty file created" $test4_1
    
    if ($test4_1) {
        $content = Get-Content $devEnvPath -Raw
        $test4_2 = $content.Trim() -eq "{}"
        Write-TestResult "File contains empty JSON" $test4_2
    }
    
    # Restore template
    if (Test-Path $templateBackup) {
        Move-Item $templateBackup $templatePath
    }

    Write-Host "`nAll init_env.ps1 tests completed!" -ForegroundColor Green

} catch {
    Write-Host "Error during testing: $_" -ForegroundColor Red
} finally {
    # Restore original directory
    Set-Location $originalDir
    
    # Clean up
    $env:DEV_ENV_VARIABLES = $null
    
    # Clean up test files
    $filesToClean = @(
        (Join-Path $testDir ".dev_env.json"),
        (Join-Path $testDir "custom_config.json"),
        ($templatePath + ".backup")
    )
    
    foreach ($file in $filesToClean) {
        if (Test-Path $file) {
            Remove-Item $file -Force -ErrorAction SilentlyContinue
        }
    }
}