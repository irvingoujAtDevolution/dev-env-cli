# Run.ps1 - Quick command execution (v2)

function Show-Commands {
    <#
    .SYNOPSIS
    List all available commands from merged config.
    #>

    $config = Get-MergedConfig

    if ($config.Sources.Count -gt 0) {
        Write-Host "Sources:" -ForegroundColor Gray
        foreach ($src in $config.Sources) {
            Write-Host "  $src" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    if ($config.Commands.Count -eq 0) {
        Write-Host "No commands found." -ForegroundColor Yellow
        return
    }

    Write-Host "Commands:" -ForegroundColor Cyan
    foreach ($name in $config.Commands.Keys | Sort-Object) {
        $cmd = $config.Commands[$name]

        if ($cmd -is [string]) {
            Write-Host "  $name" -ForegroundColor White -NoNewline
            Write-Host " -> $cmd" -ForegroundColor Gray
        } else {
            $runStr = $cmd.run
            Write-Host "  $name" -ForegroundColor White -NoNewline
            Write-Host " -> $runStr" -ForegroundColor Gray
            if ($cmd.cwd) {
                Write-Host "       cwd: $($cmd.cwd)" -ForegroundColor DarkGray
            }
            if ($cmd.env) {
                $envStr = if ($cmd.env -is [string]) { $cmd.env }
                          elseif ($cmd.env -is [array]) { $cmd.env -join ", " }
                          else { "(inline)" }
                Write-Host "       env: $envStr" -ForegroundColor DarkGray
            }
        }
    }
}

function Invoke-Command {
    <#
    .SYNOPSIS
    Run a command by name with optional extra arguments.
    #>
    param(
        [string]$Name,
        [string[]]$ExtraArgs
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Show-Commands
        return
    }

    $cmd = Get-Command -Name $Name
    if ($null -eq $cmd) {
        Write-Host "Command '$Name' not found." -ForegroundColor Red
        Write-Host ""
        Show-Commands
        exit 1
    }

    $originalDir = Get-Location

    try {
        if ($cmd -is [string]) {
            # Simple string command
            $fullCommand = $cmd
            if ($ExtraArgs -and $ExtraArgs.Count -gt 0) {
                $fullCommand += " " + ($ExtraArgs -join ' ')
            }
            Write-Host "Running: $fullCommand" -ForegroundColor Cyan
            Invoke-Expression -Command $fullCommand
        }
        elseif ($cmd -is [pscustomobject]) {
            # Object command with run, cwd, env
            $runCmd = $cmd.run
            if (-not $runCmd) {
                Write-Host "Command '$Name' has no 'run' field." -ForegroundColor Red
                exit 1
            }

            # Resolve and set env vars
            if ($cmd.env) {
                $envVars = Resolve-EnvVars -EnvSpec $cmd.env
                if ($null -eq $envVars) {
                    # Error already printed
                    exit 1
                }
                foreach ($key in $envVars.Keys) {
                    Write-Host "  env: $key=$($envVars[$key])" -ForegroundColor DarkGray
                    Set-Item -Path "env:$key" -Value $envVars[$key]
                }
            }

            # Change directory if specified
            if ($cmd.cwd -and -not [string]::IsNullOrWhiteSpace($cmd.cwd)) {
                Set-Location -Path $cmd.cwd
            }

            # Build full command
            $fullCommand = $runCmd
            if ($ExtraArgs -and $ExtraArgs.Count -gt 0) {
                $fullCommand += " " + ($ExtraArgs -join ' ')
            }

            Write-Host "Running: $fullCommand" -ForegroundColor Cyan
            if ($cmd.cwd) {
                Write-Host "    cwd: $(Get-Location)" -ForegroundColor DarkGray
            }

            Invoke-Expression -Command $fullCommand
        }
        else {
            Write-Host "Unknown command format for '$Name'." -ForegroundColor Red
            exit 1
        }
    }
    finally {
        Set-Location -Path $originalDir
    }
}
