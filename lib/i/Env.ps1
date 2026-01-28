# Env.ps1 - Environment profile management (v2)

function Show-EnvProfiles {
    <#
    .SYNOPSIS
    List all available env profiles from merged config.
    #>

    $config = Get-MergedConfig

    if ($config.Env.Count -eq 0) {
        Write-Host "No env profiles found." -ForegroundColor Yellow
        Write-Host "Add 'env' section to your .dev_env.json" -ForegroundColor Gray
        return
    }

    # Header
    Write-Host ""
    Write-Host "  ENV PROFILES" -ForegroundColor Cyan
    Write-Host "  ------------" -ForegroundColor DarkGray

    # Calculate max name length
    $maxLen = ($config.Env.Keys | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum
    $maxLen = [Math]::Max($maxLen, 8)

    foreach ($name in $config.Env.Keys | Sort-Object) {
        $profile = $config.Env[$name]
        $vars = $profile.PSObject.Properties | Where-Object { $_.Value -is [string] }
        $varCount = ($vars | Measure-Object).Count
        $padding = " " * ($maxLen - $name.Length)

        # Profile name with default indicator
        if ($name -eq "default") {
            Write-Host "  $name$padding  " -ForegroundColor Green -NoNewline
            Write-Host "($varCount vars) " -ForegroundColor Gray -NoNewline
            Write-Host "[default]" -ForegroundColor DarkGreen
        } else {
            Write-Host "  $name$padding  " -ForegroundColor White -NoNewline
            Write-Host "($varCount vars)" -ForegroundColor Gray
        }

        # Show variables
        $varPad = " " * ($maxLen + 4)
        foreach ($v in $vars) {
            $displayValue = $v.Value
            if ($displayValue.Length -gt 35) {
                $displayValue = $displayValue.Substring(0, 32) + "..."
            }
            Write-Host "$varPad" -NoNewline
            Write-Host "$($v.Name)" -ForegroundColor DarkYellow -NoNewline
            Write-Host "=" -ForegroundColor DarkGray -NoNewline
            Write-Host "$displayValue" -ForegroundColor Gray
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

    if (-not $config.Env.ContainsKey($ProfileName)) {
        Write-Host "Env profile '$ProfileName' not found." -ForegroundColor Red
        Write-Host ""
        Show-EnvProfiles
        exit 1
    }

    $profile = $config.Env[$ProfileName]
    $setCount = 0

    Write-Host ""
    Write-Host "  Setting env: " -ForegroundColor Cyan -NoNewline
    Write-Host "$ProfileName" -ForegroundColor White
    Write-Host ""

    foreach ($prop in $profile.PSObject.Properties | Where-Object { $_.Value -is [string] }) {
        $key = $prop.Name
        $value = $prop.Value
        Set-Item -Path "env:$key" -Value $value

        $displayValue = if ($value.Length -gt 40) { $value.Substring(0, 37) + "..." } else { $value }
        Write-Host "  $key" -ForegroundColor Green -NoNewline
        Write-Host "=" -ForegroundColor DarkGray -NoNewline
        Write-Host "$displayValue" -ForegroundColor Gray
        $setCount++
    }

    Write-Host ""
    Write-Host "  $setCount variable(s) set." -ForegroundColor DarkGray
    Write-Host ""
}
