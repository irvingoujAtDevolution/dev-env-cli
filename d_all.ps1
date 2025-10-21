# this is for NativeSession only
#  C:\Users\jou\code\NativeSessions\Protocols\Rdp\Devolutions.Rdp.Windows
#  C:\Users\jou\code\NativeSessions\Protocols\Rdp\Devolutions.IronRdp.Windows
# C:\Users\jou\code\NativeSessions\Common\Devolutions.Sessions.Windows
# C:\Users\jou\code\NativeSessions\Renderer\Devolutions.Renderer.Windows

# command to run: d build;d pack, d push
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

$directories = 'C:\Users\jou\code\NativeSessions\Protocols\Rdp\Devolutions.Rdp.Windows','C:\Users\jou\code\NativeSessions\Protocols\Rdp\Devolutions.IronRdp.Windows','C:\Users\jou\code\NativeSessions\Common\Devolutions.Sessions.Windows','C:\Users\jou\code\NativeSessions\Renderer\Devolutions.Renderer.Windows'

foreach ($directory in $directories) {
    Write-Host "Building, packing and pushing $directory" -ForegroundColor DarkGreen
    Set-Location $directory
    d build
    d pack
    d push
    Write-Host "$directory is done" -ForegroundColor DarkGreen 
}

$localtionToInstall = 'C:\dev\RDM\Windows\RemoteDesktopManager\Core'
Write-Host "installing package for $localtionToInstall" -ForegroundColor DarkGreen 
Set-Location $localtionToInstall
dotnet add package Devolutions.Rdp.Windows;dotnet add package Devolutions.Renderer.Windows;dotnet add package Devolutions.IronRdp.Windows
Write-Host "done" -ForegroundColor DarkGreen
