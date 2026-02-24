# Config.ps1 - Configuration file discovery, parsing, and merging (v2)

function Get-MainWorktreeRoot {
    <#
    .SYNOPSIS
    If current directory is inside a linked git worktree, returns the main worktree root path.
    Returns $null if not in a linked worktree or not in a git repo.
    #>
    try {
        $gitDir = git rev-parse --git-dir 2>$null
        $commonDir = git rev-parse --git-common-dir 2>$null

        if (-not $gitDir -or -not $commonDir) { return $null }

        $gitDirFull = (Resolve-Path $gitDir -ErrorAction Stop).Path
        $commonDirFull = (Resolve-Path $commonDir -ErrorAction Stop).Path

        # If same, we're in the main worktree (not linked)
        if ($gitDirFull -eq $commonDirFull) { return $null }

        # Main worktree root = parent of the common .git directory
        return Split-Path -Parent $commonDirFull
    } catch {
        return $null
    }
}

function Get-DevEnvPaths {
    <#
    .SYNOPSIS
    Find all .dev_env.json files from current directory up to root.
    If inside a linked git worktree, also includes the main worktree's config.
    Returns paths ordered from root to current (for merge order).
    Merge order: parent dirs -> main worktree -> linked worktree -> subdirs
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

    # Check for linked git worktree - inject main worktree config if needed
    $mainRoot = Get-MainWorktreeRoot
    if ($mainRoot) {
        $mainConfig = Join-Path $mainRoot ".dev_env.json"
        if (Test-Path $mainConfig) {
            $mainConfigFull = (Resolve-Path $mainConfig).Path

            # Check it's not already in the path list
            $alreadyIn = $false
            foreach ($p in $paths) {
                if ((Resolve-Path $p).Path -eq $mainConfigFull) {
                    $alreadyIn = $true
                    break
                }
            }

            if (-not $alreadyIn) {
                # Find the linked worktree root to determine insert position
                $wtRoot = (git rev-parse --show-toplevel 2>$null)
                if ($wtRoot) {
                    $wtRoot = $wtRoot.Trim().Replace('/', '\')

                    # Insert main config just before the first path inside the linked worktree
                    $insertAt = $paths.Count
                    for ($i = 0; $i -lt $paths.Count; $i++) {
                        $dir = Split-Path -Parent (Resolve-Path $paths[$i]).Path
                        if ($dir -eq $wtRoot -or $dir.StartsWith("$wtRoot\", [System.StringComparison]::OrdinalIgnoreCase)) {
                            $insertAt = $i
                            break
                        }
                    }

                    if ($insertAt -eq 0) {
                        $paths = @($mainConfig) + $paths
                    } elseif ($insertAt -ge $paths.Count) {
                        $paths = $paths + @($mainConfig)
                    } else {
                        $paths = $paths[0..($insertAt - 1)] + @($mainConfig) + $paths[$insertAt..($paths.Count - 1)]
                    }
                }
            }
        }
    }

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

            # Merge env profiles (deep merge: individual vars within each profile)
            if ($config.PSObject.Properties.Name -contains "env") {
                foreach ($prop in $config.env.PSObject.Properties) {
                    if (-not $mergedEnv.ContainsKey($prop.Name)) {
                        $mergedEnv[$prop.Name] = @{}
                    }
                    # Merge individual key-value pairs within the profile
                    foreach ($envProp in $prop.Value.PSObject.Properties) {
                        $mergedEnv[$prop.Name][$envProp.Name] = $envProp.Value
                    }
                }
            }
        } catch {
            Write-Warning "Failed to parse $path : $_"
        }
    }

    # Convert inner env hashtables to PSCustomObjects for downstream compatibility
    $envResult = @{}
    foreach ($key in $mergedEnv.Keys) {
        $envResult[$key] = [PSCustomObject]$mergedEnv[$key]
    }

    return @{
        Commands = $mergedCommands
        Env = $envResult
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
