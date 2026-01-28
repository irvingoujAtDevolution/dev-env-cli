# test_commands.ps1 - Command execution tests (C1-C9)

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$testDir\TestHelper.ps1"

Reset-TestCounters

Write-Host "Command Tests" -ForegroundColor Yellow
Write-Host "=============" -ForegroundColor Yellow
Write-Host ""

$appDir = Get-FixturePath "root\app"

# C1: String command
Write-Host "C1: String command" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("run", "build")
$passed = $output -match "app-build"
Write-TestResult "C1" "Runs string command" $passed "Output: $output"

# C2: Object with 'run'
Write-Host "`nC2: Object with run" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("run", "with_cwd")
# The command runs Get-Location which outputs a path table
$passed = $output -match "->" -and ($output -match "C:\\" -or $output -match "C:/")
Write-TestResult "C2" "Runs object command with 'run' field" $passed "Output: $output"

# C3: Object with cwd
Write-Host "`nC3: Object with cwd" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("run", "with_cwd")
$passed = $output -match "C:\\" -or $output -match "C:/"
Write-TestResult "C3" "Changes to specified cwd" $passed "Output: $output"

# C4: Inline env object
Write-Host "`nC4: Inline env object" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("run", "with_inline_env")
$passed = $output -match "INLINE_VAR=inline_value"
Write-TestResult "C4" "Sets inline env vars" $passed "Output: $output"

# C5: Env reference string
Write-Host "`nC5: Env reference string" -ForegroundColor Cyan
$rootDir = Get-FixturePath "root"
$output = Invoke-ICommand -WorkingDir $rootDir -Arguments @("run", "with_env_ref")
$passed = $output -match "ROOT_VAR=root_default_value"
Write-TestResult "C5" "Resolves env reference to profile" $passed "Output: $output"

# C6: Env reference array (merge)
Write-Host "`nC6: Env reference array" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("run", "with_env_array")
$passed = $output -match "app_default_value" -and $output -match "extra_value"
Write-TestResult "C6" "Merges multiple env profiles" $passed "Output: $output"

# C7: Extra args passthrough
Write-Host "`nC7: Extra args passthrough" -ForegroundColor Cyan
# Create a simple test - use echo command with extra args
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("run", "test", "--verbose", "--flag")
$passed = $output -match "--verbose" -and $output -match "--flag"
Write-TestResult "C7" "Passes extra arguments through" $passed "Output: $output"

# C8: Command not found
Write-Host "`nC8: Command not found" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("run", "nonexistent_command")
$passed = $output -match "not found" -or $output -match "No command"
Write-TestResult "C8" "Shows error for missing command" $passed "Output: $output"

# C9: Env reference not found
Write-Host "`nC9: Env reference not found" -ForegroundColor Cyan
# Need a fixture with bad env reference - create temp one
$tempDir = Join-Path $env:TEMP "i_test_c9_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
@{
    commands = @{
        bad_ref = @{
            run = "echo test"
            env = "nonexistent_profile"
        }
    }
} | ConvertTo-Json -Depth 10 | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$iScript = Join-Path (Get-ScriptPath) "i.ps1"
# Capture both stdout and stderr by redirecting in powershell
$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; `$ErrorActionPreference='Continue'; & '$iScript' run bad_ref 2>&1 | Out-String"
$outputStr = $output | Out-String
$passed = [bool]($outputStr -match "not found")
Write-TestResult "C9" "Shows error for missing env profile" $passed "Output: $outputStr"

Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-TestSummary "Command Tests"
