Set-StrictMode -Version Latest

$script:AegisObservationStates = @(
    'Observed',
    'NotDetected',
    'Unknown',
    'QueryFailed',
    'Unavailable',
    'VerificationPending',
    'Verified',
    'Violation'
)

function Test-AegisObservationState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$State
    )

    return $script:AegisObservationStates -contains $State
}

function New-AegisObservationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$State,

        [AllowNull()]
        [object]$Value = $null,

        [string]$Detail = '',

        [string]$Source = 'AEGIS'
    )

    if (-not (Test-AegisObservationState -State $State)) {
        throw "Invalid AEGIS observation state: $State"
    }

    [pscustomobject]@{
        Name      = $Name
        State     = $State
        Value     = $Value
        Detail    = $Detail
        Source    = $Source
        Timestamp = (Get-Date).ToUniversalTime().ToString('o')
    }
}
