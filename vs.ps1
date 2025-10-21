$cwd = Get-Location
$slnFile = Get-ChildItem -Path $cwd -Filter *.sln -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
$sudo = $args -contains '--sudo'

# Path to Visual Studio executable
$devenvPath = "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\devenv.exe"

if (-not (Test-Path $devenvPath)) {
    Write-Host "Error: Visual Studio executable not found at $devenvPath."
    exit 1
}

if ($null -eq $slnFile) {
    Write-Host "No .sln file found in the current directory."
    exit 1
}

Write-Host "Opening solution file: $($slnFile.FullName)"

if ($sudo) {
    Write-Host "Running with administrator privileges..."
    Start-Process -FilePath $devenvPath -ArgumentList $slnFile.FullName -Verb RunAs
} else {
    Start-Process -FilePath $devenvPath -ArgumentList $slnFile.FullName
}
