# Init.ps1 - Initialize .dev_env.json configuration

function Initialize-DevEnv {
    $devEnvFilePath = Join-Path -Path (Get-Location) -ChildPath ".dev_env.json"
    $scriptRoot = Get-ScriptRootPath
    $templatePath = Join-Path $scriptRoot "template\.dev_env.json"

    # Check if already exists
    if (Test-Path -Path $devEnvFilePath) {
        Write-Host "Already exists: $devEnvFilePath" -ForegroundColor Yellow
        return
    }

    # Priority: DEV_ENV_VARIABLES > template > empty
    if ($env:DEV_ENV_VARIABLES -and (Test-Path -Path $env:DEV_ENV_VARIABLES)) {
        # Copy from DEV_ENV_VARIABLES
        $content = Get-Content -Path $env:DEV_ENV_VARIABLES
        $content | Out-File -FilePath $devEnvFilePath -Encoding UTF8
        Write-Host "Created from: $($env:DEV_ENV_VARIABLES)" -ForegroundColor Green
        Write-Host "  -> $devEnvFilePath"
    }
    elseif (Test-Path -Path $templatePath) {
        # Copy from template
        Copy-Item -Path $templatePath -Destination $devEnvFilePath

        # Update schema path to absolute
        $schemaPath = Join-Path $scriptRoot "template\.dev_env.schema.json"
        if (Test-Path $schemaPath) {
            $absoluteSchemaPath = (Resolve-Path $schemaPath).Path

            try {
                $jsonContent = Get-Content -Path $devEnvFilePath -Raw | ConvertFrom-Json
                $jsonContent | Add-Member -MemberType NoteProperty -Name '$schema' -Value $absoluteSchemaPath -Force
                $jsonContent | ConvertTo-Json -Depth 100 | Out-File -FilePath $devEnvFilePath -Encoding UTF8
            }
            catch {
                # Schema update failed, but file was copied
            }
        }

        Write-Host "Created from template" -ForegroundColor Green
        Write-Host "  -> $devEnvFilePath"
        Write-Host ""
        Write-Host "Edit the file to customize your settings." -ForegroundColor Gray
    }
    else {
        # Create empty file
        '{}' | Out-File -FilePath $devEnvFilePath -Encoding UTF8
        Write-Host "Created empty config" -ForegroundColor Green
        Write-Host "  -> $devEnvFilePath"
        Write-Host ""
        Write-Host "Add your configuration to the file." -ForegroundColor Gray
    }
}
