# Define the path for the .dev_env.json file
$devEnvFilePath = Join-Path -Path (Get-Location) -ChildPath ".dev_env.json"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $scriptDir "template\.dev_env.json"

# Check if the .dev_env.json file already exists
if (Test-Path -Path $devEnvFilePath) {
    Write-Host "The .dev_env.json file already exists at $devEnvFilePath"
    exit 0
}

# Priority order for initialization:
# 1. DEV_ENV_VARIABLES environment variable
# 2. Template file
# 3. Create empty file

if ($env:DEV_ENV_VARIABLES -and (Test-Path -Path $env:DEV_ENV_VARIABLES)) {
    # Read content from the file specified in $env:DEV_ENV_VARIABLES
    $devEnvContent = Get-Content -Path $env:DEV_ENV_VARIABLES
    # Write the content to the .dev_env.json file
    $devEnvContent | Out-File -FilePath $devEnvFilePath -Encoding UTF8
    Write-Host "The content from $($env:DEV_ENV_VARIABLES) has been copied to $devEnvFilePath"
} elseif (Test-Path -Path $templatePath) {
    # Copy from template
    Copy-Item -Path $templatePath -Destination $devEnvFilePath
    
    # Update schema path to absolute path
    $schemaPath = Join-Path $scriptDir "template\.dev_env.schema.json"
    $absoluteSchemaPath = (Resolve-Path $schemaPath).Path
    
    try {
        $jsonContent = Get-Content -Path $devEnvFilePath -Raw | ConvertFrom-Json
        $jsonContent | Add-Member -MemberType NoteProperty -Name '$schema' -Value $absoluteSchemaPath -Force
        $jsonContent | ConvertTo-Json -Depth 100 | Out-File -FilePath $devEnvFilePath -Encoding UTF8
        Write-Host "Template copied from $templatePath to $devEnvFilePath with absolute schema path"
    } catch {
        Write-Host "Template copied from $templatePath to $devEnvFilePath (schema path update failed)"
    }
    
    Write-Host "Please edit $devEnvFilePath to customize your environment settings"
} else {
    # Create empty file as fallback
    Write-Host "Creating empty .dev_env.json file at $devEnvFilePath"
    '{}' | Out-File -FilePath $devEnvFilePath -Encoding UTF8
    Write-Host "Please add your configuration to $devEnvFilePath"
}

