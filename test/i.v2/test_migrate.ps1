# test_migrate.ps1 - Migration tests

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$testDir\TestHelper.ps1"

Reset-TestCounters

Write-Host "Migrate Tests" -ForegroundColor Yellow
Write-Host "=============" -ForegroundColor Yellow
Write-Host ""

$iScript = Join-Path (Get-ScriptPath) "i.ps1"

# Test 1: Migrate quick_command to commands
Write-Host "MIG1: Migrate quick_command -> commands" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_migrate_test1_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Create v1 config
@'
{
  "quick_command": {
    "build": "echo build",
    "test": "echo test"
  }
}
'@ | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' migrate" 2>&1 | Out-String
$content = Get-Content "$tempDir\.dev_env.json" -Raw | ConvertFrom-Json

$passed = $content.PSObject.Properties.Name -contains "commands" -and
          -not ($content.PSObject.Properties.Name -contains "quick_command")
Write-TestResult "MIG1" "Converts quick_command to commands" $passed "Output: $output"

Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Test 2: Migrate complex command (command + args -> run)
Write-Host "`nMIG2: Migrate command+args -> run" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_migrate_test2_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

@'
{
  "quick_command": {
    "build": {
      "cwd": "C:/project",
      "command": "dotnet",
      "args": ["build", "-c", "Release"],
      "env": []
    }
  }
}
'@ | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' migrate" 2>&1 | Out-String
$content = Get-Content "$tempDir\.dev_env.json" -Raw | ConvertFrom-Json

$passed = $content.commands.build.run -eq "dotnet build -c Release" -and
          $content.commands.build.cwd -eq "C:/project"
Write-TestResult "MIG2" "Converts command+args to run" $passed "Content: $($content.commands.build | ConvertTo-Json -Compress)"

Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Test 3: Migrate env array to object
Write-Host "`nMIG3: Migrate env array -> object" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_migrate_test3_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

@'
{
  "quick_command": {
    "dev": {
      "command": "npm",
      "args": ["start"],
      "env": [
        { "NODE_ENV": "development" },
        { "DEBUG": "true" }
      ]
    }
  }
}
'@ | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' migrate" 2>&1 | Out-String
$content = Get-Content "$tempDir\.dev_env.json" -Raw | ConvertFrom-Json

$passed = $content.commands.dev.env.NODE_ENV -eq "development" -and
          $content.commands.dev.env.DEBUG -eq "true"
Write-TestResult "MIG3" "Converts env array to object" $passed "Env: $($content.commands.dev.env | ConvertTo-Json -Compress)"

Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Test 4: Migrate temp_env to env.default
Write-Host "`nMIG4: Migrate temp_env -> env.default" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_migrate_test4_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

@'
{
  "temp_env": {
    "API_KEY": "secret123",
    "DEBUG": "true"
  }
}
'@ | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' migrate" 2>&1 | Out-String
$content = Get-Content "$tempDir\.dev_env.json" -Raw | ConvertFrom-Json

$passed = $content.env.default.API_KEY -eq "secret123" -and
          $content.env.default.DEBUG -eq "true" -and
          -not ($content.PSObject.Properties.Name -contains "temp_env")
Write-TestResult "MIG4" "Converts temp_env to env.default" $passed

Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Test 5: Migrate temp_env_N to env.<N>
Write-Host "`nMIG5: Migrate temp_env_N -> env.N" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_migrate_test5_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

@'
{
  "temp_env": { "DEFAULT": "val" },
  "temp_env_1": { "PROFILE1": "val1" },
  "temp_env_2": { "PROFILE2": "val2" }
}
'@ | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' migrate" 2>&1 | Out-String
$content = Get-Content "$tempDir\.dev_env.json" -Raw | ConvertFrom-Json

$passed = $content.env.default.DEFAULT -eq "val" -and
          $content.env."1".PROFILE1 -eq "val1" -and
          $content.env."2".PROFILE2 -eq "val2"
Write-TestResult "MIG5" "Converts temp_env_N to env.N" $passed

Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Test 6: Already v2 - no changes
Write-Host "`nMIG6: Already v2 - no changes" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_migrate_test6_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

@'
{
  "commands": { "build": "echo build" },
  "env": { "default": { "VAR": "val" } }
}
'@ | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' migrate" 2>&1 | Out-String
$passed = $output -match "already" -or $output -match "v2" -or $output -match "nothing"
Write-TestResult "MIG6" "Detects already v2 format" $passed "Output: $output"

Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Test 7: Preserves other fields (gateway, etc)
Write-Host "`nMIG7: Preserves other fields" -ForegroundColor Cyan
$tempDir = Join-Path $env:TEMP "i_migrate_test7_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

@'
{
  "quick_command": { "build": "echo build" },
  "gateway_url": "ws://localhost:7171",
  "custom_field": "preserved"
}
'@ | Out-File "$tempDir\.dev_env.json" -Encoding UTF8

$output = & powershell -NoProfile -Command "Set-Location '$tempDir'; & '$iScript' migrate" 2>&1 | Out-String
$content = Get-Content "$tempDir\.dev_env.json" -Raw | ConvertFrom-Json

$passed = $content.gateway_url -eq "ws://localhost:7171" -and
          $content.custom_field -eq "preserved"
Write-TestResult "MIG7" "Preserves unrelated fields" $passed

Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-TestSummary "Migrate Tests"
