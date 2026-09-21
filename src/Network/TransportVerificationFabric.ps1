Set-StrictMode -Version Latest

function Get-AegisTransportVerificationFabric {
    [CmdletBinding()]
    param()

    [pscustomobject][ordered]@{
        Name                  = 'AEGIS Transport Verification Fabric'
        Version               = '5.3'
        ObservationOnly       = $true
        MutationEnabled       = $false
        RequireExternalProof  = $true
        RequireRouteProof     = $true
        RequireDnsProof       = $true
        RequireIpv6Proof      = $true
        RequireCryptographic  = $true
        RequireProviderProof  = $true
        FailClosedOnUnknown   = $true
        Lifecycle             = @(
            'Observe'
            'Candidate'
            'Establishing'
            'Verifying'
            'Verified'
            'Bound'
            'Degraded'
            'Failed'
            'Recovering'
        )
    }
}

function New-AegisTransportVerificationRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TransportId,

        [Parameter(Mandatory)]
        [string]$Provider,

        [Parameter(Mandatory)]
        [ValidateSet(
            'Observe',
            'Candidate',
            'Establishing',
            'Verifying',
            'Verified',
            'Bound',
            'Degraded',
            'Failed',
            'Recovering'
        )]
        [string]$State,

        [bool]$ExternalEndpointProof = $false,
        [bool]$RouteBindingProof = $false,
        [bool]$DnsPathProof = $false,
        [bool]$Ipv6BoundaryProof = $false,
        [bool]$CryptographicTunnelProof = $false,
        [bool]$ProviderProof = $false
    )

    $proofs = [ordered]@{
        ExternalEndpointProof  = $ExternalEndpointProof
        RouteBindingProof      = $RouteBindingProof
        DnsPathProof           = $DnsPathProof
        Ipv6BoundaryProof      = $Ipv6BoundaryProof
        CryptographicTunnelProof = $CryptographicTunnelProof
        ProviderProof           = $ProviderProof
    }

    $verified = (
        $ExternalEndpointProof -and
        $RouteBindingProof -and
        $DnsPathProof -and
        $Ipv6BoundaryProof -and
        $CryptographicTunnelProof -and
        $ProviderProof
    )

    [pscustomobject][ordered]@{
        TransportId = $TransportId
        Provider    = $Provider
        State       = $State
        Proofs      = [pscustomobject]$proofs
        Verified    = $verified
        ObservationOnly = $true
        MutationExecuted = $false
        VerifiedAt  = if ($verified) { (Get-Date).ToUniversalTime() } else { $null }
    }
}

function Test-AegisTransportVerificationRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Record
    )

    $required = @(
        'TransportId'
        'Provider'
        'State'
        'Proofs'
        'Verified'
        'ObservationOnly'
        'MutationExecuted'
    )

    foreach ($property in $required) {
        if (-not ($Record.PSObject.Properties.Name -contains $property)) {
            return [pscustomobject][ordered]@{
                Status = 'INVALID_RECORD'
                Verified = $false
                Reason = "Missing property: $property"
            }
        }
    }

    if (-not [bool]$Record.ObservationOnly) {
        return [pscustomobject][ordered]@{
            Status = 'MUTATION_MODE_REJECTED'
            Verified = $false
            Reason = 'Verification fabric must remain observation-only.'
        }
    }

    if ([bool]$Record.MutationExecuted) {
        return [pscustomobject][ordered]@{
            Status = 'MUTATION_DETECTED'
            Verified = $false
            Reason = 'Verification record reports network mutation.'
        }
    }

    $proofProperties = @(
        'ExternalEndpointProof'
        'RouteBindingProof'
        'DnsPathProof'
        'Ipv6BoundaryProof'
        'CryptographicTunnelProof'
        'ProviderProof'
    )

    foreach ($proof in $proofProperties) {
        if (-not ($Record.Proofs.PSObject.Properties.Name -contains $proof)) {
            return [pscustomobject][ordered]@{
                Status = 'INCOMPLETE_PROOF'
                Verified = $false
                Reason = "Missing proof: $proof"
            }
        }
    }

    $allProofs = $true

    foreach ($proof in $proofProperties) {
        if (-not [bool]$Record.Proofs.$proof) {
            $allProofs = $false
            break
        }
    }

    if (-not $allProofs) {
        return [pscustomobject][ordered]@{
            Status = 'VERIFICATION_PENDING'
            Verified = $false
            Reason = 'One or more required proofs are absent.'
        }
    }

    [pscustomobject][ordered]@{
        Status = 'VERIFIED'
        Verified = $true
        Reason = 'All required transport proofs are present.'
    }
}
