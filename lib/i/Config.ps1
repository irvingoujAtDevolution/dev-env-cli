# Config.ps1 - Configuration file discovery, parsing, and merging (v2)

function Get-DevEnvPaths {
    <#
    .SYNOPSIS
    Find all .dev_env.json files from current directory up to root.
    Returns paths ordered from root to current (for merge order).
    #>

    $currentDir = Get-Location
    $paths = @()

    while ($true) {
        if ([string]::IsNullOrEmpty($currentDir)) {
            break
        }

        $configPath = Join-Path $currentDir ".dev_env.json"
        if (Test-Path -Path $configPath) {
            $paths += $configPath
        }

        $parentDir = Split-Path -Path $currentDir -Parent
        if ($parentDir -eq $currentDir -or [string]::IsNullOrEmpty($parentDir)) {
            break
        }
        $currentDir = $parentDir
    }

    # Reverse so root comes first (for merge: root -> child)
    [array]::Reverse($paths)
    return $paths
}

function Get-MergedConfig {
    <#
    .SYNOPSIS
    Get merged configuration from all .dev_env.json files.
    Child configs override parent configs for colliding keys.
    #>

    $paths = Get-DevEnvPaths

    $mergedCommands = @{}
    $mergedEnv = @{}
    $configSources = @()

    foreach ($path in $paths) {
        if (-not (Test-Path $path)) { continue }

        try {
            $config = Get-Content -Path $path -Raw | ConvertFrom-Json
            $configSources += $path

            # Merge commands
            if ($config.PSObject.Properties.Name -contains "commands") {
                foreach ($prop in $config.commands.PSObject.Properties) {
                    $mergedCommands[$prop.Name] = $prop.Value
                }
            }

            # Merge env profiles
            if ($config.PSObject.Properties.Name -contains "env") {
                foreach ($prop in $config.env.PSObject.Properties) {
                    $mergedEnv[$prop.Name] = $prop.Value
                }
            }
        } catch {
            Write-Warning "Failed to parse $path : $_"
        }
    }

    return @{
        Commands = $mergedCommands
        Env = $mergedEnv
        Sources = $configSources
    }
}

function Get-Command {
    <#
    .SYNOPSIS
    Get a specific command from merged config.
    #>
    param([string]$Name)

    $config = Get-MergedConfig
    if ($config.Commands.ContainsKey($Name)) {
        return $config.Commands[$Name]
    }
    return $null
}

function Get-EnvProfile {
    <#
    .SYNOPSIS
    Get a specific env profile from merged config.
    #>
    param([string]$Name)

    $config = Get-MergedConfig
    if ($config.Env.ContainsKey($Name)) {
        return $config.Env[$Name]
    }
    return $null
}

function Resolve-EnvVars {
    <#
    .SYNOPSIS
    Resolve env specification to actual env vars hashtable.
    Supports: string ref, array of refs, or inline object.
    #>
    param($EnvSpec)

    if ($null -eq $EnvSpec) {
        return @{}
    }

    $result = @{}

    if ($EnvSpec -is [string]) {
        # Single profile reference
        $profile = Get-EnvProfile -Name $EnvSpec
        if ($null -eq $profile) {
            Write-Error "Env profile '$EnvSpec' not found"
            return $null
        }
        foreach ($prop in $profile.PSObject.Properties) {
            $result[$prop.Name] = $prop.Value
        }
    }
    elseif ($EnvSpec -is [array]) {
        # Array of profile references - merge in order
        foreach ($profileName in $EnvSpec) {
            $profile = Get-EnvProfile -Name $profileName
            if ($null -eq $profile) {
                Write-Error "Env profile '$profileName' not found"
                return $null
            }
            foreach ($prop in $profile.PSObject.Properties) {
                $result[$prop.Name] = $prop.Value
            }
        }
    }
    elseif ($EnvSpec -is [pscustomobject]) {
        # Inline env object
        foreach ($prop in $EnvSpec.PSObject.Properties) {
            $result[$prop.Name] = $prop.Value
        }
    }

    return $result
}

function Get-ScriptRootPath {
    # Returns the root bin/ directory
    return Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
