function Get-AegisMobileProviderCapabilities {
    [CmdletBinding()]
    param()

    @(
        [pscustomobject]@{
            Provider = 'WireGuard'
            Android  = $true
            Native   = $true
            RequiresPlatformAdapter = $true
            MutationEnabled = $false
        }

        [pscustomobject]@{
            Provider = 'OpenVPN'
            Android  = $true
            Native   = $true
            RequiresPlatformAdapter = $true
            MutationEnabled = $false
        }

        [pscustomobject]@{
            Provider = 'Tor'
            Android  = $true
            Native   = $false
            RequiresPlatformAdapter = $true
            MutationEnabled = $false
        }

        [pscustomobject]@{
            Provider = 'SOCKS5'
            Android  = $true
            Native   = $false
            RequiresPlatformAdapter = $true
            MutationEnabled = $false
        }

        [pscustomobject]@{
            Provider = 'HTTP_CONNECT'
            Android  = $true
            Native   = $false
            RequiresPlatformAdapter = $true
            MutationEnabled = $false
        }
    )
}
