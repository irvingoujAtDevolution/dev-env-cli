param (
    [string]$envNameSubstring
)

function Copy-Env {
    param (
        [string]$envNameSubstring
    )

    $jsonFilePath = get_env_path 
    $jsonContent = Get-Content -Path $jsonFilePath | ConvertFrom-Json

    $matchingEnvVars = $jsonContent.PSObject.Properties | Where-Object { $_.Name -like "*$envNameSubstring*" }

    if ($matchingEnvVars.Count -eq 1) {
        $matchingEnvVars.Value | Set-Clipboard
        Write-Host "Environment variable '$($matchingEnvVars.Name)' from JSON file copied to clipboard."
    }
    elseif ($matchingEnvVars.Count -gt 1) {
        Write-Host "Multiple environment variables found with substring '$envNameSubstring':"
        $matchingEnvVars.Name | ForEach-Object { Write-Host $_ }
    }
    else {
        Write-Host "Error: No environment variable contains the substring '$envNameSubstring' in the JSON file."
    }
}

# Call the Copy-Env function
Copy-Env -envNameSubstring $envNameSubstring
