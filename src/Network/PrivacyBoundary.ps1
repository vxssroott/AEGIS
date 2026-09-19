Set-StrictMode -Version Latest

function Get-AegisNetworkPrivacyBoundary {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\config\network.json')
    )

    $config = $null

    if (Test-Path $ConfigPath) {
        try {
            $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        }
        catch {
            $config = $null
        }
    }

    $vpnRequired = $false
    $dnsPolicy = 'system'
    $ipv6Policy = 'allow'
    $proxyPolicy = 'system'
    $torEnabled = $false

    if ($null -ne $config) {
        if ($null -ne $config.vpn) {
            if ($null -ne $config.vpn.required) {
                $vpnRequired = [bool]$config.vpn.required
            }
        }

        if ($null -ne $config.dns) {
            if ($null -ne $config.dns.policy) {
                $dnsPolicy = [string]$config.dns.policy
            }
        }

        if ($null -ne $config.ipv6) {
            if ($null -ne $config.ipv6.policy) {
                $ipv6Policy = [string]$config.ipv6.policy
            }
        }

        if ($null -ne $config.proxy) {
            if ($null -ne $config.proxy.policy) {
                $proxyPolicy = [string]$config.proxy.policy
            }
        }

        if ($null -ne $config.tor) {
            if ($null -ne $config.tor.enabled) {
                $torEnabled = [bool]$config.tor.enabled
            }
        }
    }

    [pscustomobject]@{
        SchemaVersion = '1.2'
        VPNRequired   = $vpnRequired
        DNSPolicy     = $dnsPolicy
        IPv6Policy    = $ipv6Policy
        ProxyPolicy   = $proxyPolicy
        TorEnabled    = $torEnabled
        TimestampUtc  = [DateTime]::UtcNow.ToString('o')
    }
}

function Test-AegisDNSBoundary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$DNSServers,

        [Parameter(Mandatory)]
        [object]$Boundary,

        [bool]$VPNDetected = $false
    )

    $results = @()

    foreach ($dns in @($DNSServers)) {
        $server = [string]$dns.Server
        $classification = [string]$dns.Classification

        $status = 'PASS'
        $reason = 'DNS server is compatible with current privacy boundary.'

        if ($Boundary.DNSPolicy -eq 'private' -and $classification -eq 'PUBLIC_DNS') {
            $status = 'EXPOSURE'
            $reason = 'Public DNS server violates private DNS policy.'
        }
        elseif ($Boundary.VPNRequired -and -not $VPNDetected) {
            $status = 'EXPOSURE'
            $reason = 'VPN-required boundary is not currently established.'
        }

        $results += [pscustomobject]@{
            Server         = $server
            Classification = $classification
            Status         = $status
            Reason         = $reason
            Policy         = [string]$Boundary.DNSPolicy
        }
    }

    return @($results)
}

function Get-AegisNetworkBoundaryVerdict {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Boundary,

        [Parameter(Mandatory)]
        [object[]]$DNSResults,

        [Parameter(Mandatory)]
        [object[]]$ExternalResults,

        [bool]$VPNDetected = $false,

        [bool]$IPv6Detected = $false
    )

    $violations = @()

    if ($Boundary.VPNRequired -and -not $VPNDetected) {
        $violations += [pscustomobject]@{
            Type = 'VPN'
            Severity = 'High'
            Reason = 'Privacy boundary requires VPN but no VPN-like interface is detected.'
        }
    }

    foreach ($dns in @($DNSResults)) {
        if ([string]$dns.Status -eq 'EXPOSURE') {
            $violations += [pscustomobject]@{
                Type = 'DNS'
                Severity = 'High'
                Reason = [string]$dns.Reason
            }
        }
    }

    if ($Boundary.IPv6Policy -eq 'block' -and $IPv6Detected) {
        $violations += [pscustomobject]@{
            Type = 'IPv6'
            Severity = 'High'
            Reason = 'Global IPv6 exposure violates IPv6 block policy.'
        }
    }

    $externalIPv4 = @(
        $ExternalResults |
        Where-Object {
            [string]$_.Type -eq 'IPv4' -and
            [bool]$_.Valid
        }
    )

    if ($Boundary.VPNRequired -and $externalIPv4.Count -gt 0 -and -not $VPNDetected) {
        $violations += [pscustomobject]@{
            Type = 'EXTERNAL_IPV4'
            Severity = 'High'
            Reason = 'External IPv4 is reachable while the required VPN boundary is absent.'
        }
    }

    $verdict = if ($violations.Count -eq 0) {
        'BOUNDARY_COMPLIANT'
    }
    else {
        'BOUNDARY_VIOLATION'
    }

    [pscustomobject]@{
        Verdict      = $verdict
        Compliant    = ($violations.Count -eq 0)
        ViolationCount = $violations.Count
        Violations   = @($violations)
        TimestampUtc = [DateTime]::UtcNow.ToString('o')
    }
}
