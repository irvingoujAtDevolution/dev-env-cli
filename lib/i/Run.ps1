# Run.ps1 - Quick command execution (v2)

function Show-Commands {
    <#
    .SYNOPSIS
    List all available commands from merged config.
    #>

    $config = Get-MergedConfig

    if ($config.Commands.Count -eq 0) {
        Write-Host "No commands found." -ForegroundColor Yellow
        return
    }

    # Header
    Write-Host ""
    Write-Host "  COMMANDS" -ForegroundColor Cyan
    Write-Host "  --------" -ForegroundColor DarkGray

    # Calculate max name length for alignment
    $maxLen = ($config.Commands.Keys | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
    $maxLen = [Math]::Max($maxLen, 10)

    foreach ($name in $config.Commands.Keys | Sort-Object) {
        $cmd = $config.Commands[$name]
        $padding = " " * ($maxLen - $name.Length)

        if ($cmd -is [string]) {
            $displayCmd = if ($cmd.Length -gt 50) { $cmd.Substring(0, 47) + "..." } else { $cmd }
            Write-Host "  $name$padding  " -ForegroundColor White -NoNewline
            Write-Host "$displayCmd" -ForegroundColor Gray
        } else {
            $runStr = $cmd.run
            $displayCmd = if ($runStr.Length -gt 50) { $runStr.Substring(0, 47) + "..." } else { $runStr }
            Write-Host "  $name$padding  " -ForegroundColor White -NoNewline
            Write-Host "$displayCmd" -ForegroundColor Gray

            # Show details with tree-like indent
            $detailPad = " " * ($maxLen + 4)
            if ($cmd.cwd) {
                Write-Host "$detailPad" -NoNewline
                Write-Host "cwd: " -ForegroundColor DarkGray -NoNewline
                Write-Host "$($cmd.cwd)" -ForegroundColor DarkYellow
            }
            if ($cmd.env) {
                $envStr = if ($cmd.env -is [string]) { $cmd.env }
                          elseif ($cmd.env -is [array]) { $cmd.env -join ", " }
                          else { "(inline)" }
                Write-Host "$detailPad" -NoNewline
                Write-Host "env: " -ForegroundColor DarkGray -NoNewline
                Write-Host "$envStr" -ForegroundColor DarkYellow
            }
        }
    }

    # Footer with sources
    Write-Host ""
    Write-Host "  Sources:" -ForegroundColor DarkGray
    foreach ($src in $config.Sources) {
        $shortSrc = $src -replace [regex]::Escape($HOME), "~"
        Write-Host "    $shortSrc" -ForegroundColor DarkGray
    }
    Write-Host ""
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
            Write-Host "-> $fullCommand" -ForegroundColor DarkGray
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

            Write-Host "-> $fullCommand" -ForegroundColor DarkGray
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
