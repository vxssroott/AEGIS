function Get-AegisTransportProviderRegistry {
    [CmdletBinding()]
    param()
    $ProviderDirectory = Join-Path $PSScriptRoot 'Providers'

    $ProviderFiles = @(
        'WireGuardProvider.ps1'
        'OpenVpnProvider.ps1'
        'TorProvider.ps1'
        'Socks5Provider.ps1'
        'HttpConnectProvider.ps1'
    )

    foreach ($ProviderFile in $ProviderFiles) {
        $ProviderPath = Join-Path $ProviderDirectory $ProviderFile

        if (Test-Path -LiteralPath $ProviderPath) {
            . $ProviderPath
        }
    }

    $ProviderResults = @()

    if (Get-Command Get-AegisWireGuardProvider -ErrorAction SilentlyContinue) {
        $ProviderResults += Get-AegisWireGuardProvider
    }

    if (Get-Command Get-AegisOpenVpnProvider -ErrorAction SilentlyContinue) {
        $ProviderResults += Get-AegisOpenVpnProvider
    }

    if (Get-Command Get-AegisTorProvider -ErrorAction SilentlyContinue) {
        $ProviderResults += Get-AegisTorProvider
    }

    if (Get-Command Get-AegisSocks5Provider -ErrorAction SilentlyContinue) {
        $ProviderResults += Get-AegisSocks5Provider
    }

    if (Get-Command Get-AegisHttpConnectProvider -ErrorAction SilentlyContinue) {
        $ProviderResults += Get-AegisHttpConnectProvider
    }

    return @($ProviderResults)
}

