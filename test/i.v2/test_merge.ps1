# test_merge.ps1 - Config merging tests (M1-M6)

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$testDir\TestHelper.ps1"

Reset-TestCounters

Write-Host "Config Merge Tests" -ForegroundColor Yellow
Write-Host "==================" -ForegroundColor Yellow
Write-Host ""

$rootDir = Get-FixturePath "root"
$appDir = Get-FixturePath "root\app"
$subDir = Get-FixturePath "root\app\sub"

# M1: Single config - only root has what we need
Write-Host "M1: Single config" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $rootDir -Arguments @("run", "root_only")
$passed = $output -match "root-only-cmd"
Write-TestResult "M1" "Single config uses local commands" $passed "Output: $output"

# M2: Parent + child merge - root has root_only, app has test
Write-Host "`nM2: Parent + child merge" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("run", "root_only")
$passed = $output -match "root-only-cmd"
Write-TestResult "M2a" "Child can access parent command" $passed "Output: $output"

$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("run", "test")
$passed = $output -match "app-test"
Write-TestResult "M2b" "Child has its own commands" $passed "Output: $output"

# M3: Child overrides parent - both have 'build'
Write-Host "`nM3: Child overrides parent" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("run", "build")
$passed = $output -match "app-build" -and -not ($output -match "root-build")
Write-TestResult "M3" "Child command overrides parent" $passed "Output: $output"

# M4: 3-level merge - sub overrides app's 'test', still has root's 'root_only'
Write-Host "`nM4: 3-level merge" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $subDir -Arguments @("run", "test")
$passed = $output -match "sub-test"
Write-TestResult "M4a" "Grandchild overrides parent command" $passed "Output: $output"

$output = Invoke-ICommand -WorkingDir $subDir -Arguments @("run", "root_only")
$passed = $output -match "root-only-cmd"
Write-TestResult "M4b" "Grandchild can access grandparent command" $passed "Output: $output"

$output = Invoke-ICommand -WorkingDir $subDir -Arguments @("run", "sub_only")
$passed = $output -match "sub-only-cmd"
Write-TestResult "M4c" "Grandchild has its own commands" $passed "Output: $output"

# M5: Env profiles merge - root has root_profile, app has dev
Write-Host "`nM5: Env profiles merge" -ForegroundColor Cyan
$output = Invoke-ICommand -WorkingDir $appDir -Arguments @("list", "env")
$passed = $output -match "root_profile" -and $output -match "dev"
Write-TestResult "M5" "Child sees both parent and own env profiles" $passed "Output: $output"

# M6: Env profile override - both have 'default', check SHARED_VAR
Write-Host "`nM6: Env profile override" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "Set-Location '$appDir'; & '$(Join-Path (Get-ScriptPath) "i.ps1")' set env; Write-Host SHARED=`$env:SHARED_VAR" 2>&1 | Out-String
$passed = $output -match "SHARED=from_app"
Write-TestResult "M6" "Child env profile overrides parent" $passed "Output: $output"

Write-TestSummary "Merge Tests"
