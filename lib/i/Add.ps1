# Add.ps1 - Add commands and env profiles

function Add-EnvProfile {
    <#
    .SYNOPSIS
    Add or update an env profile with KEY=VALUE pairs.

    Usage: i add env <profile> "KEY=VALUE" ...
    #>
    param(
        [string]$ProfileName,
        [string[]]$Vars
    )

    if ([string]::IsNullOrWhiteSpace($ProfileName)) {
        Write-Host "Usage: i add env <profile> ""KEY=VALUE"" ..." -ForegroundColor Red
        exit 1
    }

    if ($null -eq $Vars -or $Vars.Count -eq 0) {
        Write-Host "Usage: i add env <profile> ""KEY=VALUE"" ..." -ForegroundColor Red
        Write-Host "  Example: i add env dev ""DEBUG=true"" ""LOG_LEVEL=verbose""" -ForegroundColor Gray
        exit 1
    }

    # Parse KEY=VALUE pairs
    $envVars = @{}
    foreach ($var in $Vars) {
        if ($var -notmatch "=") {
            Write-Host "Invalid format: '$var'" -ForegroundColor Red
            Write-Host "Expected: KEY=VALUE" -ForegroundColor Gray
            exit 1
        }
        $eqIndex = $var.IndexOf("=")
        $key = $var.Substring(0, $eqIndex)
        $value = $var.Substring($eqIndex + 1)
        $envVars[$key] = $value
    }

    # Load or create config
    $configPath = Join-Path (Get-Location) ".dev_env.json"
    $config = Get-OrCreateConfig -ConfigPath $configPath

    # Ensure env section exists
    if (-not ($config.PSObject.Properties.Name -contains "env")) {
        $config | Add-Member -MemberType NoteProperty -Name "env" -Value ([pscustomobject]@{})
    }

    # Get or create profile
    if ($config.env.PSObject.Properties.Name -contains $ProfileName) {
        # Merge with existing
        foreach ($key in $envVars.Keys) {
            if ($config.env.$ProfileName.PSObject.Properties.Name -contains $key) {
                $config.env.$ProfileName.$key = $envVars[$key]
            } else {
                $config.env.$ProfileName | Add-Member -MemberType NoteProperty -Name $key -Value $envVars[$key]
            }
        }
    } else {
        # Create new profile
        $config.env | Add-Member -MemberType NoteProperty -Name $ProfileName -Value ([pscustomobject]$envVars)
    }

    # Save
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8

    Write-Host ""
    Write-Host "  Added to env.$ProfileName :" -ForegroundColor Green
    foreach ($key in $envVars.Keys) {
        Write-Host "    $key=$($envVars[$key])" -ForegroundColor White
    }
    Write-Host ""
}

function Add-Command {
    <#
    .SYNOPSIS
    Add a command to the config.

    Usage: i add cmd <name> "<run>" [cwd=<path>] [env=<profiles|vars>]
    #>
    param(
        [string]$Name,
        [string[]]$Arguments
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-Host "Usage: i add cmd <name> ""<run>"" [cwd=<path>] [env=<value>]" -ForegroundColor Red
        exit 1
    }

    if ($null -eq $Arguments -or $Arguments.Count -eq 0) {
        Write-Host "Usage: i add cmd <name> ""<run>"" [cwd=<path>] [env=<value>]" -ForegroundColor Red
        Write-Host "  Example: i add cmd build ""dotnet build""" -ForegroundColor Gray
        Write-Host "  Example: i add cmd dev ""npm start"" cwd=./frontend env=dev" -ForegroundColor Gray
        exit 1
    }

    # Parse arguments
    $runCommand = $null
    $cwd = $null
    $envSpec = $null

    foreach ($arg in $Arguments) {
        if ($arg -match "^cwd=(.+)$") {
            $cwd = $Matches[1]
        }
        elseif ($arg -match "^env=(.+)$") {
            $envSpec = $Matches[1]
        }
        elseif ($null -eq $runCommand) {
            $runCommand = $arg
        }
    }

    if ([string]::IsNullOrWhiteSpace($runCommand)) {
        Write-Host "Missing run command." -ForegroundColor Red
        Write-Host "Usage: i add cmd <name> ""<run>"" [cwd=<path>] [env=<value>]" -ForegroundColor Gray
        exit 1
    }

    # Load or create config
    $configPath = Join-Path (Get-Location) ".dev_env.json"
    $config = Get-OrCreateConfig -ConfigPath $configPath

    # Ensure commands section exists
    if (-not ($config.PSObject.Properties.Name -contains "commands")) {
        $config | Add-Member -MemberType NoteProperty -Name "commands" -Value ([pscustomobject]@{})
    }

    # Build command object
    $cmdObj = $null

    if ($null -eq $cwd -and $null -eq $envSpec) {
        # Simple string command
        $cmdObj = $runCommand
    } else {
        # Object command
        $cmdObj = [pscustomobject]@{
            run = $runCommand
        }

        if ($cwd) {
            $cmdObj | Add-Member -MemberType NoteProperty -Name "cwd" -Value $cwd
        }

        if ($envSpec) {
            $parsedEnv = Parse-EnvSpec -EnvSpec $envSpec -Config $config
            if ($null -eq $parsedEnv) {
                # Error already printed
                exit 1
            }
            $cmdObj | Add-Member -MemberType NoteProperty -Name "env" -Value $parsedEnv
        }
    }

    # Add or replace command
    if ($config.commands.PSObject.Properties.Name -contains $Name) {
        $config.commands.$Name = $cmdObj
    } else {
        $config.commands | Add-Member -MemberType NoteProperty -Name $Name -Value $cmdObj
    }

    # Save
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8

    Write-Host ""
    Write-Host "  Added command: " -ForegroundColor Green -NoNewline
    Write-Host "$Name" -ForegroundColor White
    Write-Host "    run: $runCommand" -ForegroundColor Gray
    if ($cwd) {
        Write-Host "    cwd: $cwd" -ForegroundColor Gray
    }
    if ($envSpec) {
        Write-Host "    env: $envSpec" -ForegroundColor Gray
    }
    Write-Host ""
}

function Parse-EnvSpec {
    <#
    .SYNOPSIS
    Parse env= value into profile reference(s) or inline object.

    - "dev" -> profile ref (string)
    - "default,dev" -> profile refs (array)
    - "KEY=val,KEY2=val2" -> inline object
    #>
    param(
        [string]$EnvSpec,
        $Config
    )

    # Check if it contains = (inline vars)
    if ($EnvSpec -match "^[^,]+=") {
        # Inline vars: KEY=val,KEY2=val2
        $vars = @{}
        $parts = $EnvSpec -split ","

        foreach ($part in $parts) {
            if ($part -match "^([^=]+)=(.*)$") {
                $key = $Matches[1]
                $value = $Matches[2]
                $vars[$key] = $value
            }
        }

        return [pscustomobject]$vars
    }
    else {
        # Profile reference(s)
        $profiles = $EnvSpec -split ","

        # Validate profiles exist
        foreach ($profile in $profiles) {
            $profileExists = $Config.PSObject.Properties.Name -contains "env" -and
                           $Config.env.PSObject.Properties.Name -contains $profile

            if (-not $profileExists) {
                Write-Host "Env profile '$profile' does not exist." -ForegroundColor Red
                Write-Host "Available profiles:" -ForegroundColor Gray
                if ($Config.PSObject.Properties.Name -contains "env") {
                    foreach ($p in $Config.env.PSObject.Properties.Name) {
                        Write-Host "  $p" -ForegroundColor White
                    }
                } else {
                    Write-Host "  (none)" -ForegroundColor DarkGray
                }
                return $null
            }
        }

        if ($profiles.Count -eq 1) {
            return $profiles[0]
        } else {
            return $profiles
        }
    }
}

function Get-OrCreateConfig {
    param([string]$ConfigPath)

    if (Test-Path $ConfigPath) {
        try {
            return Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        } catch {
            Write-Host "Failed to parse config: $_" -ForegroundColor Red
            exit 1
        }
    } else {
        # Create new config
        return [pscustomobject]@{
            commands = [pscustomobject]@{}
            env = [pscustomobject]@{}
        }
    }
}
