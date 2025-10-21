param(
    [string]$locationName
)

# Function to read locations from the JSON file
function Get-LocationMap {
    param(
        [string]$jsonPath
    )
    
    # Read the JSON content from the file
    $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    
    # Convert the JSON array to a hashtable
    $locationMap = @{}
    foreach ($item in $jsonContent.quick_locations) {
        $locationMap[$item.name] = $item.location
    }
    
    return $locationMap
}

# Function to add a location to the JSON file
function Add-Location {
    param(
        [string]$jsonPath,
        [string]$name,
        [string]$location
    )
    
    $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    $newLocation = @{ name = $name; location = $location }
    $jsonContent.quick_locations += $newLocation
    $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath
    Write-Host "Added new location: $name -> $location"
}

# Function to list all locations
function Read-Locations {
    param(
        [string]$jsonPath
    )
    
    $locations = Get-LocationMap -jsonPath $jsonPath
    foreach ($name in $locations.Keys) {
        Write-Host "$name -> $($locations[$name])"
    }
}

# Check for functional arguments
if ($locationName.StartsWith("-")) {
    switch ($locationName) {
        "--list" {
            if (-not [string]::IsNullOrEmpty($env:DEV_ENV_VARIABLES)) {
                Read-Locations -jsonPath $env:DEV_ENV_VARIABLES
            }
            else {
                Write-Host "The environment variable 'DEV_ENV_VARIABLES' is not set."
            }
        }
        "--help" {
            Write-Host "Usage: to <location>"
            Write-Host "       to --list"
        }
        "-h" {
            Write-Host "Usage: to <location>"
            Write-Host "       to --list"
        }
        default {
            Write-Host "Unknown argument: $locationName"
        }
    }
}
else {
    # Rest of the script for non-functional arguments
    if (-not [string]::IsNullOrEmpty($env:DEV_ENV_VARIABLES)) {
        $locations = Get-LocationMap -jsonPath $env:DEV_ENV_VARIABLES
        
        if ($locations.ContainsKey($locationName)) {
            Set-Location -Path $locations[$locationName]
            Write-Host "Navigated to $($locations[$locationName])"
        }
        else {
            Write-Host "Location '$locationName' not found."
        }
    }
    else {
        Write-Host "The environment variable 'DEV_ENV_VARIABLES' is not set."
    }
}
