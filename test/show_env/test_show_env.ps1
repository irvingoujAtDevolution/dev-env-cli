# Test script for show_env.ps1
param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent (Split-Path -Parent $testDir)
$showEnvScript = Join-Path $scriptDir "show_env.ps1"

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

Write-Host "Running show_env.ps1 tests..." -ForegroundColor Yellow
Write-Host "Test directory: $testDir" -ForegroundColor Gray
Write-Host ""

try {
    # Test 1: Show all environment configuration (no filter)
    Write-Host "Test 1: Show all configuration" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $showEnvScript 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output:`n$output" -ForegroundColor Gray
    }
    
    $test1_1 = $output -match "quick_command :"
    $test1_2 = $output -match "private_key_file :"
    $test1_3 = $output -match "gateway_websocket_url :"
    $test1_4 = $output -match "target :"
    $test1_5 = $output -match "temp_env :"
    $test1_6 = $output -match "krb_realm :"
    
    Write-TestResult "Shows quick_command section" $test1_1
    Write-TestResult "Shows private_key_file" $test1_2
    Write-TestResult "Shows gateway_websocket_url" $test1_3
    Write-TestResult "Shows target" $test1_4
    Write-TestResult "Shows temp_env section" $test1_5
    Write-TestResult "Shows krb_realm" $test1_6

    # Test 2: Filter by specific property name (exact match)
    Write-Host "`nTest 2: Filter by 'target'" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $showEnvScript -Name "target" 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output:`n$output" -ForegroundColor Gray
    }
    
    $test2_1 = $output -match "target : ssh"
    $test2_2 = -not ($output -match "quick_command")  # Should not show other properties
    $test2_3 = -not ($output -match "private_key_file")
    
    Write-TestResult "Shows target value" $test2_1
    Write-TestResult "Filters out quick_command" $test2_2
    Write-TestResult "Filters out private_key_file" $test2_3

    # Test 3: Filter by partial match
    Write-Host "`nTest 3: Filter by 'temp'" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $showEnvScript -Name "temp" 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output:`n$output" -ForegroundColor Gray
    }
    
    $test3_1 = $output -match "temp_env :"
    $test3_2 = $output -match "temp_env_1 :"
    $test3_3 = $output -match "API_KEY"
    $test3_4 = $output -match "DATABASE_URL"
    $test3_5 = -not ($output -match "target")  # Should not show target
    
    Write-TestResult "Shows temp_env section" $test3_1
    Write-TestResult "Shows temp_env_1 section" $test3_2
    Write-TestResult "Shows temp_env content (API_KEY)" $test3_3
    Write-TestResult "Shows temp_env_1 content (DATABASE_URL)" $test3_4
    Write-TestResult "Filters out non-matching properties" $test3_5

    # Test 4: Filter by 'host' (should match multiple host properties)
    Write-Host "`nTest 4: Filter by 'host'" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $showEnvScript -Name "host" 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output:`n$output" -ForegroundColor Gray
    }
    
    $test4_1 = $output -match "ssh_destination_host"
    $test4_2 = $output -match "rdp_destination_host"
    $test4_3 = $output -match "primary:22"
    $test4_4 = $output -match "primary:3389"
    $test4_5 = -not ($output -match "temp_env")
    
    Write-TestResult "Shows ssh_destination_host" $test4_1
    Write-TestResult "Shows rdp_destination_host" $test4_2
    Write-TestResult "Shows SSH host value" $test4_3
    Write-TestResult "Shows RDP host value" $test4_4
    Write-TestResult "Filters out non-host properties" $test4_5

    # Test 5: Filter with no matches
    Write-Host "`nTest 5: Filter with no matches" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $showEnvScript -Name "nonexistent" 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output:`n$output" -ForegroundColor Gray
    }
    
    $test5_1 = $output.Trim() -eq ""  # Should produce no output
    Write-TestResult "No output for non-matching filter" $test5_1

    # Test 6: Complex object display (quick_command)
    Write-Host "`nTest 6: Complex object display" -ForegroundColor Cyan
    
    $output = & powershell -NoProfile -File $showEnvScript -Name "quick_command" 2>&1 | Out-String
    if ($Verbose) {
        Write-Host "Output:`n$output" -ForegroundColor Gray
    }
    
    $test6_1 = $output -match "quick_command :"
    $test6_2 = $output -match "    test : echo 'test command'"
    $test6_3 = $output -match "    build :"
    $test6_4 = $output -match "        cwd :"
    $test6_5 = $output -match "        command : dotnet"
    
    Write-TestResult "Shows quick_command header" $test6_1
    Write-TestResult "Shows simple command with indentation" $test6_2
    Write-TestResult "Shows complex command header" $test6_3
    Write-TestResult "Shows nested properties with proper indentation" $test6_4
    Write-TestResult "Shows nested command value" $test6_5

    Write-Host "`nAll show_env.ps1 tests completed!" -ForegroundColor Green

} catch {
    Write-Host "Error during testing: $_" -ForegroundColor Red
    if ($Verbose) {
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
    }
} finally {
    # Restore original directory
    Set-Location $originalDir
}