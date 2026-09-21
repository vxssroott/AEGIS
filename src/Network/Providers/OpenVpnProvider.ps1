function Get-AegisOpenVpnProvider {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Provider  = 'OpenVPN'
        Type      = 'VPN'
        Available = $false
        Active    = $false
        Verified  = $false
        Mutation  = $false
        Evidence  = @()
    }
}
