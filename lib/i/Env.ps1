# Env.ps1 - Environment variable management

function Get-EnvConfigs {
    $configPath = Get-DevEnvPath
    if ($configPath) {
        Write-Host "Config: $configPath" -ForegroundColor Gray
    }

    $config = Get-DevEnvConfig
    if ($null -eq $config) {
        Write-Host "No config found." -ForegroundColor Yellow
        return @()
    }

    # Find all temp_env* properties
    $envConfigs = $config.PSObject.Properties | Where-Object {
        $_.Name -match "^temp_env(_\d+)?$" -and $_.Value -is [pscustomobject]
    }

    return $envConfigs
}

function Show-EnvConfigs {
    $configs = Get-EnvConfigs

    if ($configs.Count -eq 0) {
        Write-Host "No environment configs found." -ForegroundColor Yellow
        Write-Host "Add 'temp_env' or 'temp_env_N' to your .dev_env.json" -ForegroundColor Gray
        return
    }

    Write-Host "Available env configs:" -ForegroundColor Cyan
    foreach ($cfg in $configs) {
        $name = $cfg.Name
        $vars = $cfg.Value.PSObject.Properties | Where-Object { $_.Value -is [string] }
        $varCount = ($vars | Measure-Object).Count

        # Extract number if present
        if ($name -eq "temp_env") {
            Write-Host "  env" -ForegroundColor White -NoNewline
            Write-Host " (default) - $varCount vars" -ForegroundColor Gray
        } else {
            $num = $name -replace "temp_env_", ""
            Write-Host "  env $num" -ForegroundColor White -NoNewline
            Write-Host " - $varCount vars" -ForegroundColor Gray
        }

        # Show variables
        foreach ($v in $vars) {
            $displayValue = $v.Value
            if ($displayValue.Length -gt 40) {
                $displayValue = $displayValue.Substring(0, 37) + "..."
            }
            Write-Host "       $($v.Name)=$displayValue" -ForegroundColor DarkGray
        }
    }
}

function Set-DevEnv {
    param(
        [string]$Number
    )

    # Get all config files recursively (layered approach)
    $configFiles = @(Get-DevEnvPath -Recursive) | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } | Sort-Object { $_.Length }

    if ($null -eq $configFiles -or $configFiles.Count -eq 0) {
        Write-Host "No .dev_env.json found." -ForegroundColor Red
        exit 1
    }

    $envAttributeName = if ($Number) { "temp_env_$Number" } else { "temp_env" }
    $setCount = 0

    foreach ($path in $configFiles) {
        if (-not (Test-Path $path)) {
            continue
        }

        try {
            $config = Get-Content -Raw -Path $path | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to parse $path"
            continue
        }

        if ($config.PSObject.Properties.Name -contains $envAttributeName -and
            $config.$envAttributeName -is [pscustomobject]) {

            Write-Host "From: $path" -ForegroundColor Gray

            foreach ($attr in $config.$envAttributeName.PSObject.Properties | Where-Object { $_.Value -is [string] }) {
                $key = $attr.Name
                $value = $attr.Value

                # Set environment variable
                Set-Item -Path "env:$key" -Value $value
                Write-Host "  $key=$value" -ForegroundColor Green
                $setCount++
            }
        }
    }

    if ($setCount -eq 0) {
        Write-Host "No '$envAttributeName' found in any config." -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "Set $setCount environment variable(s)." -ForegroundColor Cyan
    }
}
