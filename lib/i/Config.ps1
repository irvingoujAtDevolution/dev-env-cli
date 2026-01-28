# Config.ps1 - Configuration file discovery and parsing

function Get-DevEnvPath {
    param(
        [switch]$Recursive
    )

    $currentDir = Get-Location
    $jsonPaths = @()
    $scriptDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $templatePath = Join-Path $scriptDir "template\.dev_env.json"

    while ($true) {
        if ([string]::IsNullOrEmpty($currentDir)) {
            break
        }

        $configPath = Join-Path $currentDir ".dev_env.json"
        if (Test-Path -Path $configPath) {
            if ($Recursive) {
                $jsonPaths += $configPath
            } else {
                return $configPath
            }
        }

        $parentDir = Split-Path -Path $currentDir -Parent
        if ($parentDir -eq $currentDir -or [string]::IsNullOrEmpty($parentDir)) {
            break
        }
        $currentDir = $parentDir
    }

    # Add DEV_ENV_PATH if it exists
    if ($env:DEV_ENV_PATH -and (Test-Path -Path $env:DEV_ENV_PATH)) {
        $jsonPaths += $env:DEV_ENV_PATH
    }

    # Add template as fallback if it exists
    if (Test-Path -Path $templatePath) {
        $jsonPaths += $templatePath
    }

    if ($Recursive) {
        return $jsonPaths
    } else {
        # Return the first valid path, with template as last resort
        if ($env:DEV_ENV_PATH -and (Test-Path -Path $env:DEV_ENV_PATH)) {
            return $env:DEV_ENV_PATH
        }
        if (Test-Path -Path $templatePath) {
            return $templatePath
        }
        return $null
    }
}

function Get-DevEnvConfig {
    param(
        [switch]$Recursive
    )

    if ($Recursive) {
        $paths = Get-DevEnvPath -Recursive
        $configs = @()
        foreach ($path in $paths) {
            if ($path -and (Test-Path $path)) {
                try {
                    $content = Get-Content -Path $path -Raw | ConvertFrom-Json
                    $configs += @{
                        Path = $path
                        Config = $content
                    }
                } catch {
                    Write-Warning "Failed to parse $path : $_"
                }
            }
        }
        return $configs
    } else {
        $path = Get-DevEnvPath
        if ($path -and (Test-Path $path)) {
            try {
                return Get-Content -Path $path -Raw | ConvertFrom-Json
            } catch {
                Write-Error "Failed to parse $path : $_"
                return $null
            }
        }
        return $null
    }
}

function Get-ScriptRootPath {
    # Returns the root bin/ directory
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
