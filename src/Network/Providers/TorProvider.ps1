function Get-AegisTorProvider {
    [CmdletBinding()]
    param(
        [int[]]$Ports = @(9050,9150)
    )

    $EndpointResults = foreach ($Port in $Ports) {
        $Listener = Get-NetTCPConnection `
            -LocalAddress '127.0.0.1' `
            -LocalPort $Port `
            -State Listen `
            -ErrorAction SilentlyContinue

        [pscustomobject]@{
            Port      = $Port
            Available = $null -ne $Listener
            Active    = $false
            Verified  = $false
        }
    }

    [pscustomobject]@{
        Provider  = 'Tor'
        Type      = 'SOCKS'
        Available = @($EndpointResults | Where-Object Available).Count -gt 0
        Active    = $false
        Verified  = $false
        Mutation  = $false
        Evidence  = @($EndpointResults)
    }
}
