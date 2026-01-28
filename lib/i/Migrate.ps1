# Migrate.ps1 - Migrate v1 config to v2 format

function Invoke-Migration {
    <#
    .SYNOPSIS
    Migrate .dev_env.json from v1 to v2 format.

    v1 -> v2 transformations:
    - quick_command -> commands
    - command + args -> run
    - env array [{"K":"V"}] -> env object {"K":"V"}
    - temp_env -> env.default
    - temp_env_N -> env.N
    #>

    $configPath = Join-Path (Get-Location) ".dev_env.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "No .dev_env.json found in current directory." -ForegroundColor Red
        exit 1
    }

    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "Failed to parse .dev_env.json: $_" -ForegroundColor Red
        exit 1
    }

    # Check if already v2
    $hasCommands = $config.PSObject.Properties.Name -contains "commands"
    $hasQuickCommand = $config.PSObject.Properties.Name -contains "quick_command"
    $hasTempEnv = $config.PSObject.Properties.Name -match "^temp_env"

    if ($hasCommands -and -not $hasQuickCommand -and -not $hasTempEnv) {
        Write-Host "Config is already v2 format. Nothing to migrate." -ForegroundColor Yellow
        return
    }

    Write-Host "Migrating: $configPath" -ForegroundColor Cyan
    $changes = @()

    # Migrate quick_command -> commands
    if ($hasQuickCommand) {
        $commands = @{}

        foreach ($prop in $config.quick_command.PSObject.Properties) {
            $cmdName = $prop.Name
            $cmdValue = $prop.Value

            if ($cmdValue -is [string]) {
                # String command - keep as is
                $commands[$cmdName] = $cmdValue
            }
            elseif ($cmdValue -is [pscustomobject]) {
                # Object command - transform
                $newCmd = @{}

                # command + args -> run
                if ($cmdValue.PSObject.Properties.Name -contains "command") {
                    $run = $cmdValue.command
                    if ($cmdValue.PSObject.Properties.Name -contains "args" -and $cmdValue.args.Count -gt 0) {
                        $run += " " + ($cmdValue.args -join " ")
                    }
                    $newCmd["run"] = $run
                }

                # cwd - keep if not empty
                if ($cmdValue.PSObject.Properties.Name -contains "cwd" -and
                    -not [string]::IsNullOrWhiteSpace($cmdValue.cwd)) {
                    $newCmd["cwd"] = $cmdValue.cwd
                }

                # env array -> env object
                if ($cmdValue.PSObject.Properties.Name -contains "env" -and
                    $cmdValue.env -is [array] -and $cmdValue.env.Count -gt 0) {
                    $envObj = @{}
                    foreach ($envItem in $cmdValue.env) {
                        foreach ($envProp in $envItem.PSObject.Properties) {
                            $envObj[$envProp.Name] = $envProp.Value
                        }
                    }
                    if ($envObj.Count -gt 0) {
                        $newCmd["env"] = $envObj
                    }
                }

                $commands[$cmdName] = [pscustomobject]$newCmd
            }
        }

        # Remove old, add new
        $config.PSObject.Properties.Remove("quick_command")
        $config | Add-Member -MemberType NoteProperty -Name "commands" -Value ([pscustomobject]$commands)
        $changes += "quick_command -> commands"
    }

    # Migrate temp_env* -> env
    $envProfiles = @{}
    $tempEnvProps = $config.PSObject.Properties | Where-Object { $_.Name -match "^temp_env(_\d+)?$" }

    if ($tempEnvProps.Count -gt 0) {
        foreach ($prop in $tempEnvProps) {
            $profileName = if ($prop.Name -eq "temp_env") {
                "default"
            } else {
                $prop.Name -replace "temp_env_", ""
            }
            $envProfiles[$profileName] = $prop.Value
            $config.PSObject.Properties.Remove($prop.Name)
        }

        # Merge with existing env if present
        if ($config.PSObject.Properties.Name -contains "env") {
            foreach ($key in $envProfiles.Keys) {
                $config.env | Add-Member -MemberType NoteProperty -Name $key -Value $envProfiles[$key] -Force
            }
        } else {
            $config | Add-Member -MemberType NoteProperty -Name "env" -Value ([pscustomobject]$envProfiles)
        }
        $changes += "temp_env* -> env profiles"
    }

    # Write back
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8

    Write-Host ""
    Write-Host "Migration complete:" -ForegroundColor Green
    foreach ($change in $changes) {
        Write-Host "  - $change" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Backup recommended. Review the migrated config." -ForegroundColor Gray
}
