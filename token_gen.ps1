$jsonFilePath = get_env_path
Write-Host "JSON file path = ${jsonFilePath}"

if (Test-Path $jsonFilePath) {
    $envVars = Get-Content $jsonFilePath | ConvertFrom-Json
}
else {
    Write-Host "The specified JSON file path does not exist."
    exit
}

$PrivateKeyFile = $envVars.private_key_file
$GatewayWebSocket = $envVars.gateway_websocket_url
$SshDestinationHost = $envVars.ssh_destination_host
$TelnetDestinationHost = $envVars.telnet_destination_host
$LdapDestinationHost = $envVars.ldap_destination_host
$LdapsDestinationHost = $envVars.ldaps_destination_host
$RdpDestinationHost = $envVars.rdp_destination_host
$WinrmDestinationHost = $envVars.winrm_destination_host
$KrbRealm = $envVars.krb_realm
$KrbKdc = $envVars.krb_kdc
$target = $envVars.target

# Write-Host "Private key file = ${PrivateKeyFile}"
# Write-Host "Gateway websocket url = ${GatewayWebSocket}"
# Write-Host "SSH destination host = ${SshDestinationHost}"
# Write-Host "Telnet destination host = ${TelnetDestinationHost}"
# Write-Host "RDP destination host = ${RdpDestinationHost}"
# Write-Host "Kerberos realm = ${KrbRealm}"
# Write-Host "Kerberos KDC = ${KrbKdc}"
# Write-Host "Target = ${target}"

$AssociationId = New-Guid
Write-Host "Association Id = ${AssociationId}"
Write-Host ""

function Generate-Token {
    if ($target -eq "ssh") {
        $DestinationHost = $SshDestinationHost
        $token = New-DGatewayToken -PrivateKeyFile $PrivateKeyFile -Type ASSOCIATION -ApplicationProtocol ssh -DestinationHost $DestinationHost -AssociationId $AssociationId -ExpirationTime (Get-Date).AddDays(7)
        Write-Host "SSH Host = ${DestinationHost}"
    }
    elseif ($target -eq "telnet") {
        $DestinationHost = $TelnetDestinationHost
        $token = New-DGatewayToken -PrivateKeyFile $PrivateKeyFile -Type ASSOCIATION -ApplicationProtocol unknown -DestinationHost $DestinationHost -ExpirationTime (Get-Date).AddDays(7)
        Write-Host "Telnet Host = ${DestinationHost}"
    }
    elseif ($target -eq "rdp") {
        $DestinationHost = $RdpDestinationHost
        $token = New-DGatewayToken -PrivateKeyFile $PrivateKeyFile -Type ASSOCIATION -ApplicationProtocol rdp -DestinationHost $DestinationHost -ExpirationTime (Get-Date).AddDays(7)
        Write-Host "RDP Host = ${DestinationHost}"
    }
    elseif ($target -eq "ldap") {
        $DestinationHost = $LdapDestinationHost
        $token = New-DGatewayToken -PrivateKeyFile $PrivateKeyFile -Type ASSOCIATION -ApplicationProtocol ldap -DestinationHost $DestinationHost -ExpirationTime (Get-Date).AddDays(7)
        Write-Host "LDAP Host = ${DestinationHost}"
    }
    elseif ($target -eq "ldaps") {
        $DestinationHost = $LdapsDestinationHost
        $token = New-DGatewayToken -PrivateKeyFile $PrivateKeyFile -Type ASSOCIATION -ApplicationProtocol ldaps -DestinationHost $DestinationHost -ExpirationTime (Get-Date).AddDays(7)
        Write-Host "LDAPS Host = ${DestinationHost}"
    }
    elseif ($target -eq "winrm-http-pwsh") {
        $DestinationHost = $WinrmDestinationHost
        $token = New-DGatewayToken -PrivateKeyFile $PrivateKeyFile -Type ASSOCIATION -ApplicationProtocol unknown -DestinationHost $DestinationHost -ExpirationTime (Get-Date).AddDays(7)
        Write-Host "WinRM Host = ${DestinationHost}"
    }
    else {
        Write-Host "Target not supported"
        exit
    }
    return $token
}
function Process-Token {
    param (
        [string]$gatewayAddress,
        [string]$token,
        [string]$type
    )

    $devolutionsGatewaySessionId = ''
    $parts = $token -split '\.'
    
    if ($null -ne $parts -and $parts.Length -gt 1 -and $null -ne $parts[1]) {
        $base64String = $parts[1]
        $padding = "=" * ((4 - ($base64String.Length % 4)) % 4)
        $base64String = $base64String + $padding

        try {
            $decodedBytes = [System.Convert]::FromBase64String($base64String)
            $decoded = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
            $decodedObject = ConvertFrom-Json -InputObject $decoded
            $devolutionsGatewaySessionId = $decodedObject.jet_aid
        }
        catch {
            Write-Error "There was an error decoding the token: $_"
            return $null
        }
    }
    else {
        Write-Error "The token is invalid"
        return $null
    }

    if ($type -ne 'kdc') {
        $returnValue = "$gatewayAddress/jet/fwd/tcp/$devolutionsGatewaySessionId`?token=$token"
        return $returnValue
    }
    else {
        $httpGatewayAddress = $gatewayAddress -replace 'ws', 'http'
        return "$httpGatewayAddress/jet/KdcProxy/$token"
    }
}

function Generate-KrbUrl {
    $krb_token = tokengen.exe --provisioner-key $PrivateKeyFile kdc --krb-realm $KrbRealm --krb-kdc $KrbKdc
    $krbUrl = "http://localhost:7171/jet/KdcProxy/$krb_token"
    return $krbUrl
}

$token = Generate-Token
$ProcessedURL = Process-Token -gatewayAddress $GatewayWebSocket -token $token -type $target
$krbUrl = Generate-KrbUrl

switch ($args[0]) {
    "copy" {
        switch ($args[1]) {
            "krb" {
                $krbUrl | Set-Clipboard
                Write-Host "Kerberos URL copied to clipboard."
            }
            "token" {
                $token | Set-Clipboard
                Write-Host "Connection token copied to clipboard."
            }
        }
    }
    "help" {
        Write-Host "Usage: script.ps1 [option]"
        Write-Host "`tOptions:"
        Write-Host "`t(no option) : Execute the default script behavior."
        Write-Host "`tcopy krb    : Copy the Kerberos URL to the clipboard."
        Write-Host "`tcopy token : Copy the connection token to the clipboard."
        Write-Host "`thelp       : Show this help message."
    }
    default {
        
        Write-Host "Krb URL: "
        Write-Host "$krbUrl"
        Write-Host ""
        Write-Host "Token: " 
        Write-Host "$token"
    }
}
