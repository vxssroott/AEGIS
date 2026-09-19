Set-StrictMode -Version Latest

function Get-AegisTransportProviders {
    [CmdletBinding()]
    param()

    $results = @()

    # -------------------------
    # VPN / tunnel heuristics
    # -------------------------

    $adapters = @()
    try {
        $adapters = @(Get-NetAdapter -ErrorAction Stop)
    }
    catch {
        $adapters = @()
    }

    $vpnPatterns = @(
        'WireGuard',
        'Wintun',
        'TAP',
        'TUN',
        'OpenVPN',
        'Nord',
        'Proton',
        'Mullvad',
        'Tailscale',
        'ZeroTier',
        'WARP',
        'Cisco',
        'Forti',
        'GlobalProtect',
        'Pulse',
        'Hamachi',
        'Surfshark',
        'ExpressVPN',
        'Private Internet Access',
        'PIA',
        'Windscribe'
    )

    foreach ($adapter in $adapters) {
        $name = [string]$adapter.Name
        $description = [string]$adapter.InterfaceDescription

        $matched = $false
        $provider = 'Unknown'

        foreach ($pattern in $vpnPatterns) {
            if ($name -like "*$pattern*" -or $description -like "*$pattern*") {
                $matched = $true
                $provider = $pattern
                break
            }
        }

        if ($matched) {
            $results += New-AegisTransportDescriptor `
                -Id ("vpn-" + $adapter.ifIndex) `
                -Kind 'vpn' `
                -Provider $provider `
                -DisplayName $name `
                -Available $true `
                -Active ([string]$adapter.Status -eq 'Up') `
                -Verified $false `
                -Priority 10
        }
    }

    # -------------------------
    # Tor local endpoint
    # -------------------------

    $torPorts = @(9050, 9150)
    $torListening = $false

    try {
        $connections = @(Get-NetTCPConnection -State Listen -ErrorAction Stop)

        foreach ($port in $torPorts) {
            if (@($connections | Where-Object LocalPort -eq $port).Count -gt 0) {
                $torListening = $true
                break
            }
        }
    }
    catch {
    }

    $results += New-AegisTransportDescriptor `
        -Id 'tor-local' `
        -Kind 'tor' `
        -Provider 'Tor' `
        -DisplayName 'Tor local SOCKS endpoint' `
        -Available $torListening `
        -Active $torListening `
        -Verified $false `
        -Priority 20

    # -------------------------
    # WinHTTP proxy
    # -------------------------

    $proxyOutput = ''
    try {
        $proxyOutput = (& netsh winhttp show proxy 2>$null | Out-String)
    }
    catch {
        $proxyOutput = ''
    }

    $proxyActive =
        ($proxyOutput -notmatch 'Direct access') -and
        (-not [string]::IsNullOrWhiteSpace($proxyOutput))

    $results += New-AegisTransportDescriptor `
        -Id 'proxy-winhttp' `
        -Kind 'proxy' `
        -Provider 'WinHTTP' `
        -DisplayName 'Windows WinHTTP proxy' `
        -Available $true `
        -Active $proxyActive `
        -Verified $false `
        -Priority 30

    return @($results | Sort-Object Priority, Provider, Id)
}
