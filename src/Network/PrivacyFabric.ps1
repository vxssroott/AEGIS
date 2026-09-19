Set-StrictMode -Version Latest

function Get-AegisNetworkPrivacyFabric {
    [CmdletBinding()]
    param()

    $interfaces = @()
    $routes = @()
    $dns = @()
    $leaks = @()
    $vpn = @()
    $proxy = @()
    $ipConfig = @()

    try {
        if (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue) {
            $interfaces = @(Get-NetAdapter -ErrorAction SilentlyContinue |
                Where-Object { $_.Status -eq "Up" } |
                Select-Object Name, InterfaceDescription, ifIndex, MacAddress, LinkSpeed, Status)
        }
    } catch {
        $interfaces = @()
    }

    try {
        if (Get-Command Get-NetRoute -ErrorAction SilentlyContinue) {
            $routes = @(Get-NetRoute -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Where-Object { $_.State -ne "Invalid" } |
                Select-Object DestinationPrefix, NextHop, InterfaceIndex, RouteMetric, State)
        }
    } catch {
        $routes = @()
    }

    try {
        if (Get-Command Get-DnsClientServerAddress -ErrorAction SilentlyContinue) {
            $dns = @(Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Where-Object {
                    @($_.ServerAddresses).Count -gt 0
                } |
                Select-Object InterfaceAlias, InterfaceIndex, ServerAddresses)
        }
    } catch {
        $dns = @()
    }

    try {
        if (Get-Command Get-NetIPConfiguration -ErrorAction SilentlyContinue) {
            $ipConfig = @(Get-NetIPConfiguration -ErrorAction SilentlyContinue |
                Where-Object { $_.InterfaceAlias } |
                Select-Object InterfaceAlias,
                              InterfaceIndex,
                              IPv4Address,
                              IPv6Address,
                              IPv4DefaultGateway,
                              DNSServer)

            foreach ($item in $ipConfig) {
                $ipv6 = @($item.IPv6Address)

                if ($ipv6.Count -gt 0) {
                    foreach ($address in $ipv6) {
                        if ($null -ne $address) {
                            $leaks += [pscustomobject]@{
                                Type       = "IPv6"
                                Interface  = $item.InterfaceAlias
                                Exposure   = [string]$address
                                Severity   = "Info"
                                Remediable = $false
                            }
                        }
                    }
                }
            }
        }
    } catch {
        $ipConfig = @()
    }

    # --------------------------------------------------------
    # VPN interface heuristics
    # --------------------------------------------------------

    foreach ($interface in @($interfaces)) {

        $name = [string]$interface.Name
        $description = [string]$interface.InterfaceDescription

        if (
            $name -match "VPN|TAP|TUN|WireGuard|Wintun|OpenVPN|Nord|Proton|Mullvad|Cisco|AnyConnect|Forti|GlobalProtect" -or
            $description -match "VPN|TAP|TUN|WireGuard|Wintun|OpenVPN|Nord|Proton|Mullvad|Cisco|AnyConnect|Forti|GlobalProtect"
        ) {
            $vpn += [pscustomobject]@{
                Interface   = $name
                Description = $description
                Detected    = $true
                Confidence  = "heuristic"
            }
        }
    }

    # --------------------------------------------------------
    # WinHTTP proxy state
    # --------------------------------------------------------

    try {
        $proxyOutput = @(netsh winhttp show proxy 2>$null) -join "`n"

        $proxyDetected = $proxyOutput -notmatch "Direct access \(no proxy server\)"

        $proxy = @(
            [pscustomobject]@{
                Detected      = [bool]$proxyDetected
                Source        = "WinHTTP"
                Configuration = $proxyOutput.Trim()
                Confidence    = "system"
            }
        )
    } catch {
        $proxy = @()
    }

    # --------------------------------------------------------
    # DNS exposure observations
    # --------------------------------------------------------

    foreach ($entry in @($dns)) {

        foreach ($server in @($entry.ServerAddresses)) {

            if ([string]::IsNullOrWhiteSpace([string]$server)) {
                continue
            }

            $serverString = [string]$server

            $private = (
                $serverString -match "^10\." -or
                $serverString -match "^192\.168\." -or
                $serverString -match "^172\.(1[6-9]|2[0-9]|3[0-1])\." -or
                $serverString -eq "127.0.0.1" -or
                $serverString -eq "::1"
            )

            $leaks += [pscustomobject]@{
                Type       = "DNS"
                Interface  = [string]$entry.InterfaceAlias
                Exposure   = $serverString
                Severity   = if ($private) { "Low" } else { "Medium" }
                Remediable = $true
            }
        }
    }

    # Explicitly force every collection to remain an array.
    $interfaces = @($interfaces)
    $routes     = @($routes)
    $dns        = @($dns)
    $vpn        = @($vpn)
    $proxy      = @($proxy)
    $leaks      = @($leaks)
    $ipConfig   = @($ipConfig)

    $dnsServerCount = 0

    foreach ($entry in $dns) {
        $dnsServerCount += @($entry.ServerAddresses).Count
    }

    [pscustomobject]@{
        Timestamp  = (Get-Date).ToUniversalTime().ToString("o")
        Interfaces = @($interfaces)
        Routes     = @($routes)
        DNS        = @($dns)
        VPN        = @($vpn)
        Proxy      = @($proxy)
        Exposures  = @($leaks)

        Summary = [pscustomobject]@{
            Interfaces    = [int]$interfaces.Count
            Routes        = [int]$routes.Count
            DNSServers    = [int]$dnsServerCount
            VPNDetected   = [bool]($vpn.Count -gt 0)
            ProxyDetected = [bool](@($proxy | Where-Object { $_.Detected }).Count -gt 0)
            IPv6Detected  = [bool](@($leaks | Where-Object { $_.Type -eq "IPv6" }).Count -gt 0)
            ExposureCount = [int]$leaks.Count
        }
    }
}

function Test-AegisNetworkPrivacyFabric {
    [CmdletBinding()]
    param()

    $fabric = Get-AegisNetworkPrivacyFabric

    $checks = @(
        [pscustomobject]@{
            Id     = "network.interfaces"
            Status = if ([int]$fabric.Summary.Interfaces -gt 0) { "PASS" } else { "WARN" }
            Detail = "$($fabric.Summary.Interfaces) active interface(s)"
        }

        [pscustomobject]@{
            Id     = "network.routes"
            Status = if ([int]$fabric.Summary.Routes -gt 0) { "PASS" } else { "WARN" }
            Detail = "$($fabric.Summary.Routes) valid IPv4 route(s)"
        }

        [pscustomobject]@{
            Id     = "network.dns"
            Status = if ([int]$fabric.Summary.DNSServers -gt 0) { "PASS" } else { "WARN" }
            Detail = "$($fabric.Summary.DNSServers) DNS server(s)"
        }

        [pscustomobject]@{
            Id     = "network.vpn"
            Status = if ([bool]$fabric.Summary.VPNDetected) { "DETECTED" } else { "NOT_DETECTED" }
            Detail = if ([bool]$fabric.Summary.VPNDetected) {
                "VPN-like interface detected by heuristic"
            } else {
                "No VPN-like interface detected"
            }
        }

        [pscustomobject]@{
            Id     = "network.proxy"
            Status = if ([bool]$fabric.Summary.ProxyDetected) { "DETECTED" } else { "NOT_DETECTED" }
            Detail = if ([bool]$fabric.Summary.ProxyDetected) {
                "WinHTTP proxy detected"
            } else {
                "No WinHTTP proxy detected"
            }
        }

        [pscustomobject]@{
            Id     = "network.ipv6"
            Status = if ([bool]$fabric.Summary.IPv6Detected) { "EXPOSED" } else { "NOT_DETECTED" }
            Detail = if ([bool]$fabric.Summary.IPv6Detected) {
                "IPv6 addressing detected"
            } else {
                "No IPv6 exposure detected"
            }
        }
    )

    $checks = @($checks)

    $exposedCount = @(
        $checks | Where-Object { $_.Status -eq "EXPOSED" }
    ).Count

    $warningCount = @(
        $checks | Where-Object { $_.Status -eq "WARN" }
    ).Count

    $status = if ($exposedCount -gt 0) {
        "EXPOSED"
    }
    elseif ($warningCount -gt 0) {
        "WARN"
    }
    else {
        "PASS"
    }

    [pscustomobject]@{
        Timestamp = $fabric.Timestamp
        Checks    = @($checks)
        Fabric    = $fabric
        Status    = $status
    }
}

function Invoke-AegisNetworkPrivacyCommand {
    [CmdletBinding()]
    param(
        [ValidateSet(
            "fabric",
            "audit",
            "leaks",
            "dns",
            "routes",
            "vpn",
            "proxy"
        )]
        [string]$Action = "fabric"
    )

    $result = Test-AegisNetworkPrivacyFabric

    switch ($Action) {
        "fabric" { return $result }
        "audit"  { return @($result.Checks) }
        "leaks"  { return @($result.Fabric.Exposures) }
        "dns"    { return @($result.Fabric.DNS) }
        "routes" { return @($result.Fabric.Routes) }
        "vpn"    { return @($result.Fabric.VPN) }
        "proxy"  { return @($result.Fabric.Proxy) }
    }
}
