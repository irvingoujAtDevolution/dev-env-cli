param (
    [string]$number
)

function SetEnvForFile {
    param (
        [string]$JsonFilePath
    )

    Write-Host "Setting environment variables for $JsonFilePath"
    
    try {
        $envJson = Get-Content -Raw -Path $JsonFilePath | ConvertFrom-Json
    }
    catch {
        Write-Host "Failed to parse the .dev_env.json file. Please check if the file contains valid JSON."
        exit
    }

    # Determine the attribute name based on the presence of the number parameter
    $envAttributeName = if ($number) { "temp_env_$number" } else { "temp_env" }

    # Check if the specified attribute exists and is an object
    if ($envJson.PSObject.Properties.Name -contains $envAttributeName -and $envJson.$envAttributeName -is [pscustomobject]) {
        # Loop through each string attribute in specified environment config
        foreach ($attribute in $envJson.$envAttributeName.PSObject.Properties | Where-Object { $_.Value -is [string] }) {
            # Set environment variable for the current session using the correct syntax
            $Command = '$env:' + $attribute.Name + ' = ' + "'" + $attribute.Value + "'"
            # Execute the command
            Invoke-Expression -Command $Command
            Write-Host "Setting environment variable $($attribute.Name) to $($attribute.Value)"
        }
    }
    else {
        Write-Host "The $envAttributeName attribute does not exist or is not an object in the .dev_env.json file."
    }
    Write-Host ""
}

# Attempt to find and read the .dev_env.json file, converting its content to a JSON object
$jsonFilePath = @(get_env_path -r) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object { $_.Length }

if ($null -eq $jsonFilePath -or $jsonFilePath.Count -eq 0) {
    Write-Host "Failed to locate the .dev_env.json file. Please ensure it exists within the directory hierarchy."
    exit
}
else {
    Write-Host "Found .dev_env.json file at $jsonFilePath"
}

Write-Host "jsonFilePath contains the following paths:"
foreach ($path in $jsonFilePath) {
    Write-Host "  $path"
}
Write-Host ""

foreach ($path in $jsonFilePath) {
    if (Test-Path $path) {
        SetEnvForFile -JsonFilePath $path
    }
    else {
        Write-Host "File not found: $path"
    }
}
