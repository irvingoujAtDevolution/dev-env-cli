param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path
)

try {
    $trashDir = "C:\Temp\Trash_" + (Get-Date -Format "yyyyMMdd_HHmmss")
        
    if (-not (Test-Path -Path $Path)) {
        throw "Source path does not exist: $Path"
    }

    # Create temp directory if it doesn't exist
    if (-not (Test-Path -Path "C:\Temp")) {
        New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
    }

    Move-Item -Path $Path -Destination $trashDir
    Start-Job -ScriptBlock { 
        param($dir) 
        Remove-Item -Path $dir -Recurse -Force 
    } -ArgumentList $trashDir
}
catch {
    Write-Error "Failed to move item to trash: $_"
}
