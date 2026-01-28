# i.ps1 - Unified development environment CLI (v2)
#
# Run 'i help' or 'i --help' for usage information.
# Run 'i <command> --help' for command-specific help.

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
. "$PSScriptRoot\lib\i\Add.ps1"
. "$PSScriptRoot\lib\i\Help.ps1"

# Check for top-level help flags
if ($Verb -eq "-h" -or $Verb -eq "--help" -or $Verb -eq "-help") {
    Show-MainHelp
    exit 0
}

# Route based on verb
switch ($Verb) {
    "run" {
        if (Test-HelpFlag $Rest) {
            Show-RunHelp
            exit 0
        }
        $cmdName = if ($Rest.Count -gt 0) { $Rest[0] } else { $null }
        $cmdArgs = if ($Rest.Count -gt 1) { $Rest[1..($Rest.Count - 1)] } else { @() }
        Invoke-Command -Name $cmdName -ExtraArgs $cmdArgs
    }

    "set" {
        if (Test-HelpFlag $Rest) {
            Show-SetHelp
            exit 0
        }
        if ($Rest.Count -eq 0 -or $Rest[0] -ne "env") {
            Write-Host "Usage: i set env [profile]" -ForegroundColor Red
            Write-Host "Run 'i set --help' for more information." -ForegroundColor Gray
            exit 1
        }
        $profileName = if ($Rest.Count -gt 1) { $Rest[1] } else { $null }
        Set-EnvProfile -ProfileName $profileName
    }

    "list" {
        if (Test-HelpFlag $Rest) {
            Show-ListHelp
            exit 0
        }
        if ($Rest.Count -eq 0) {
            Write-Host "Usage: i list <cmd|env>" -ForegroundColor Red
            Write-Host "Run 'i list --help' for more information." -ForegroundColor Gray
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
        if (Test-HelpFlag $Rest) {
            Show-InitHelp
            exit 0
        }
        Initialize-DevEnv
    }

    "migrate" {
        if (Test-HelpFlag $Rest) {
            Show-MigrateHelp
            exit 0
        }
        Invoke-Migration
    }

    "add" {
        if ($Rest.Count -eq 0) {
            Write-Host "Usage: i add <env|cmd> ..." -ForegroundColor Red
            Write-Host "Run 'i add --help' for more information." -ForegroundColor Gray
            exit 1
        }

        switch ($Rest[0]) {
            "env" {
                # Check for help on add env
                $envRest = if ($Rest.Count -gt 1) { $Rest[1..($Rest.Count - 1)] } else { @() }
                if (Test-HelpFlag $envRest) {
                    Show-AddEnvHelp
                    exit 0
                }
                $profileName = if ($Rest.Count -gt 1) { $Rest[1] } else { $null }
                $vars = if ($Rest.Count -gt 2) { $Rest[2..($Rest.Count - 1)] } else { @() }
                Add-EnvProfile -ProfileName $profileName -Vars $vars
            }
            "cmd" {
                # Check for help on add cmd
                $cmdRest = if ($Rest.Count -gt 1) { $Rest[1..($Rest.Count - 1)] } else { @() }
                if (Test-HelpFlag $cmdRest) {
                    Show-AddCmdHelp
                    exit 0
                }
                $cmdName = if ($Rest.Count -gt 1) { $Rest[1] } else { $null }
                $cmdArgs = if ($Rest.Count -gt 2) { $Rest[2..($Rest.Count - 1)] } else { @() }
                Add-Command -Name $cmdName -Arguments $cmdArgs
            }
            { $_ -eq "-h" -or $_ -eq "--help" -or $_ -eq "-help" -or $_ -eq "help" } {
                Show-AddHelp
                exit 0
            }
            default {
                Write-Host "Unknown: '$($Rest[0])'. Use 'env' or 'cmd'." -ForegroundColor Red
                exit 1
            }
        }
    }

    "help" {
        Show-MainHelp
    }

    "" {
        Show-MainHelp
    }

    default {
        # Check if it's a help flag
        if ($Verb -eq "-h" -or $Verb -eq "--help") {
            Show-MainHelp
            exit 0
        }
        # Shortcut: treat verb as command name
        Invoke-Command -Name $Verb -ExtraArgs $Rest
    }
}
