# test_worktree.ps1 - Git worktree resolution tests

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$testDir\TestHelper.ps1"

Reset-TestCounters

Write-Host "Worktree Resolution Tests" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow
Write-Host ""

$iScript = Join-Path (Get-ScriptPath) "i.ps1"

# Set up: create a real git repo with a worktree
$baseDir = Join-Path $env:TEMP "i_worktree_test_$(Get-Random)"
$mainRepo = Join-Path $baseDir "main-repo"
$linkedWt = Join-Path $baseDir "linked-wt"

try {
    # Create main repo with a commit
    New-Item -ItemType Directory -Path $mainRepo -Force | Out-Null
    Push-Location $mainRepo
    git init --quiet 2>&1 | Out-Null
    "init" | Out-File "readme.txt" -Encoding UTF8
    git add . 2>&1 | Out-Null
    git commit -m "init" --quiet 2>&1 | Out-Null

    # Add a config in main repo
    @{
        commands = @{
            from_main = "echo main-worktree-cmd"
            shared = "echo main-shared"
        }
        env = @{
            default = @{
                MAIN_VAR = "from_main"
                SHARED = "from_main"
            }
            main_only = @{
                MAIN_ONLY_VAR = "main_only_value"
            }
        }
    } | ConvertTo-Json -Depth 10 | Out-File ".dev_env.json" -Encoding UTF8

    # Create a branch for the worktree
    git branch feature-branch --quiet 2>&1 | Out-Null

    # Create linked worktree
    git worktree add $linkedWt feature-branch --quiet 2>&1 | Out-Null
    Pop-Location

    # WT1: Linked worktree inherits main worktree config
    Write-Host "WT1: Linked worktree inherits main config" -ForegroundColor Cyan
    $output = & powershell -NoProfile -Command "Set-Location '$linkedWt'; & '$iScript' list cmd" 2>&1 | Out-String
    $passed = $output -match "from_main"
    Write-TestResult "WT1" "Linked worktree sees main repo commands" $passed "Output: $output"

    # WT2: Linked worktree can run main worktree command
    Write-Host "`nWT2: Run command from main worktree" -ForegroundColor Cyan
    $output = & powershell -NoProfile -Command "Set-Location '$linkedWt'; & '$iScript' run from_main" 2>&1 | Out-String
    $passed = $output -match "main-worktree-cmd"
    Write-TestResult "WT2" "Runs command from main worktree" $passed "Output: $output"

    # WT3: Linked worktree env profile from main
    Write-Host "`nWT3: Env profile from main worktree" -ForegroundColor Cyan
    $output = & powershell -NoProfile -Command "Set-Location '$linkedWt'; & '$iScript' set env main_only; Write-Host CHECK=`$env:MAIN_ONLY_VAR" 2>&1 | Out-String
    $passed = $output -match "CHECK=main_only_value"
    Write-TestResult "WT3" "Can use env profile from main worktree" $passed "Output: $output"

    # WT4: Linked worktree local config overrides main
    Write-Host "`nWT4: Local config overrides main" -ForegroundColor Cyan
    @{
        commands = @{
            shared = "echo linked-shared"
            local_only = "echo linked-only"
        }
        env = @{
            default = @{
                SHARED = "from_linked"
                LOCAL_VAR = "local_value"
            }
        }
    } | ConvertTo-Json -Depth 10 | Out-File "$linkedWt\.dev_env.json" -Encoding UTF8

    $output = & powershell -NoProfile -Command "Set-Location '$linkedWt'; & '$iScript' run shared" 2>&1 | Out-String
    $passed = $output -match "linked-shared"
    Write-TestResult "WT4a" "Local command overrides main" $passed "Output: $output"

    $output = & powershell -NoProfile -Command "Set-Location '$linkedWt'; & '$iScript' run from_main" 2>&1 | Out-String
    $passed = $output -match "main-worktree-cmd"
    Write-TestResult "WT4b" "Still has main-only commands" $passed "Output: $output"

    $output = & powershell -NoProfile -Command "Set-Location '$linkedWt'; & '$iScript' run local_only" 2>&1 | Out-String
    $passed = $output -match "linked-only"
    Write-TestResult "WT4c" "Has local-only commands" $passed "Output: $output"

    # WT5: Env override from linked worktree
    Write-Host "`nWT5: Env override from linked worktree" -ForegroundColor Cyan
    $output = & powershell -NoProfile -Command "Set-Location '$linkedWt'; & '$iScript' set env; Write-Host SHARED=`$env:SHARED; Write-Host LOCAL=`$env:LOCAL_VAR; Write-Host MAIN=`$env:MAIN_VAR" 2>&1 | Out-String
    $passed = $output -match "SHARED=from_linked" -and $output -match "LOCAL=local_value" -and $output -match "MAIN=from_main"
    Write-TestResult "WT5" "Linked env overrides main, main vars inherited" $passed "Output: $output"

    # WT6: Main worktree shows in sources
    Write-Host "`nWT6: Main worktree shown in sources" -ForegroundColor Cyan
    $output = & powershell -NoProfile -Command "Set-Location '$linkedWt'; & '$iScript' list cmd" 2>&1 | Out-String
    $mainRepoEscaped = [regex]::Escape($mainRepo)
    $passed = $output -match $mainRepoEscaped -or $output -match "main-repo"
    Write-TestResult "WT6" "Sources include main worktree path" $passed "Output: $output"

    # WT7: Main worktree works normally (no double-loading)
    Write-Host "`nWT7: Main worktree works normally" -ForegroundColor Cyan
    $output = & powershell -NoProfile -Command "Set-Location '$mainRepo'; & '$iScript' list cmd" 2>&1 | Out-String
    # Should not have duplicate entries
    $matchCount = ([regex]::Matches($output, "from_main")).Count
    $passed = $matchCount -eq 1
    Write-TestResult "WT7" "Main worktree doesn't double-load" $passed "from_main count: $matchCount"

    # WT8: Subdirectory in linked worktree
    Write-Host "`nWT8: Subdirectory in linked worktree" -ForegroundColor Cyan
    $subDir = Join-Path $linkedWt "subdir"
    New-Item -ItemType Directory -Path $subDir -Force | Out-Null
    $output = & powershell -NoProfile -Command "Set-Location '$subDir'; & '$iScript' list cmd" 2>&1 | Out-String
    $passed = $output -match "from_main" -and $output -match "local_only"
    Write-TestResult "WT8" "Subdir in linked worktree sees both configs" $passed "Output: $output"

} finally {
    # Cleanup
    Push-Location $env:TEMP
    if (Test-Path $linkedWt) {
        Push-Location $mainRepo
        git worktree remove $linkedWt --force 2>&1 | Out-Null
        Pop-Location
    }
    Remove-Item -Path $baseDir -Recurse -Force -ErrorAction SilentlyContinue
    Pop-Location
}

Write-TestSummary "Worktree Tests"
