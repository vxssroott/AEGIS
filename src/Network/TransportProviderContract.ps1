function Get-AegisTransportProviderContract {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Version                 = '5.4'
        ObservationOnly        = $true
        MutationEnabled        = $false
        EstablishRequiresProof = $true
        VerifyBeforeBind       = $true
        Providers              = @(
            'WireGuard'
            'OpenVPN'
            'Tor'
            'SOCKS5'
            'HTTP_CONNECT'
        )
    }
}
