param(
    [string]$JsonFilePath
)

if (-not $JsonFilePath) {
    Write-Host "Usage: update_schema_path.ps1 -JsonFilePath <path_to_json_file>"
    exit 1
}

if (-not (Test-Path $JsonFilePath)) {
    Write-Host "JSON file not found: $JsonFilePath"
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$schemaPath = Join-Path $scriptDir "template\.dev_env.schema.json"
$absoluteSchemaPath = (Resolve-Path $schemaPath).Path

try {
    $jsonContent = Get-Content -Path $JsonFilePath -Raw | ConvertFrom-Json
    
    # Update or add the $schema property
    $jsonContent | Add-Member -MemberType NoteProperty -Name '$schema' -Value $absoluteSchemaPath -Force
    
    # Convert back to JSON and save
    $jsonContent | ConvertTo-Json -Depth 100 | Out-File -FilePath $JsonFilePath -Encoding UTF8
    
    Write-Host "Updated schema path in $JsonFilePath to: $absoluteSchemaPath"
} catch {
    Write-Host "Error updating schema path: $_"
    exit 1
}