function Get-AegisSocks5Provider {
    [CmdletBinding()]
    param(
        [string]$ProxyHost = '127.0.0.1',
        [int[]]$Ports = @(1080,1081,9050,9150)
    )

    $EndpointResults = foreach ($Port in $Ports) {
        $Test = Test-NetConnection `
            -ComputerName $ProxyHost `
            -Port $Port `
            -WarningAction SilentlyContinue `
            -ErrorAction SilentlyContinue

        [pscustomobject]@{
            Host      = $ProxyHost
            Port      = $Port
            Available = [bool]$Test.TcpTestSucceeded
            Active    = $false
            Verified  = $false
        }
    }

    [pscustomobject]@{
        Provider  = 'SOCKS5'
        Type      = 'Proxy'
        Available = @($EndpointResults | Where-Object Available).Count -gt 0
        Active    = $false
        Verified  = $false
        Mutation  = $false
        Evidence  = @($EndpointResults)
    }
}
