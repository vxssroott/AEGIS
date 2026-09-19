Set-StrictMode -Version Latest

function Test-AegisNetworkLeaks {
    [CmdletBinding()]
    param()

    # ---------------------------------------------------------------------
    # Plain PowerShell collections only.
    # Avoid generic .NET collections and implicit property enumeration.
    # ---------------------------------------------------------------------

    $issues = @()
    $ipv6Global = @()

    # ---------------------------------------------------------------------
    # DNS
    # ---------------------------------------------------------------------

    $dns = Test-AegisDnsConfiguration

    $dnsHealthy = $true

    if ($null -ne $dns) {
        $healthyProperty = $dns.PSObject.Properties["Healthy"]

        if ($null -ne $healthyProperty) {
            $dnsHealthy = [bool]$healthyProperty.Value
        }
    }

    if (-not $dnsHealthy) {
        $issues += [pscustomobject]@{
            Type     = "DNS"
            Severity = "High"
            Detail   = "DNS configuration contains invalid or suspicious endpoints."
        }
    }

    # ---------------------------------------------------------------------
    # ROUTES
    # ---------------------------------------------------------------------

    $routes = @(Get-AegisDefaultRoutes)

    $publicRouteCount = 0

    foreach ($route in $routes) {

        if ($null -eq $route) {
            continue
        }

        $destinationProperty =
            $route.PSObject.Properties["DestinationPrefix"]

        if ($null -eq $destinationProperty) {
            continue
        }

        $destination = [string]$destinationProperty.Value

        if ($destination -eq "0.0.0.0/0") {
            $publicRouteCount++
        }
    }

    if ($publicRouteCount -eq 0) {
        $issues += [pscustomobject]@{
            Type     = "ROUTE"
            Severity = "Medium"
            Detail   = "No IPv4 default route is currently visible."
        }
    }

    # ---------------------------------------------------------------------
    # INTERFACES / IPV6
    # ---------------------------------------------------------------------

    $interfaces = @(Get-AegisNetworkInterfaces)

    foreach ($interface in $interfaces) {

        if ($null -eq $interface) {
            continue
        }

        $ipv6Property =
            $interface.PSObject.Properties["IPv6"]

        if ($null -eq $ipv6Property) {
            continue
        }

        $addresses = @($ipv6Property.Value)

        foreach ($address in $addresses) {

            if ($null -eq $address) {
                continue
            }

            $addressText = [string]$address

            if ([string]::IsNullOrWhiteSpace($addressText)) {
                continue
            }

            # Ignore loopback.
            if ($addressText -eq "::1") {
                continue
            }

            # Ignore IPv6 link-local addresses.
            if ($addressText -like "fe80:*") {
                continue
            }

            $ipv6Global += $addressText
        }
    }

    # ---------------------------------------------------------------------
    # RESULT
    # ---------------------------------------------------------------------

    $healthy = ($issues.Count -eq 0)

    return [pscustomobject]@{
        Timestamp = (Get-Date).ToUniversalTime().ToString("o")
        Healthy   = $healthy
        DNS       = $dns
        Routes    = $routes
        IPv6      = $ipv6Global
        Issues    = $issues
    }
}
