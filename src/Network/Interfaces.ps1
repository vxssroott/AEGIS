Set-StrictMode -Version Latest

function Get-AegisSafePropertyValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Object,

        [Parameter(Mandatory)]
        [string[]]$PropertyNames
    )

    if ($null -eq $Object) {
        return $null
    }

    foreach ($name in $PropertyNames) {
        $property = $Object.PSObject.Properties[$name]

        if ($null -ne $property) {
            return $property.Value
        }
    }

    return $null
}

function Get-AegisNetworkInterfaces {
    [CmdletBinding()]
    param()

    $interfaces = @(Get-NetIPConfiguration -ErrorAction SilentlyContinue)

    foreach ($i in $interfaces) {

        $interfaceIndex = Get-AegisSafePropertyValue `
            -Object $i `
            -PropertyNames @("InterfaceIndex")

        $interfaceAlias = Get-AegisSafePropertyValue `
            -Object $i `
            -PropertyNames @("InterfaceAlias")

        $adapter = $null

        if ($null -ne $interfaceIndex) {
            $adapter = Get-NetAdapter `
                -InterfaceIndex $interfaceIndex `
                -ErrorAction SilentlyContinue
        }

        $ipv4 = @()

        $ipv4Objects = @(Get-AegisSafePropertyValue `
            -Object $i `
            -PropertyNames @("IPv4Address"))

        foreach ($entry in $ipv4Objects) {
            $value = Get-AegisSafePropertyValue `
                -Object $entry `
                -PropertyNames @("IPv4Address","IPAddress","Address")

            if ($null -ne $value -and "$value".Length -gt 0) {
                $ipv4 += "$value"
            }
        }

        $ipv6 = @()

        $ipv6Objects = @(Get-AegisSafePropertyValue `
            -Object $i `
            -PropertyNames @("IPv6Address"))

        foreach ($entry in $ipv6Objects) {
            $value = Get-AegisSafePropertyValue `
                -Object $entry `
                -PropertyNames @("IPv6Address","IPAddress","Address")

            if ($null -ne $value -and "$value".Length -gt 0) {
                $ipv6 += "$value"
            }
        }

        $gateway = @()

        $gatewayObjects = @(Get-AegisSafePropertyValue `
            -Object $i `
            -PropertyNames @("IPv4DefaultGateway"))

        foreach ($entry in $gatewayObjects) {
            $value = Get-AegisSafePropertyValue `
                -Object $entry `
                -PropertyNames @("NextHop","IPAddress","Address")

            if ($null -ne $value -and "$value".Length -gt 0) {
                $gateway += "$value"
            }
        }

        $dns = @()

        $dnsObjects = @(Get-AegisSafePropertyValue `
            -Object $i `
            -PropertyNames @("DNSServer"))

        foreach ($entry in $dnsObjects) {

            $addresses = Get-AegisSafePropertyValue `
                -Object $entry `
                -PropertyNames @("ServerAddresses","Address","IPAddress")

            if ($null -eq $addresses) {
                continue
            }

            foreach ($address in @($addresses)) {
                if ($null -ne $address -and "$address".Length -gt 0) {
                    $dns += "$address"
                }
            }
        }

        [pscustomobject]@{
            InterfaceAlias = $interfaceAlias
            InterfaceIndex = $interfaceIndex

            Status = if ($null -ne $adapter) {
                Get-AegisSafePropertyValue `
                    -Object $adapter `
                    -PropertyNames @("Status")
            }
            else {
                "Unknown"
            }

            Description = if ($null -ne $adapter) {
                Get-AegisSafePropertyValue `
                    -Object $adapter `
                    -PropertyNames @("InterfaceDescription")
            }
            else {
                $null
            }

            MacAddress = if ($null -ne $adapter) {
                Get-AegisSafePropertyValue `
                    -Object $adapter `
                    -PropertyNames @("MacAddress")
            }
            else {
                $null
            }

            IPv4   = @($ipv4)
            IPv6   = @($ipv6)
            Gateway = @($gateway)
            DNS     = @($dns)
        }
    }
}

function Get-AegisVirtualInterfaces {
    @(Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object {
            $description = Get-AegisSafePropertyValue `
                -Object $_ `
                -PropertyNames @("InterfaceDescription")

            $description -match 'VPN|TAP|TUN|WireGuard|OpenVPN|Wintun|Virtual|Hyper-V|VMware|VirtualBox'
        } |
        Select-Object Name, InterfaceDescription, ifIndex, Status, MacAddress)
}
