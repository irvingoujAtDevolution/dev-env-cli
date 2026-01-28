# i.ps1 - Unified development environment CLI (v2)
#
# Usage:
#   i run <cmd> [args]   - Run a command
#   i <cmd> [args]       - Shortcut for 'i run <cmd>'
#   i set env [profile]  - Set env vars from profile (default: 'default')
#   i list cmd           - List available commands
#   i list env           - List available env profiles
#   i init               - Initialize .dev_env.json
#   i migrate            - Migrate v1 config to v2 format
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
. "$PSScriptRoot\lib\i\Migrate.ps1"

function Show-Help {
    Write-Host "i - Development environment CLI (v2)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  i run <cmd> [args]   Run a command"
    Write-Host "  i <cmd> [args]       Shortcut for 'i run <cmd>'"
    Write-Host "  i set env [profile]  Set env vars (default: 'default')"
    Write-Host "  i list cmd           List available commands"
    Write-Host "  i list env           List available env profiles"
    Write-Host "  i init               Initialize .dev_env.json"
    Write-Host "  i migrate            Migrate v1 config to v2"
    Write-Host "  i help               Show this help"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  i build              Run the 'build' command"
    Write-Host "  i build --release    Run 'build' with extra args"
    Write-Host "  i set env            Load 'default' env profile"
    Write-Host "  i set env dev        Load 'dev' env profile"
    Write-Host "  i list cmd           Show available commands"
    Write-Host ""
    Write-Host "Config Structure:" -ForegroundColor Yellow
    Write-Host '  {
    "commands": {
      "build": "dotnet build",
      "dev": { "run": "npm start", "env": "dev" }
    },
    "env": {
      "default": { "DEBUG": "false" },
      "dev": { "DEBUG": "true" }
    }
  }'
}

# Route based on verb
switch ($Verb) {
    "run" {
        $cmdName = if ($Rest.Count -gt 0) { $Rest[0] } else { $null }
        $cmdArgs = if ($Rest.Count -gt 1) { $Rest[1..($Rest.Count - 1)] } else { @() }
        Invoke-Command -Name $cmdName -ExtraArgs $cmdArgs
    }

    "set" {
        if ($Rest.Count -eq 0 -or $Rest[0] -ne "env") {
            Write-Host "Usage: i set env [profile]" -ForegroundColor Red
            exit 1
        }
        $profileName = if ($Rest.Count -gt 1) { $Rest[1] } else { $null }
        Set-EnvProfile -ProfileName $profileName
    }

    "list" {
        if ($Rest.Count -eq 0) {
            Write-Host "Usage: i list <cmd|env>" -ForegroundColor Red
            Write-Host "  i list cmd   - List commands"
            Write-Host "  i list env   - List env profiles"
            exit 1
        }

        switch ($Rest[0]) {
            "cmd" { Show-Commands }
            "command" { Show-Commands }
            "commands" { Show-Commands }
            "env" { Show-EnvProfiles }
            default {
                Write-Host "Unknown: '$($Rest[0])'. Use 'cmd' or 'env'." -ForegroundColor Red
                exit 1
            }
        }
    }

    "init" {
        Initialize-DevEnv
    }

    "migrate" {
        Invoke-Migration
    }

    "help" {
        Show-Help
    }

    "" {
        Show-Help
    }

    default {
        # Shortcut: treat verb as command name
        Invoke-Command -Name $Verb -ExtraArgs $Rest
    }
}
