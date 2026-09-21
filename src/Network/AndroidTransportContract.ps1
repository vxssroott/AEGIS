function Get-AegisAndroidTransportContract {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Version                 = '5.4'
        Platform                = 'Android'
        BackgroundCapable       = $true
        RootRequired            = $false
        DeviceVpnBoundary       = 'Android VpnService'
        TunnelInterface         = 'TUN'
        UserInteractionRequired = $false
        ObservationOnly         = $true
        MutationEnabled         = $false

        Lifecycle = @(
            'Observe'
            'Candidate'
            'Establishing'
            'Verifying'
            'Verified'
            'Bound'
            'Degraded'
            'Recovering'
            'Failed'
        )

        RequiredProofs = @(
            'ExternalEndpointProof'
            'RouteBindingProof'
            'DnsPathProof'
            'Ipv6BoundaryProof'
            'ProviderProof'
        )

        Capabilities = @(
            'DeviceWideTrafficBoundary'
            'BackgroundMonitoring'
            'TransportRotation'
            'ConnectivityRecovery'
            'DNSLeakDetection'
            'IPv6LeakDetection'
            'ExternalIdentityVerification'
        )

        PlatformAdapterResponsibilities = @(
            'CreateVpnInterface'
            'ApplyRoutes'
            'ApplyDnsPolicy'
            'ObserveConnectivity'
            'ExposeTransportState'
            'ReportNetworkChanges'
            'StopTransport'
        )
    }
}
