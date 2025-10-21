param (
    [string]$Profile,
    [string]$Assignment
)

# Display help if no parameters provided
if (-not $Profile -or -not $Assignment) {
    Write-Host "Usage: env_add.ps1 [PROFILE] [NAME]=[VALUE]"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\env_add.ps1 temp_env API_KEY=my-secret-key"
    Write-Host "  .\env_add.ps1 temp_env_1 DATABASE_URL=postgresql://localhost:5432/db"
    Write-Host "  .\env_add.ps1 0 DEBUG_MODE=true        # 0 is shorthand for temp_env"
    Write-Host "  .\env_add.ps1 1 DEBUG_MODE=true        # 1 is shorthand for temp_env_1"
    Write-Host ""
    Write-Host "Available profiles: temp_env, temp_env_1, temp_env_2, etc."
    exit 1
}

# Normalize profile name - convert numeric shortcuts to temp_env_N format
if ($Profile -match '^\d+$') {
    if ($Profile -eq "0") {
        $Profile = "temp_env"
    } else {
        $Profile = "temp_env_$Profile"
    }
}

# Parse NAME=VALUE assignment
if ($Assignment -notmatch '^([^=]+)=(.*)$') {
    Write-Host "Error: Assignment must be in format NAME=VALUE"
    Write-Host "Example: API_KEY=my-secret-key"
    exit 1
}

$varName = $Matches[1].Trim()
$varValue = $Matches[2].Trim()

if ([string]::IsNullOrWhiteSpace($varName)) {
    Write-Host "Error: Variable name cannot be empty"
    exit 1
}

# Find the configuration file
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$getEnvPathScript = Join-Path $scriptDir "get_env_path.ps1"

if (-not (Test-Path $getEnvPathScript)) {
    Write-Host "Error: get_env_path.ps1 not found"
    exit 1
}

# Source get_env_path.ps1 to get the Find-JsonFile function
. $getEnvPathScript

# Get the config file path (non-recursive, closest one)
$configPath = Find-JsonFile

if (-not $configPath) {
    Write-Host "Error: No .dev_env.json file found in directory hierarchy"
    Write-Host "Run .\init_env.ps1 to create one"
    exit 1
}

# Don't allow editing the template
$templatePath = Join-Path $scriptDir "template\.dev_env.json"
if ($configPath -eq $templatePath) {
    Write-Host "Error: Cannot modify the template file"
    Write-Host "Run .\init_env.ps1 to create a local .dev_env.json file first"
    exit 1
}

Write-Host "Using config file: $configPath"

# Read existing configuration
try {
    $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
}
catch {
    Write-Host "Error: Failed to parse $configPath as valid JSON"
    Write-Host $_.Exception.Message
    exit 1
}

# Ensure the profile exists
if (-not ($config.PSObject.Properties.Name -contains $Profile)) {
    Write-Host "Creating new profile: $Profile"
    $config | Add-Member -MemberType NoteProperty -Name $Profile -Value ([PSCustomObject]@{})
}

# Ensure the profile is an object
if ($config.$Profile -isnot [PSCustomObject]) {
    Write-Host "Error: Profile '$Profile' exists but is not an object"
    exit 1
}

# Check if variable already exists
$isUpdate = $config.$Profile.PSObject.Properties.Name -contains $varName

# Add or update the variable
if ($isUpdate) {
    Write-Host "Updating $Profile.$varName = $varValue"
    $config.$Profile.$varName = $varValue
} else {
    Write-Host "Adding $Profile.$varName = $varValue"
    $config.$Profile | Add-Member -MemberType NoteProperty -Name $varName -Value $varValue -Force
}

# Write back to file with proper formatting
try {
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
    Write-Host "Successfully updated $configPath"
}
catch {
    Write-Host "Error: Failed to write to $configPath"
    Write-Host $_.Exception.Message
    exit 1
}
