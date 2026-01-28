# Run.ps1 - Quick command execution

function Get-QuickCommands {
    $config = Get-DevEnvConfig
    if ($null -eq $config) {
        return @()
    }

    if ($config.PSObject.Properties.Name -contains "quick_command" -and $config.quick_command -is [pscustomobject]) {
        return $config.quick_command.PSObject.Properties | Where-Object {
            $_.Value -is [string] -or $_.Value -is [pscustomobject]
        }
    }
    return @()
}

function Show-QuickCommands {
    $configPath = Get-DevEnvPath
    if ($configPath) {
        Write-Host "Config: $configPath" -ForegroundColor Gray
    }

    $commands = Get-QuickCommands
    if ($commands.Count -eq 0) {
        Write-Host "No quick commands found." -ForegroundColor Yellow
        return
    }

    Write-Host "Available commands:" -ForegroundColor Cyan
    foreach ($cmd in $commands) {
        $name = $cmd.Name
        $value = $cmd.Value

        if ($value -is [string]) {
            Write-Host "  $name" -ForegroundColor White -NoNewline
            Write-Host " -> $value" -ForegroundColor Gray
        } else {
            $cmdStr = $value.command
            if ($value.args) {
                $cmdStr += " " + ($value.args -join ' ')
            }
            Write-Host "  $name" -ForegroundColor White -NoNewline
            Write-Host " -> $cmdStr" -ForegroundColor Gray
            if ($value.cwd) {
                Write-Host "       cwd: $($value.cwd)" -ForegroundColor DarkGray
            }
        }
    }
}

function Invoke-QuickCommand {
    param(
        [string]$Name,
        [string[]]$ExtraArgs
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Show-QuickCommands
        return
    }

    $configPath = Get-DevEnvPath
    if ($null -eq $configPath) {
        Write-Host "No .dev_env.json found." -ForegroundColor Red
        exit 1
    }

    $config = Get-DevEnvConfig
    if ($null -eq $config) {
        Write-Host "Failed to parse config." -ForegroundColor Red
        exit 1
    }

    if (-not ($config.PSObject.Properties.Name -contains "quick_command")) {
        Write-Host "No quick_command section in config." -ForegroundColor Red
        exit 1
    }

    $commands = Get-QuickCommands
    $matchingCommand = $commands | Where-Object { $_.Name -eq $Name }

    if ($null -eq $matchingCommand) {
        Write-Host "Command '$Name' not found." -ForegroundColor Red
        Write-Host ""
        Show-QuickCommands
        exit 1
    }

    $commandToRun = $matchingCommand.Value
    $parentCwd = Get-Location

    Invoke-CommandInternal -Command $commandToRun -ParentCwd $parentCwd -ExtraArgs $ExtraArgs
}

function Invoke-CommandInternal {
    param(
        [psobject]$Command,
        [string]$ParentCwd,
        [string[]]$ExtraArgs
    )

    if ($Command -is [string]) {
        # Simple string command
        $fullCommand = $Command
        if ($ExtraArgs -and $ExtraArgs.Count -gt 0) {
            $fullCommand += " " + ($ExtraArgs -join ' ')
        }
        Write-Host "Running: $fullCommand" -ForegroundColor Cyan
        Invoke-Expression -Command $fullCommand
    }
    elseif ($Command -is [pscustomobject]) {
        # Object command with cwd, command, args, env
        $cwd = if ([string]::IsNullOrWhiteSpace($Command.cwd)) { $ParentCwd } else { $Command.cwd }
        $cmdName = $Command.command
        $cmdArgs = if ($Command.args) { $Command.args -join ' ' } else { "" }

        $originalDir = Get-Location

        # Set environment variables if specified
        if ($null -ne $Command.env) {
            $Command.env | ForEach-Object {
                $key = $_.PSObject.Properties.Name
                $value = $_.PSObject.Properties.Value
                Write-Host "  env: $key=$value" -ForegroundColor DarkGray
                [Environment]::SetEnvironmentVariable($key, $value, "Process")
            }
        }

        # Change directory if specified
        if (-not [string]::IsNullOrWhiteSpace($cwd)) {
            Set-Location -Path $cwd
        }

        # Build full command
        $fullCommand = "$cmdName $cmdArgs".Trim()
        if ($ExtraArgs -and $ExtraArgs.Count -gt 0) {
            $fullCommand += " " + ($ExtraArgs -join ' ')
        }

        Write-Host "Running: $fullCommand" -ForegroundColor Cyan
        if ($cwd -ne $ParentCwd) {
            Write-Host "    cwd: $(Get-Location)" -ForegroundColor DarkGray
        }

        try {
            Invoke-Expression -Command $fullCommand
        }
        finally {
            Set-Location -Path $originalDir
        }
    }
    else {
        Write-Host "Unrecognized command format." -ForegroundColor Red
        exit 1
    }
}
