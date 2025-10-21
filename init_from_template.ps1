param(
    [string]$TargetPath = ".",
    [switch]$Force
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $scriptDir "template\.dev_env.json"
$targetFilePath = Join-Path -Path $TargetPath -ChildPath ".dev_env.json"

# Check if template exists
if (-not (Test-Path -Path $templatePath)) {
    Write-Host "Template file not found at $templatePath" -ForegroundColor Red
    exit 1
}

# Check if target file already exists
if (Test-Path -Path $targetFilePath) {
    if (-not $Force) {
        Write-Host "Target file already exists at $targetFilePath" -ForegroundColor Yellow
        Write-Host "Use -Force to overwrite the existing file"
        exit 1
    } else {
        Write-Host "Overwriting existing file at $targetFilePath" -ForegroundColor Yellow
    }
}

# Create target directory if it doesn't exist
$targetDir = Split-Path -Parent $targetFilePath
if (-not (Test-Path -Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}

# Copy template to target location
Copy-Item -Path $templatePath -Destination $targetFilePath -Force

# Update schema path to absolute path
$schemaPath = Join-Path $scriptDir "template\.dev_env.schema.json"
$absoluteSchemaPath = (Resolve-Path $schemaPath).Path

try {
    $jsonContent = Get-Content -Path $targetFilePath -Raw | ConvertFrom-Json
    $jsonContent | Add-Member -MemberType NoteProperty -Name '$schema' -Value $absoluteSchemaPath -Force
    $jsonContent | ConvertTo-Json -Depth 100 | Out-File -FilePath $targetFilePath -Encoding UTF8
    Write-Host "Template copied to $targetFilePath with absolute schema path" -ForegroundColor Green
} catch {
    Write-Host "Template copied to $targetFilePath (schema path update failed)" -ForegroundColor Yellow
}

Write-Host "Please edit the file to customize your environment settings" -ForegroundColor Cyan

# Show the contents of the template for reference
Write-Host "`nTemplate contents:" -ForegroundColor Yellow
Get-Content -Path $targetFilePath | Write-Host