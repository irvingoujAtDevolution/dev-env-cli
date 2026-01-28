# i.ps1 - Unified development environment CLI
#
# Usage:
#   i run <cmd> [args]   - Run a quick command
#   i <cmd> [args]       - Shortcut for 'i run <cmd>'
#   i set env [N]        - Set environment variables from temp_env or temp_env_N
#   i list cmd           - List available quick commands
#   i list env           - List available environment configs
#   i init               - Initialize .dev_env.json in current directory
#   i help               - Show this help

param(
    [Parameter(Position = 0)]
    [string]$Verb,

    [Parameter(Position = 1, ValueFromRemainingArguments)]
    [string[]]$Rest
)

# Load modules
. "$PSScriptRoot\lib\i\Config.ps1"
. "$PSScriptRoot\lib\i\Run.ps1"
. "$PSScriptRoot\lib\i\Env.ps1"
. "$PSScriptRoot\lib\i\Init.ps1"

function Show-Help {
    Write-Host "i - Development environment CLI" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  i run <cmd> [args]   Run a quick command"
    Write-Host "  i <cmd> [args]       Shortcut for 'i run <cmd>'"
    Write-Host "  i set env [N]        Set env vars (temp_env or temp_env_N)"
    Write-Host "  i list cmd           List available commands"
    Write-Host "  i list env           List available env configs"
    Write-Host "  i init               Initialize .dev_env.json"
    Write-Host "  i help               Show this help"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  i build              Run the 'build' command"
    Write-Host "  i build --release    Run 'build' with extra args"
    Write-Host "  i set env            Load default environment"
    Write-Host "  i set env 1          Load temp_env_1"
    Write-Host "  i list cmd           Show available commands"
}

# Route based on verb
switch ($Verb) {
    "run" {
        $cmdName = if ($Rest.Count -gt 0) { $Rest[0] } else { $null }
        $cmdArgs = if ($Rest.Count -gt 1) { $Rest[1..($Rest.Count - 1)] } else { @() }
        Invoke-QuickCommand -Name $cmdName -ExtraArgs $cmdArgs
    }

    "set" {
        if ($Rest.Count -eq 0 -or $Rest[0] -ne "env") {
            Write-Host "Usage: i set env [N]" -ForegroundColor Red
            exit 1
        }
        $number = if ($Rest.Count -gt 1) { $Rest[1] } else { $null }
        Set-DevEnv -Number $number
    }

    "list" {
        if ($Rest.Count -eq 0) {
            Write-Host "Usage: i list <cmd|env>" -ForegroundColor Red
            Write-Host "  i list cmd   - List quick commands"
            Write-Host "  i list env   - List environment configs"
            exit 1
        }

        switch ($Rest[0]) {
            "cmd" { Show-QuickCommands }
            "command" { Show-QuickCommands }
            "commands" { Show-QuickCommands }
            "env" { Show-EnvConfigs }
            default {
                Write-Host "Unknown: '$($Rest[0])'. Use 'cmd' or 'env'." -ForegroundColor Red
                exit 1
            }
        }
    }

    "init" {
        Initialize-DevEnv
    }

    "help" {
        Show-Help
    }

    "" {
        Show-Help
    }

    default {
        # Shortcut: treat verb as command name
        Invoke-QuickCommand -Name $Verb -ExtraArgs $Rest
    }
}
