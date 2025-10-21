param (
    [string]$Editor = "code"  # Default to "code" if no parameter is provided
)

$Path = get_env_path

if ($null -eq $Path) {
    $Path = get_env_path
}

Write-Host "Found .dev_env.json file at $Path"

& $Editor $Path  # Invoke the editor with the $Path argument
