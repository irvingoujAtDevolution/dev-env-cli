# Initialize environment from template (ignores DEV_ENV_VARIABLES)
# Define the path for the .dev_env.json file
$devEnvFilePath = Join-Path -Path (Get-Location) -ChildPath ".dev_env.json"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $scriptDir "template\.dev_env.json"

# Check if the .dev_env.json file already exists
if (Test-Path -Path $devEnvFilePath) {
    Write-Host "The .dev_env.json file already exists at $devEnvFilePath" -ForegroundColor Yellow
    Write-Host "Use -Force to overwrite or delete the existing file first" -ForegroundColor Yellow
    exit 0
}

# Priority order for initialization (template first):
# 1. Template file
# 2. DEV_ENV_VARIABLES environment variable  
# 3. Create empty file

if (Test-Path -Path $templatePath) {
    # Copy from template
    Copy-Item -Path $templatePath -Destination $devEnvFilePath
    
    # Update schema path to absolute path
    $schemaPath = Join-Path $scriptDir "template\.dev_env.schema.json"
    $absoluteSchemaPath = (Resolve-Path $schemaPath).Path
    
    try {
        $jsonContent = Get-Content -Path $devEnvFilePath -Raw | ConvertFrom-Json
        $jsonContent | Add-Member -MemberType NoteProperty -Name '$schema' -Value $absoluteSchemaPath -Force
        $jsonContent | ConvertTo-Json -Depth 100 | Out-File -FilePath $devEnvFilePath -Encoding UTF8
        Write-Host "Template copied from $templatePath to $devEnvFilePath with absolute schema path" -ForegroundColor Green
    } catch {
        Write-Host "Template copied from $templatePath to $devEnvFilePath (schema path update failed)" -ForegroundColor Yellow
    }
    
    Write-Host "Please edit $devEnvFilePath to customize your environment settings" -ForegroundColor Cyan
} elseif ($env:DEV_ENV_VARIABLES -and (Test-Path -Path $env:DEV_ENV_VARIABLES)) {
    # Read content from the file specified in $env:DEV_ENV_VARIABLES
    $devEnvContent = Get-Content -Path $env:DEV_ENV_VARIABLES
    # Write the content to the .dev_env.json file
    $devEnvContent | Out-File -FilePath $devEnvFilePath -Encoding UTF8
    Write-Host "The content from $($env:DEV_ENV_VARIABLES) has been copied to $devEnvFilePath" -ForegroundColor Green
} else {
    # Create empty file as fallback
    Write-Host "Creating empty .dev_env.json file at $devEnvFilePath" -ForegroundColor Yellow
    '{}' | Out-File -FilePath $devEnvFilePath -Encoding UTF8
    Write-Host "Please add your configuration to $devEnvFilePath" -ForegroundColor Cyan
}