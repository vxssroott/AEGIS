function Get-AegisUiControlPlaneContract {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Version = '5.4'
        Product = 'AEGIS'
        Surface = 'MobileFirst'
        BackendBoundary = 'AEGIS Control Plane'
        NetworkBoundary = 'Platform Adapter'
        AndroidBoundary = 'Android VpnService'
        TransportFabric = @('WireGuard','OpenVPN','Tor','SOCKS5','HTTP_CONNECT')
        VerificationFabric = @('ExternalEndpointProof','RouteBindingProof','DnsPathProof','Ipv6BoundaryProof','ProviderProof')
        ObservationOnly = $true
        MutationEnabled = $false
        ExposesNetworkIdentity = $true
        ExposesNetworkPath = $true
        ExposesDnsState = $true
        ExposesIpv6State = $true
        ExposesTransportState = $true
        ExposesVerificationEvidence = $true
    }
}
