function Get-AegisWireGuardProvider {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Provider  = 'WireGuard'
        Type      = 'VPN'
        Available = $false
        Active    = $false
        Verified  = $false
        Mutation  = $false
        Evidence  = @()
    }
}
