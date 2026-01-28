# Env.ps1 - Environment profile management (v2)

function Show-EnvProfiles {
    <#
    .SYNOPSIS
    List all available env profiles from merged config.
    #>

    $config = Get-MergedConfig

    if ($config.Sources.Count -gt 0) {
        Write-Host "Sources:" -ForegroundColor Gray
        foreach ($src in $config.Sources) {
            Write-Host "  $src" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    if ($config.Env.Count -eq 0) {
        Write-Host "No env profiles found." -ForegroundColor Yellow
        Write-Host "Add 'env' section to your .dev_env.json" -ForegroundColor Gray
        return
    }

    Write-Host "Env profiles:" -ForegroundColor Cyan
    foreach ($name in $config.Env.Keys | Sort-Object) {
        $profile = $config.Env[$name]
        $vars = $profile.PSObject.Properties | Where-Object { $_.Value -is [string] }
        $varCount = ($vars | Measure-Object).Count

        $suffix = if ($name -eq "default") { " (default)" } else { "" }
        Write-Host "  $name$suffix" -ForegroundColor White -NoNewline
        Write-Host " - $varCount vars" -ForegroundColor Gray

        foreach ($v in $vars) {
            $displayValue = $v.Value
            if ($displayValue.Length -gt 40) {
                $displayValue = $displayValue.Substring(0, 37) + "..."
            }
            Write-Host "       $($v.Name)=$displayValue" -ForegroundColor DarkGray
        }
    }
}

function Set-EnvProfile {
    <#
    .SYNOPSIS
    Set environment variables from a named profile.
    Defaults to 'default' profile if no name given.
    #>
    param(
        [string]$ProfileName
    )

    # Default to 'default' profile
    if ([string]::IsNullOrWhiteSpace($ProfileName)) {
        $ProfileName = "default"
    }

    $config = Get-MergedConfig

    if ($config.Sources.Count -gt 0) {
        Write-Host "Sources:" -ForegroundColor Gray
        foreach ($src in $config.Sources) {
            Write-Host "  $src" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    if (-not $config.Env.ContainsKey($ProfileName)) {
        Write-Host "Env profile '$ProfileName' not found." -ForegroundColor Red
        Write-Host ""
        Write-Host "Available profiles:" -ForegroundColor Yellow
        foreach ($name in $config.Env.Keys | Sort-Object) {
            Write-Host "  $name" -ForegroundColor White
        }
        exit 1
    }

    $profile = $config.Env[$ProfileName]
    $setCount = 0

    Write-Host "Setting env from '$ProfileName':" -ForegroundColor Cyan
    foreach ($prop in $profile.PSObject.Properties | Where-Object { $_.Value -is [string] }) {
        $key = $prop.Name
        $value = $prop.Value
        Set-Item -Path "env:$key" -Value $value
        Write-Host "  $key=$value" -ForegroundColor Green
        $setCount++
    }

    Write-Host ""
    Write-Host "Set $setCount environment variable(s)." -ForegroundColor Cyan
}
