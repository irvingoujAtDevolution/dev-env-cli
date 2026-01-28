# test_help.ps1 - Help system tests

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$testDir\TestHelper.ps1"

Reset-TestCounters

Write-Host "Help Tests" -ForegroundColor Yellow
Write-Host "==========" -ForegroundColor Yellow
Write-Host ""

$iScript = Join-Path (Get-ScriptPath) "i.ps1"

# H1: Main help with --help
Write-Host "H1: Main help (--help)" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' --help" 2>&1 | Out-String
$passed = $output -match "Development Environment CLI" -and $output -match "COMMANDS" -and $output -match "EXAMPLES"
Write-TestResult "H1" "Shows main help with --help" $passed

# H2: Main help with -h
Write-Host "`nH2: Main help (-h)" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' -h" 2>&1 | Out-String
$passed = $output -match "Development Environment CLI"
Write-TestResult "H2" "Shows main help with -h" $passed

# H3: Main help with 'help'
Write-Host "`nH3: Main help (help command)" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' help" 2>&1 | Out-String
$passed = $output -match "Development Environment CLI"
Write-TestResult "H3" "Shows main help with help command" $passed

# H4: Run help
Write-Host "`nH4: Run help" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' run --help" 2>&1 | Out-String
$passed = $output -match "Run Commands" -and $output -match "COMMAND TYPES"
Write-TestResult "H4" "Shows run help" $passed

# H5: Set help
Write-Host "`nH5: Set help" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' set --help" 2>&1 | Out-String
$passed = $output -match "Set Environment Variables" -and $output -match "CONFIG EXAMPLE"
Write-TestResult "H5" "Shows set help" $passed

# H6: List help
Write-Host "`nH6: List help" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' list --help" 2>&1 | Out-String
$passed = $output -match "List Commands" -and $output -match "Env Profiles"
Write-TestResult "H6" "Shows list help" $passed

# H7: Add help
Write-Host "`nH7: Add help" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' add --help" 2>&1 | Out-String
$passed = $output -match "Add Commands" -and $output -match "i add cmd --help"
Write-TestResult "H7" "Shows add help" $passed

# H8: Add cmd help
Write-Host "`nH8: Add cmd help" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' add cmd --help" 2>&1 | Out-String
$passed = $output -match "Add Commands" -and $output -match "ENV VALUES" -and $output -match "cwd="
Write-TestResult "H8" "Shows add cmd help" $passed

# H9: Add env help
Write-Host "`nH9: Add env help" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' add env --help" 2>&1 | Out-String
$passed = $output -match "Add Env Profiles" -and $output -match "KEY=VALUE"
Write-TestResult "H9" "Shows add env help" $passed

# H10: Init help
Write-Host "`nH10: Init help" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' init --help" 2>&1 | Out-String
$passed = $output -match "Initialize Config" -and $output -match "TEMPLATE STRUCTURE"
Write-TestResult "H10" "Shows init help" $passed

# H11: Migrate help
Write-Host "`nH11: Migrate help" -ForegroundColor Cyan
$output = & powershell -NoProfile -Command "& '$iScript' migrate --help" 2>&1 | Out-String
$passed = $output -match "Migrate v1 Config" -and $output -match "TRANSFORMATIONS"
Write-TestResult "H11" "Shows migrate help" $passed

Write-TestSummary "Help Tests"
