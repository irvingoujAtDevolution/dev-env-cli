# test_add.ps1 - Tests for add cmd and add env

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$testDir\TestHelper.ps1"

Reset-TestCounters

Write-Host "Add Command Tests" -ForegroundColor Yellow
Write-Host "=================" -ForegroundColor Yellow
Write-Host ""

$iScript = Join-Path (Get-ScriptPath) "i.ps1"

function New-TestConfig {
    param([string]$TempDir, [string]$Content = '{"commands":{},"env":{}}')
    $Content | Out-File "$TempDir\.dev_env.json" -Encoding UTF8
}

function Get-TestConfig {
    param([string]$TempDir)
    Get-Content "$TempDir\.dev_env.json" -Raw | ConvertFrom-Json
}

# ============================================
# ADD ENV TESTS
# ============================================

Write-Host "--- ADD ENV ---" -ForegroundColor Magenta
Write-Host ""

# AE1: Add env profile with single var
Write-Host "AE1: Add env with single var" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ae1_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add env dev 'DEBUG=true'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.env.dev.DEBUG -eq "true"
Write-TestResult "AE1" "Adds env profile with single var" $passed "Config: $($config.env | ConvertTo-Json -Compress)"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AE2: Add env profile with multiple vars
Write-Host "`nAE2: Add env with multiple vars" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ae2_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add env prod 'DEBUG=false' 'LOG_LEVEL=error' 'API_URL=https://api.prod.com'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.env.prod.DEBUG -eq "false" -and
          $config.env.prod.LOG_LEVEL -eq "error" -and
          $config.env.prod.API_URL -eq "https://api.prod.com"
Write-TestResult "AE2" "Adds env profile with multiple vars" $passed
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AE3: Add to existing env profile (merge)
Write-Host "`nAE3: Add to existing env profile" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ae3_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
'{"commands":{},"env":{"dev":{"EXISTING":"value"}}}' | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add env dev 'NEW_VAR=new_value'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.env.dev.EXISTING -eq "value" -and $config.env.dev.NEW_VAR -eq "new_value"
Write-TestResult "AE3" "Merges with existing env profile" $passed
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AE4: Override existing var in profile
Write-Host "`nAE4: Override existing var" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ae4_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
'{"commands":{},"env":{"dev":{"DEBUG":"false"}}}' | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add env dev 'DEBUG=true'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.env.dev.DEBUG -eq "true"
Write-TestResult "AE4" "Overrides existing var in profile" $passed
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AE5: Add env with special characters in value
Write-Host "`nAE5: Add env with special chars" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ae5_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add env dev 'CONNECTION=Server=localhost;Port=5432'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.env.dev.CONNECTION -eq "Server=localhost;Port=5432"
Write-TestResult "AE5" "Handles special chars in value" $passed "Value: $($config.env.dev.CONNECTION)"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AE6: Error - no vars provided
Write-Host "`nAE6: Error when no vars provided" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ae6_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add env dev 2>&1" | Out-String
$passed = $output -match "Usage" -or $output -match "KEY=VALUE"
Write-TestResult "AE6" "Shows error when no vars provided" $passed "Output: $output"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AE7: Error - invalid format (no =)
Write-Host "`nAE7: Error on invalid format" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ae7_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add env dev 'INVALID' 2>&1" | Out-String
$passed = $output -match "invalid" -or $output -match "format" -or $output -match "KEY=VALUE"
Write-TestResult "AE7" "Shows error on invalid var format" $passed "Output: $output"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# ============================================
# ADD CMD TESTS - BASIC
# ============================================

Write-Host ""
Write-Host "--- ADD CMD (Basic) ---" -ForegroundColor Magenta
Write-Host ""

# AC1: Add simple string command
Write-Host "AC1: Add simple command" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac1_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd build 'dotnet build'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.commands.build -eq "dotnet build"
Write-TestResult "AC1" "Adds simple string command" $passed "Command: $($config.commands.build)"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC2: Add command with cwd
Write-Host "`nAC2: Add command with cwd" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac2_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd dev 'npm start' cwd=./frontend" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.commands.dev.run -eq "npm start" -and $config.commands.dev.cwd -eq "./frontend"
Write-TestResult "AC2" "Adds command with cwd" $passed "Command: $($config.commands.dev | ConvertTo-Json -Compress)"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC3: Add command with env profile reference
Write-Host "`nAC3: Add command with env profile ref" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac3_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
'{"commands":{},"env":{"dev":{"DEBUG":"true"}}}' | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd serve 'npm start' env=dev" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.commands.serve.run -eq "npm start" -and $config.commands.serve.env -eq "dev"
Write-TestResult "AC3" "Adds command with env profile reference" $passed "Command: $($config.commands.serve | ConvertTo-Json -Compress)"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC4: Add command with multiple env profiles
Write-Host "`nAC4: Add command with multiple env profiles" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac4_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
'{"commands":{},"env":{"default":{"A":"1"},"dev":{"B":"2"}}}' | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd serve 'npm start' 'env=default,dev'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.commands.serve.run -eq "npm start" -and
          $config.commands.serve.env -is [array] -and
          $config.commands.serve.env[0] -eq "default" -and
          $config.commands.serve.env[1] -eq "dev"
Write-TestResult "AC4" "Adds command with multiple env profiles" $passed "Env: $($config.commands.serve.env | ConvertTo-Json -Compress)"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC5: Add command with inline env vars
Write-Host "`nAC5: Add command with inline env vars" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac5_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd dev 'npm start' 'env=NODE_ENV=development,PORT=3000'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.commands.dev.run -eq "npm start" -and
          $config.commands.dev.env.NODE_ENV -eq "development" -and
          $config.commands.dev.env.PORT -eq "3000"
Write-TestResult "AC5" "Adds command with inline env vars" $passed "Env: $($config.commands.dev.env | ConvertTo-Json -Compress)"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC6: Add command with cwd and env
Write-Host "`nAC6: Add command with cwd and env" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac6_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
'{"commands":{},"env":{"dev":{"DEBUG":"true"}}}' | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd serve 'npm start' cwd=./app env=dev" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.commands.serve.run -eq "npm start" -and
          $config.commands.serve.cwd -eq "./app" -and
          $config.commands.serve.env -eq "dev"
Write-TestResult "AC6" "Adds command with both cwd and env" $passed
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC7: Override existing command
Write-Host "`nAC7: Override existing command" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac7_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
'{"commands":{"build":"old command"},"env":{}}' | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd build 'new command'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.commands.build -eq "new command"
Write-TestResult "AC7" "Overrides existing command" $passed
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# ============================================
# ADD CMD TESTS - ERROR CASES
# ============================================

Write-Host ""
Write-Host "--- ADD CMD (Errors) ---" -ForegroundColor Magenta
Write-Host ""

# AC8: Error - env profile doesn't exist
Write-Host "AC8: Error when env profile doesn't exist" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac8_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd serve 'npm start' env=nonexistent 2>&1" | Out-String
$passed = $output -match "not found" -or $output -match "doesn't exist" -or $output -match "not exist"
Write-TestResult "AC8" "Shows error when env profile doesn't exist" $passed "Output: $output"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC9: Error - no command provided
Write-Host "`nAC9: Error when no command provided" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac9_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd build 2>&1" | Out-String
$passed = $output -match "Usage" -or $output -match "run"
Write-TestResult "AC9" "Shows error when no run command provided" $passed "Output: $output"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC10: Error - no name provided
Write-Host "`nAC10: Error when no name provided" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac10_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd 2>&1" | Out-String
$passed = $output -match "Usage" -or $output -match "name"
Write-TestResult "AC10" "Shows error when no name provided" $passed "Output: $output"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# ============================================
# ADD CMD TESTS - EDGE CASES
# ============================================

Write-Host ""
Write-Host "--- ADD CMD (Edge Cases) ---" -ForegroundColor Magenta
Write-Host ""

# AC11: Command with spaces in run
Write-Host "AC11: Command with complex run string" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac11_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd test 'dotnet test --no-build --verbosity normal'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.commands.test -eq "dotnet test --no-build --verbosity normal"
Write-TestResult "AC11" "Handles complex run string with spaces" $passed "Command: $($config.commands.test)"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC12: Single inline env var
Write-Host "`nAC12: Single inline env var" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac12_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd dev 'npm start' 'env=DEBUG=true'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.commands.dev.env.DEBUG -eq "true"
Write-TestResult "AC12" "Handles single inline env var" $passed
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC13: Env var with = in value
Write-Host "`nAC13: Env var with = in value" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac13_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
New-TestConfig -TempDir $tempDir

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd db 'psql' 'env=CONN=host=localhost;port=5432'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.commands.db.env.CONN -eq "host=localhost;port=5432"
Write-TestResult "AC13" "Handles = in env value" $passed "Value: $($config.commands.db.env.CONN)"
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC14: Creates config if doesn't exist
Write-Host "`nAC14: Creates config if missing" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac14_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
# Don't create config file

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd build 'make build'" 2>&1 | Out-String
$configExists = Test-Path "$tempDir\.dev_env.json"
$config = if ($configExists) { Get-TestConfig -TempDir $tempDir } else { $null }

$passed = $configExists -and $config.commands.build -eq "make build"
Write-TestResult "AC14" "Creates config file if missing" $passed
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# AC15: Preserves other config fields
Write-Host "`nAC15: Preserves other config fields" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_add_test_ac15_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
'{"commands":{},"env":{},"gateway_url":"ws://localhost","custom":"preserved"}' | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' add cmd build 'make'" 2>&1 | Out-String
$config = Get-TestConfig -TempDir $tempDir

$passed = $config.gateway_url -eq "ws://localhost" -and $config.custom -eq "preserved"
Write-TestResult "AC15" "Preserves unrelated config fields" $passed
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-TestSummary "Add Tests"
