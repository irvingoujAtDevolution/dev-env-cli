# Check if the current session is running as administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Relaunch PowerShell with administrator privileges
    Start-Process pwsh -Verb RunAs -ArgumentList "-NoProfile", "-NoExit", "-Command", "cd `\`"
    exit
}

# Code to execute when already running as administrator
Write-Host "PowerShell session is running with administrator privileges."

