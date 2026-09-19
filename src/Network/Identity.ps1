Set-StrictMode -Version Latest

function Get-AegisNetworkIdentity {
    [CmdletBinding()]
    param()

    $interfaces = @(Get-AegisNetworkInterfaces)
    $routes = @(Get-AegisDefaultRoutes)

    $vpn = @(Get-AegisVpnProvider)
    $tor = @(Get-AegisTorProvider)
    $proxy = @(Get-AegisProxyProvider)

    $identityType = "Direct"

    if ($vpn.Count -gt 0 -and $vpn[0].Available) {
        $identityType = "VPN-mediated"
    }
    elseif ($tor.Count -gt 0 -and $tor[0].Available) {
        $identityType = "Tor-capable"
    }
    elseif ($proxy.Count -gt 0 -and $proxy[0].Available) {
        $identityType = "Proxy-mediated"
    }

    [pscustomobject]@{
        Timestamp     = (Get-Date).ToUniversalTime().ToString("o")
        Host          = $env:COMPUTERNAME
        Interfaces    = $interfaces
        DefaultRoutes = $routes
        VPNDetected   = if ($vpn.Count -gt 0) { [bool]$vpn[0].Available } else { $false }
        TorDetected   = if ($tor.Count -gt 0) { [bool]$tor[0].Available } else { $false }
        ProxyDetected = if ($proxy.Count -gt 0) { [bool]$proxy[0].Available } else { $false }
        IdentityType  = $identityType
    }
}

function Get-AegisNetworkIdentityFingerprint {
    [CmdletBinding()]
    param()

    $identity = Get-AegisNetworkIdentity

    $interfaceMaterial = @()

    foreach ($interface in @($identity.Interfaces)) {

        if ($null -eq $interface) {
            continue
        }

        $alias = [string]$interface.InterfaceAlias
        $description = [string]$interface.Description
        $mac = [string]$interface.MacAddress

        $interfaceMaterial += "$alias|$description|$mac"
    }

    $routeMaterial = @()

    foreach ($route in @($identity.DefaultRoutes)) {

        if ($null -eq $route) {
            continue
        }

        $destination = ""
        $nextHop = ""
        $interfaceAlias = ""

        $property = $route.PSObject.Properties["DestinationPrefix"]
        if ($null -ne $property) {
            $destination = [string]$property.Value
        }

        $property = $route.PSObject.Properties["NextHop"]
        if ($null -ne $property) {
            $nextHop = [string]$property.Value
        }

        $property = $route.PSObject.Properties["InterfaceAlias"]
        if ($null -ne $property) {
            $interfaceAlias = [string]$property.Value
        }

        $routeMaterial += "$destination|$nextHop|$interfaceAlias"
    }

    $material = [ordered]@{
        Interfaces  = @($interfaceMaterial)
        Routes      = @($routeMaterial)
        IdentityType = [string]$identity.IdentityType
    }

    $json = $material | ConvertTo-Json -Compress -Depth 10
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)

    $sha = [Security.Cryptography.SHA256]::Create()

    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }

    # Compatible with Windows PowerShell / older .NET:
    # Convert each byte to a two-character hexadecimal representation.
    $hex = -join (
        $hash |
        ForEach-Object {
            $_.ToString("x2")
        }
    )

    return $hex
}
