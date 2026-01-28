# Init.ps1 - Initialize .dev_env.json configuration (v2)

function Initialize-DevEnv {
    <#
    .SYNOPSIS
    Create a new .dev_env.json file with v2 structure.
    #>

    $devEnvFilePath = Join-Path -Path (Get-Location) -ChildPath ".dev_env.json"

    # Check if already exists
    if (Test-Path -Path $devEnvFilePath) {
        Write-Host "Already exists: $devEnvFilePath" -ForegroundColor Yellow
        return
    }

    # Create v2 structure
    $template = @{
        commands = @{
            build = "echo 'build command here'"
            test = "echo 'test command here'"
            dev = @{
                run = "echo 'dev server'"
                env = "default"
            }
        }
        env = @{
            default = @{
                DEBUG = "false"
            }
            dev = @{
                DEBUG = "true"
                LOG_LEVEL = "verbose"
            }
        }
    }

    $template | ConvertTo-Json -Depth 10 | Out-File -FilePath $devEnvFilePath -Encoding UTF8

    Write-Host "Created: $devEnvFilePath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Edit the file to customize your commands and env profiles." -ForegroundColor Gray
}
