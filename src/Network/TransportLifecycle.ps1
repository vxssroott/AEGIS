Set-StrictMode -Version Latest

function Get-AegisTransportLifecycleContract {
    [CmdletBinding()]
    param()

    [pscustomobject][ordered]@{
        Version = '5.3'
        ObservationOnly = $true
        MutationEnabled = $false
        SafeTransition = 'VerifyBeforeBind'
        RequiredSequence = @(
            'Observe'
            'Candidate'
            'Establishing'
            'Verifying'
            'Verified'
            'Bound'
        )
        FailureSequence = @(
            'Degraded'
            'Failed'
            'Recovering'
        )
    }
}

function New-AegisTransportLifecycleRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TransportId,

        [Parameter(Mandatory)]
        [string]$Provider
    )

    [pscustomobject][ordered]@{
        TransportId       = $TransportId
        Provider          = $Provider
        State             = 'Observe'
        PreviousState     = $null
        ObservationOnly   = $true
        MutationExecuted  = $false
        TransitionAllowed = $true
        CreatedAt         = (Get-Date).ToUniversalTime()
        UpdatedAt         = (Get-Date).ToUniversalTime()
    }
}

function Move-AegisTransportLifecycle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Record,

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
        [string]$NextState
    )

    $allowed = @{
        Observe      = @('Candidate','Degraded')
        Candidate    = @('Establishing','Failed')
        Establishing = @('Verifying','Failed')
        Verifying    = @('Verified','Degraded','Failed')
        Verified     = @('Bound','Degraded','Failed')
        Bound        = @('Degraded','Failed')
        Degraded     = @('Recovering','Failed')
        Failed       = @('Recovering')
        Recovering   = @('Candidate','Failed')
    }

    $current = [string]$Record.State

    if (-not $allowed.ContainsKey($current)) {
        throw "Unknown lifecycle state: $current"
    }

    if ($allowed[$current] -notcontains $NextState) {
        throw "Illegal transport lifecycle transition: $current -> $NextState"
    }

    # Binding is only permitted after verification.
    if ($NextState -eq 'Bound' -and $current -ne 'Verified') {
        throw 'Transport cannot enter Bound state without Verified state.'
    }

    # This controller never performs the actual mutation.
    if ([bool]$Record.MutationExecuted) {
        throw 'Lifecycle record already reports mutation execution.'
    }

    $Record.PreviousState = $Record.State
    $Record.State = $NextState
    $Record.UpdatedAt = (Get-Date).ToUniversalTime()

    return $Record
}
