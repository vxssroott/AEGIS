function Get-AegisPlatformContract {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Version              = '5.4'
        CorePortable         = $true
        Windows              = $true
        Android              = $true
        Linux                = $true
        IOS                  = $false
        MobileFirstBoundary = $true

        ControlPlane = [pscustomobject]@{
            Policy       = $true
            Observation  = $true
            Verification = $true
            Lifecycle    = $true
            Telemetry    = $true
        }

        TransportBoundary = [pscustomobject]@{
            WindowsNativeAdapters = $true
            AndroidVpnService     = $true
            AndroidTunBoundary    = $true
            ProviderNeutral       = $true
            VerifyBeforeBind     = $true
            FailClosed            = $true
        }

        Mutation = [pscustomobject]@{
            Core                    = $false
            PlatformAdapterRequired = $true
            PrivilegedBoundary      = $true
        }
    }
}
