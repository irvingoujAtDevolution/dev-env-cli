param (
    [string]$commandName
)

# Get all remaining arguments after the command name
$additionalArgs = $args

# Attempt to find and read the .dev_env.json file, converting its content to a JSON object
$jsonFilePath = get_env_path
if ($null -eq $jsonFilePath) {
    Write-Host "Failed to locate the .dev_env.json file. Please ensure it exists within the directory hierarchy."
    exit 1
}
else {
    Write-Host "Found .dev_env.json file at $jsonFilePath"
}

# Try to read and parse the JSON file
try {
    $envJson = Get-Content -Raw -Path $jsonFilePath | ConvertFrom-Json
}
catch {
    Write-Host "Failed to parse the .dev_env.json file. Please check if the file contains valid JSON."
    exit 1
}

# Check if the 'quick_command' object exists at the second level
if ($envJson.PSObject.Properties.Name -contains "quick_command" -and $envJson.quick_command -is [pscustomobject]) {
    # Retrieve all the quick commands as a list
    $quickCommands = $envJson.quick_command.PSObject.Properties | Where-Object { $_.Value -is [string] -or $_.Value -is [pscustomobject] }

    # If no command is provided, list available commands
    if ([string]::IsNullOrWhiteSpace($commandName)) {
        Write-Host "Available commands:"
        $quickCommands | ForEach-Object { Write-Host $_.Name }
        exit 0
    }

    # Find if the provided command name matches any in the 'quick_command' object
    $matchingCommand = $quickCommands | Where-Object { $_.Name -eq $commandName }
    
    if ($null -eq $matchingCommand) {
        Write-Host "No quick command found matching '$commandName'."
        exit 1
    }
    else {
        $commandToRun = $matchingCommand.Value
        $parentCwd = Get-Location  # Save the current working directory
        $global:requireProcesses = @()
        # Function to execute the command, handling nested command objects
        function RunCommand {
            param (
                [psobject]$commandToRun,
                [string]$parentCwd,
                [string[]]$additionalArgs
            )
            try {
                if ($commandToRun -is [string]) {
                    # Simple string command
                    $fullCommand = $commandToRun
                    if ($additionalArgs -and $additionalArgs.Count -gt 0) {
                        $fullCommand += " " + ($additionalArgs -join ' ')
                    }
                    Write-Host "Running command: $fullCommand"
                    Invoke-Expression -Command $fullCommand
                }
                elseif ($commandToRun -is [pscustomobject]) {
                    # JSON object with cwd, command, and args
                    # Do a check: if commandToRun.cwd is empty, use parentCwd
                    if ([string]::IsNullOrWhiteSpace($commandToRun.cwd)) {
                        $cwd = $parentCwd
                    }
                    else {
                        $cwd = $commandToRun.cwd
                    }
                    $command = $commandToRun.command
                    $commandArgs = $commandToRun.args -join ' '  # Convert array of arguments to a single string

                    $originalDir = Get-Location  # Save the current working directory


                    # Check if there's env attribute
                    if ($null -ne $commandToRun.env) {
                        # env is a list of key-value pairs like this:
                        # [{ "key1": "value1" }, { "key2": "value2" }]
                        # for each key-value pair in the list, we do this following:
                        # 1. set the environment variable in the current process
                        $env = $commandToRun.env
                        Write-Host $env
                        $env | ForEach-Object {
                            $key = $_.PSObject.Properties.Name
                            $value = $_.PSObject.Properties.Value
                            Write-Host "Setting environment variable: $key=$value"
                            [Environment]::SetEnvironmentVariable($key, $value, "Process")
                        }
                    }

                    # Change directory if 'cwd' is specified
                    if (-not [string]::IsNullOrWhiteSpace($cwd)) {
                        Set-Location -Path $cwd
                    }

                    #check if there's require attribute
                    # TODO: figure out how to check for --no-require flag
                    # if ($null -ne $commandToRun.require -and -not ($args -contains "--no-require")) {

                    #     # open new powershell process in cwd and call the require script
                    #     # require is a list of commands like this: ["command1", "command2"]
                    #     # for each command in the list, we do this following:
                    #     # 1. open new powershell process (new window) with the current profile in current working directory
                    #     # 2. run the command with `run command` command
                    #     $require = $commandToRun.require
                    #     $require | ForEach-Object {
                    #         $requireCommand = $_
                    #         Write-Host "Running require command: $requireCommand"
                    #         $process = Start-Process powershell -ArgumentList "-NoExit -NoProfile -Command & { . $profile; run $requireCommand }" -WorkingDirectory $cwd
                    #         $global:requireProcesses += $process  # Track the process
                    #     }
                    # }

                    # Construct the full command with arguments
                    $fullCommand = "$command $commandArgs"
                    if ($additionalArgs -and $additionalArgs.Count -gt 0) {
                        $fullCommand += " " + ($additionalArgs -join ' ')
                    }
                    Write-Host "Running command: $fullCommand in directory: $(Get-Location)"

                    # Run the command
                    Invoke-Expression -Command $fullCommand

                    # Return to the original working directory
                    Set-Location -Path $originalDir

                }
                else {
                    Write-Host "The command format is not recognized."
                    exit 1
                }
            }finally {
                # Wait for all require processes to finish
                 if ($global:requireProcesses.Count -gt 0) {
                    Write-Host "Terminating prerequisite processes..."
                    $global:requireProcesses | ForEach-Object {
                        try {
                            if (-not $_.HasExited) {
                                $_.Kill()
                                Write-Host "Process $_ terminated."
                            }
                        } catch {
                            Write-Host "Failed to terminate process $_."
                        }
                    }
                }
            }
        }

        # Execute the command, passing the parentCwd
        RunCommand -commandToRun $commandToRun -parentCwd $parentCwd -additionalArgs $additionalArgs
    }
}
else {
    Write-Host "'quick_command' object not found or is not valid in the .dev_env.json file."
    exit 1
}
