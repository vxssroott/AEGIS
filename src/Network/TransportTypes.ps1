Set-StrictMode -Version Latest

$script:AegisTransportStates = @(
    'Detached',
    'Establishing',
    'Verifying',
    'Active',
    'Degraded',
    'Rotating',
    'Failed',
    'Recovering'
)

function New-AegisTransportDescriptor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Kind,

        [Parameter(Mandatory)]
        [string]$Provider,

        [string]$DisplayName = $Provider,

        [bool]$Available = $false,

        [bool]$Active = $false,

        [bool]$Verified = $false,

        [int]$Priority = 100
    )

    [pscustomobject]@{
        Id          = $Id
        Kind        = $Kind
        Provider    = $Provider
        DisplayName = $DisplayName
        Available   = $Available
        Active      = $Active
        Verified    = $Verified
        Priority    = $Priority
        Timestamp   = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Test-AegisTransportState {
    param(
        [Parameter(Mandatory)]
        [string]$State
    )

    return $script:AegisTransportStates -contains $State
}
