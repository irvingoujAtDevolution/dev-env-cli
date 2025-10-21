param (
    [switch]$r  # Use PowerShell's switch type for flags
)

function Find-JsonFile {
    $currentDir = Get-Location
    $jsonPaths = @()  # To store multiple paths if -r is used
    $isRecursive = $r.IsPresent  # Use the $r switch to determine if recursion is needed
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    $templatePath = Join-Path $scriptDir "template\.dev_env.json"

    while ($true) {
        if ("" -eq $currentDir) {
            break
        }

        # Check if .dev_env.json exists in the current directory
        if (Test-Path -Path "$currentDir\.dev_env.json") {
            if ($isRecursive) {
                $jsonPaths += "$currentDir\.dev_env.json"
            } else {
                return "$currentDir\.dev_env.json"
            }
        }

        $parentDir = Split-Path -Path $currentDir -Parent
        if ($parentDir -eq $currentDir) {
            break
        }
        $currentDir = $parentDir
    }

    # Add DEV_ENV_PATH if it exists
    if ($DEV_ENV_PATH -and (Test-Path -Path $DEV_ENV_PATH)) {
        $jsonPaths += $DEV_ENV_PATH
    }

    # Add template as fallback if it exists
    if (Test-Path -Path $templatePath) {
        $jsonPaths += $templatePath
    }

    if ($isRecursive) {
        return $jsonPaths
    } else {
        # Return the first valid path, with template as last resort
        if ($DEV_ENV_PATH -and (Test-Path -Path $DEV_ENV_PATH)) {
            return $DEV_ENV_PATH
        }
        if (Test-Path -Path $templatePath) {
            return $templatePath
        }
        return $null
    }
}

# Call the function and output results
Find-JsonFile
