Set-StrictMode -Version Latest

$script:AegisPhase51RuntimeRoot =
    Join-Path $PSScriptRoot '..\..\data\network'

New-Item -ItemType Directory -Force `
    -Path $script:AegisPhase51RuntimeRoot | Out-Null

function Get-AegisExternalIPv4 {
    [CmdletBinding()]
    param(
        [int]$TimeoutSec = 8
    )

    $endpoints = @(
        'https://api.ipify.org?format=json'
        'https://ipv4.icanhazip.com'
        'https://ifconfig.me/ip'
    )

    $observations = @()

    foreach ($endpoint in $endpoints) {

        try {
            $response = Invoke-RestMethod `
                -Uri $endpoint `
                -Method Get `
                -TimeoutSec $TimeoutSec `
                -UseBasicParsing `
                -ErrorAction Stop

            $value = $null

            if ($response -is [string]) {
                $value = $response.Trim()
            }
            elseif ($null -ne $response.ip) {
                $value = [string]$response.ip
            }
            elseif ($null -ne $response.IP) {
                $value = [string]$response.IP
            }

            $parsed = $null

            if ([System.Net.IPAddress]::TryParse($value, [ref]$parsed)) {

                if ($parsed.AddressFamily -eq
                    [System.Net.Sockets.AddressFamily]::InterNetwork) {

                    $observations += [pscustomobject]@{
                        Endpoint = $endpoint
                        Address  = $value
                        Success  = $true
                    }

                    continue
                }
            }

            $observations += [pscustomobject]@{
                Endpoint = $endpoint
                Address  = $null
                Success  = $false
                Error    = 'Endpoint returned a non-IPv4 value.'
            }
        }
        catch {

            $observations += [pscustomobject]@{
                Endpoint = $endpoint
                Address  = $null
                Success  = $false
                Error    = $_.Exception.Message
            }
        }
    }

    $valid = @(
        $observations |
            Where-Object {
                $_.Success -eq $true -and
                -not [string]::IsNullOrWhiteSpace([string]$_.Address)
            }
    )

    $groups = @(
        $valid |
            Group-Object Address |
            Sort-Object Count -Descending
    )

    $consensus = $null
    $consensusCount = 0

    if ($groups.Count -gt 0) {
        $consensus = [string]$groups[0].Name
        $consensusCount = [int]$groups[0].Count
    }

    $consistent = (
        $valid.Count -gt 0 -and
        $groups.Count -eq 1
    )

    return [pscustomobject]@{
        Address         = $consensus
        SuccessfulTests = $valid.Count
        EndpointCount   = $observations.Count
        ConsensusCount  = $consensusCount
        Consistent      = $consistent
        Observations    = @($observations)
        Timestamp       = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Get-AegisExternalIPv6 {
    [CmdletBinding()]
    param(
        [int]$TimeoutSec = 8
    )

    $endpoints = @(
        'https://api64.ipify.org?format=json'
        'https://ifconfig.co/ip'
    )

    $observations = @()

    foreach ($endpoint in $endpoints) {

        try {
            $response = Invoke-RestMethod `
                -Uri $endpoint `
                -Method Get `
                -TimeoutSec $TimeoutSec `
                -UseBasicParsing `
                -ErrorAction Stop

            $value = $null

            if ($response -is [string]) {
                $value = $response.Trim()
            }
            elseif ($null -ne $response.ip) {
                $value = [string]$response.ip
            }

            $parsed = $null

            if ([System.Net.IPAddress]::TryParse($value, [ref]$parsed)) {

                if ($parsed.AddressFamily -eq
                    [System.Net.Sockets.AddressFamily]::InterNetworkV6) {

                    $observations += [pscustomobject]@{
                        Endpoint = $endpoint
                        Address  = $value
                        Success  = $true
                    }

                    continue
                }
            }

            $observations += [pscustomobject]@{
                Endpoint = $endpoint
                Address  = $null
                Success  = $false
                Error    = 'No globally reachable IPv6 identity returned.'
            }
        }
        catch {

            $observations += [pscustomobject]@{
                Endpoint = $endpoint
                Address  = $null
                Success  = $false
                Error    = $_.Exception.Message
            }
        }
    }

    $valid = @(
        $observations |
            Where-Object {
                $_.Success -eq $true -and
                -not [string]::IsNullOrWhiteSpace([string]$_.Address)
            }
    )

    $groups = @(
        $valid |
            Group-Object Address |
            Sort-Object Count -Descending
    )

    $consensus = $null
    $consensusCount = 0

    if ($groups.Count -gt 0) {
        $consensus = [string]$groups[0].Name
        $consensusCount = [int]$groups[0].Count
    }

    return [pscustomobject]@{
        Address         = $consensus
        SuccessfulTests = $valid.Count
        EndpointCount   = $observations.Count
        ConsensusCount  = $consensusCount
        Consistent      = (
            $valid.Count -gt 0 -and
            $groups.Count -eq 1
        )
        Observations    = @($observations)
        Timestamp       = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Get-AegisLocalIPv4 {
    [CmdletBinding()]
    param()

    $results = @()

    try {
        $adapters = @(Get-NetIPAddress `
            -AddressFamily IPv4 `
            -ErrorAction Stop)

        foreach ($adapter in $adapters) {

            $address = [string]$adapter.IPAddress

            if ([string]::IsNullOrWhiteSpace($address)) {
                continue
            }

            if ($address -eq '127.0.0.1') {
                continue
            }

            $results += [pscustomobject]@{
                Address        = $address
                InterfaceIndex = $adapter.InterfaceIndex
                PrefixLength   = $adapter.PrefixLength
                Type           = [string]$adapter.PrefixOrigin
            }
        }
    }
    catch {
    }

    return @($results)
}

function Get-AegisLocalIPv6 {
    [CmdletBinding()]
    param()

    $results = @()

    try {
        $addresses = @(Get-NetIPAddress `
            -AddressFamily IPv6 `
            -ErrorAction Stop)

        foreach ($entry in $addresses) {

            $address = [string]$entry.IPAddress

            if ([string]::IsNullOrWhiteSpace($address)) {
                continue
            }

            if ($address -eq '::1') {
                continue
            }

            if ($address -like 'fe80:*') {
                continue
            }

            $results += [pscustomobject]@{
                Address        = $address
                InterfaceIndex = $entry.InterfaceIndex
                PrefixLength   = $entry.PrefixLength
                Type           = [string]$entry.PrefixOrigin
            }
        }
    }
    catch {
    }

    return @($results)
}

function Test-AegisIPv6Correlation {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()]
        [object[]]$LocalIPv6,

        [Parameter(Mandatory)]
        [object]$ExternalIPv6
    )

    $globalLocal = @($LocalIPv6)

    if ($globalLocal.Count -eq 0) {

        return [pscustomobject]@{
            Status  = 'NO_LOCAL_GLOBAL_IPV6'
            Passed  = $true
            Detail  = 'No globally routable local IPv6 address was detected.'
        }
    }

    if ([string]::IsNullOrWhiteSpace(
        [string]$ExternalIPv6.Address
    )) {

        return [pscustomobject]@{
            Status  = 'EXTERNAL_IPV6_UNAVAILABLE'
            Passed  = $false
            Detail  = 'Global local IPv6 exists but external IPv6 identity could not be established.'
        }
    }

    $external = [string]$ExternalIPv6.Address

    $matchingPrefix = $false

    foreach ($local in $globalLocal) {

        $localAddress = [string]$local.Address

        $localParts = $localAddress.Split(':')
        $externalParts = $external.Split(':')

        if ($localParts.Count -ge 2 -and
            $externalParts.Count -ge 2) {

            if (
                $localParts[0] -eq $externalParts[0] -and
                $localParts[1] -eq $externalParts[1]
            ) {
                $matchingPrefix = $true
                break
            }
        }
    }

    if ($matchingPrefix) {

        return [pscustomobject]@{
            Status  = 'DIRECT_IPV6_CORRELATION'
            Passed  = $false
            Detail  = 'The externally observed IPv6 identity correlates with a local global IPv6 prefix.'
        }
    }

    return [pscustomobject]@{
        Status  = 'IPV6_PATH_MISMATCH'
        Passed  = $true
        Detail  = 'External IPv6 identity does not directly correlate with the detected local global IPv6 prefixes.'
    }
}

function Get-AegisDnsPathVerification {
    [CmdletBinding()]
    param(
        [int]$TimeoutMs = 3000
    )

    $servers = @()

    try {
        $dnsObjects = @(
            Get-DnsClientServerAddress `
                -AddressFamily IPv4 `
                -ErrorAction Stop
        )

        foreach ($object in $dnsObjects) {

            foreach ($server in @($object.ServerAddresses)) {

                if ([string]::IsNullOrWhiteSpace([string]$server)) {
                    continue
                }

                $servers += [pscustomobject]@{
                    InterfaceIndex = $object.InterfaceIndex
                    Server         = [string]$server
                }
            }
        }
    }
    catch {
    }

    $servers = @(
        $servers |
            Sort-Object Server, InterfaceIndex -Unique
    )

    $checks = @()

    foreach ($server in $servers) {

        $resolved = $false
        $detail = ''

        try {

            $query = Resolve-DnsName `
                -Name 'example.com' `
                -Type A `
                -Server $server.Server `
                -DnsOnly `
                -NoHostsFile `
                -ErrorAction Stop

            if (@($query).Count -gt 0) {
                $resolved = $true
                $detail = 'Resolver answered successfully.'
            }
            else {
                $detail = 'Resolver returned no answer.'
            }
        }
        catch {
            $detail = $_.Exception.Message
        }

        $checks += [pscustomobject]@{
            Server         = $server.Server
            InterfaceIndex = $server.InterfaceIndex
            Reachable      = $resolved
            Detail         = $detail
        }
    }

    $reachable = @(
        $checks |
            Where-Object Reachable
    )

    $healthy = (
        $servers.Count -gt 0 -and
        $reachable.Count -gt 0
    )

    return [pscustomobject]@{
        Healthy          = $healthy
        ConfiguredServers = @($servers)
        Checks           = @($checks)
        ReachableServers  = @($reachable)
        Timestamp        = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Test-AegisExternalIdentityConsensus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$IPv4,

        [Parameter(Mandatory)]
        [object]$IPv6
    )

    $checks = @()

    $ipv4Passed = (
        $IPv4.SuccessfulTests -ge 2 -and
        $IPv4.Consistent -eq $true
    )

    $checks += [pscustomobject]@{
        Check  = 'ExternalIPv4Consensus'
        Passed = $ipv4Passed
        Detail = if ($ipv4Passed) {
            "IPv4 identity $($IPv4.Address) was independently observed by $($IPv4.SuccessfulTests) endpoint(s)."
        }
        else {
            'External IPv4 identity did not achieve multi-endpoint consensus.'
        }
    }

    if ($IPv6.SuccessfulTests -gt 0) {

        $ipv6Passed = (
            $IPv6.SuccessfulTests -ge 2 -and
            $IPv6.Consistent -eq $true
        )

        $checks += [pscustomobject]@{
            Check  = 'ExternalIPv6Consensus'
            Passed = $ipv6Passed
            Detail = if ($ipv6Passed) {
                "IPv6 identity $($IPv6.Address) was independently observed."
            }
            else {
                'IPv6 identity was observed but did not achieve multi-endpoint consensus.'
            }
        }
    }
    else {

        $checks += [pscustomobject]@{
            Check  = 'ExternalIPv6Consensus'
            Passed = $true
            Detail = 'No externally reachable IPv6 identity was observed.'
        }
    }

    $overall = @(
        $checks |
            Where-Object {
                $_.Check -eq 'ExternalIPv4Consensus'
            }
    )

    $passed = (
        $overall.Count -eq 1 -and
        $overall[0].Passed -eq $true
    )

    return [pscustomobject]@{
        Passed     = $passed
        Checks     = @($checks)
        Timestamp  = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Invoke-AegisPhase51ExternalVerification {
    [CmdletBinding()]
    param(
        [switch]$Persist
    )

    $ipv4 = Get-AegisExternalIPv4
    $ipv6 = Get-AegisExternalIPv6

    $localIPv4 = @(Get-AegisLocalIPv4)
    $localIPv6 = @(Get-AegisLocalIPv6)

    $ipv6Correlation = Test-AegisIPv6Correlation `
        -LocalIPv6 $localIPv6 `
        -ExternalIPv6 $ipv6

    $dns = Get-AegisDnsPathVerification

    $identity = Test-AegisExternalIdentityConsensus `
        -IPv4 $ipv4 `
        -IPv6 $ipv6

    $transportState = $null

    try {
        $transportState = Get-AegisTransportState
    }
    catch {
        $transportState = [pscustomobject]@{
            State    = 'Unknown'
            ActiveId = $null
            Verified = $false
        }
    }

    $providerSnapshot = @()

    try {
        $providerSnapshot = @(Get-AegisTransportProviders)
    }
    catch {
        $providerSnapshot = @()
    }

    $activeProviders = @(
        $providerSnapshot |
            Where-Object {
                $_.Active -eq $true
            }
    )

    $verifiedProviders = @(
        $providerSnapshot |
            Where-Object {
                $_.Verified -eq $true
            }
    )

    $verificationChecks = @()

    $verificationChecks += [pscustomobject]@{
        Check  = 'ExternalIPv4Identity'
        Passed = (
            $ipv4.SuccessfulTests -ge 2 -and
            $ipv4.Consistent
        )
        Detail = if ($ipv4.Address) {
            "Observed external IPv4 identity: $($ipv4.Address)."
        }
        else {
            'External IPv4 identity unavailable.'
        }
    }

    $verificationChecks += [pscustomobject]@{
        Check  = 'DNSPathReachability'
        Passed = $dns.Healthy
        Detail = if ($dns.Healthy) {
            "$($dns.ReachableServers.Count) configured DNS resolver(s) answered."
        }
        else {
            'No configured DNS resolver successfully answered the validation query.'
        }
    }

    $verificationChecks += [pscustomobject]@{
        Check  = 'IPv6Boundary'
        Passed = $ipv6Correlation.Passed
        Detail = $ipv6Correlation.Detail
    }

    $verificationChecks += [pscustomobject]@{
        Check  = 'TransportTrust'
        Passed = [bool]$transportState.Verified
        Detail = if ($transportState.Verified) {
            'Current transport state is trusted.'
        }
        else {
            'Current transport has not passed provider-level trust verification.'
        }
    }

    $verificationChecks += [pscustomobject]@{
        Check  = 'CryptographicTunnelProof'
        Passed = $false
        Detail = 'Provider-specific cryptographic proof remains pending.'
    }

    $verificationChecks += [pscustomobject]@{
        Check  = 'ProviderAccountProof'
        Passed = $false
        Detail = 'Provider account/session proof remains pending.'
    }

    $verificationChecks += [pscustomobject]@{
        Check  = 'RouteBindingProof'
        Passed = $false
        Detail = 'Provider-specific route binding proof remains pending.'
    }

    $identityTrusted = (
        $identity.Passed -and
        $dns.Healthy -and
        $ipv6Correlation.Passed
    )

    $result = [pscustomobject]@{
        Version = '5.1'

        Timestamp = (Get-Date).ToUniversalTime().ToString('o')

        Verdict = if ($identityTrusted) {
            'EXTERNAL_BOUNDARY_OBSERVED'
        }
        else {
            'EXTERNAL_BOUNDARY_UNVERIFIED'
        }

        Identity = [pscustomobject]@{
            IPv4 = $ipv4
            IPv6 = $ipv6
            LocalIPv4 = @($localIPv4)
            LocalIPv6 = @($localIPv6)
            Consensus = $identity
        }

        DNS = $dns

        IPv6Correlation = $ipv6Correlation

        Transport = [pscustomobject]@{
            State            = $transportState
            Providers        = @($providerSnapshot)
            ActiveProviders  = @($activeProviders)
            VerifiedProviders = @($verifiedProviders)
        }

        Verification = [pscustomobject]@{
            Passed = $identityTrusted
            Checks = @($verificationChecks)
        }

        CapabilityStatus = [pscustomobject]@{
            ExternalIPv4Correlation = $true
            ExternalIPv6Correlation = $true
            DNSPathCorrelation      = $true
            CryptographicProof      = $false
            ProviderAccountProof    = $false
            RouteBindingProof       = $false
            AutomaticHandoff        = $false
            AutomaticRotation       = $false
            FailClosed              = $false
        }

        Mutation = [pscustomobject]@{
            RoutesModified   = $false
            DNSModified      = $false
            FirewallModified = $false
            VPNModified      = $false
            ProxyModified    = $false
            TorModified      = $false
        }
    }

    if ($Persist) {

        $path = Join-Path `
            $script:AegisPhase51RuntimeRoot `
            'phase5.1-external-verification-last.json'

        $result |
            ConvertTo-Json -Depth 20 |
            Set-Content -LiteralPath $path -Encoding UTF8
    }

    return $result
}

