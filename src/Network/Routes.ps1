Set-StrictMode -Version Latest

function Get-AegisDefaultRoutes {
    [CmdletBinding()]
    param()

    $routes = @()

    try {
        $rawRoutes = @(Get-NetRoute -AddressFamily IPv4 -ErrorAction Stop)

        foreach ($route in $rawRoutes) {
            if ($null -eq $route) {
                continue
            }

            $destinationProperty =
                $route.PSObject.Properties["DestinationPrefix"]

            if ($null -eq $destinationProperty) {
                continue
            }

            $destination = [string]$destinationProperty.Value

            if ($destination -ne "0.0.0.0/0") {
                continue
            }

            $routes += [pscustomobject]@{
                DestinationPrefix = $destination
                InterfaceIndex    = if ($null -ne $route.PSObject.Properties["InterfaceIndex"]) {
                    $route.InterfaceIndex
                } else {
                    $null
                }
                NextHop           = if ($null -ne $route.PSObject.Properties["NextHop"]) {
                    [string]$route.NextHop
                } else {
                    $null
                }
                RouteMetric       = if ($null -ne $route.PSObject.Properties["RouteMetric"]) {
                    $route.RouteMetric
                } else {
                    $null
                }
                AddressFamily     = "IPv4"
            }
        }
    }
    catch {
        return @()
    }

    return @($routes)
}
