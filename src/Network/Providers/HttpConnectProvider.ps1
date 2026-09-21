function Get-AegisHttpConnectProvider {
    [CmdletBinding()]
    param()

    $ProxyOutput = @(netsh winhttp show proxy 2>$null)

    $Configured = $false

    if ($ProxyOutput.Count -gt 0) {
        $Configured = (
            ($ProxyOutput -join "`n") -notmatch 'Direct access \(no proxy server\)'
        )
    }

    [pscustomobject]@{
        Provider  = 'HTTP_CONNECT'
        Type      = 'Proxy'
        Available = $Configured
        Active    = $false
        Verified  = $false
        Mutation  = $false
        Evidence  = $ProxyOutput
    }
}
