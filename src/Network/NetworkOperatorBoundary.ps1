Set-StrictMode -Version Latest

function Get-AegisNetworkOperatorBoundary {
    [CmdletBinding()]
    param()

    $contract = Get-AegisNetworkOperatorContract

    [pscustomobject]@{
        Name            = $contract.Name
        Version         = $contract.Version
        Privilege       = $contract.PrivilegeProfile
        Operations      = @($contract.AllowedOperations)
        MutationEnabled = [bool]$contract.MutationEnabled
        Timestamp       = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Invoke-AegisNetworkOperatorBoundary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Request
    )

    $contractResult = Test-AegisOperatorMutationRequest -Request $Request

    if (-not $contractResult.Allowed) {
        return [pscustomobject]@{
            Status       = 'DENIED'
            RequestId    = $Request.RequestId
            Operation    = $Request.Operation
            Mutation     = $false
            Reason       = $contractResult.Reason
            Timestamp    = (Get-Date).ToUniversalTime().ToString('o')
        }
    }

    if (-not [bool]$Request.Authorized) {
        return [pscustomobject]@{
            Status       = 'UNAUTHORIZED'
            RequestId    = $Request.RequestId
            Operation    = $Request.Operation
            Mutation     = $false
            Reason       = 'Operator authorization is required.'
            Timestamp    = (Get-Date).ToUniversalTime().ToString('o')
        }
    }

    if (-not [bool]$Request.Verified) {
        return [pscustomobject]@{
            Status       = 'VERIFICATION_REQUIRED'
            RequestId    = $Request.RequestId
            Operation    = $Request.Operation
            Mutation     = $false
            Reason       = 'Pre-execution verification has not passed.'
            Timestamp    = (Get-Date).ToUniversalTime().ToString('o')
        }
    }

    if (-not [bool]$Request.Audited) {
        return [pscustomobject]@{
            Status       = 'AUDIT_REQUIRED'
            RequestId    = $Request.RequestId
            Operation    = $Request.Operation
            Mutation     = $false
            Reason       = 'Audit preparation is required.'
            Timestamp    = (Get-Date).ToUniversalTime().ToString('o')
        }
    }

    if (-not [bool]$Request.RollbackReady) {
        return [pscustomobject]@{
            Status       = 'ROLLBACK_REQUIRED'
            RequestId    = $Request.RequestId
            Operation    = $Request.Operation
            Mutation     = $false
            Reason       = 'Rollback preparation is required.'
            Timestamp    = (Get-Date).ToUniversalTime().ToString('o')
        }
    }

    # Phase 5.2 deliberately stops here.
    # The privileged execution substrate does not exist yet.
    [pscustomobject]@{
        Status       = 'AUTHORIZED_BUT_NOT_EXECUTED'
        RequestId    = $Request.RequestId
        Operation    = $Request.Operation
        Mutation     = $false
        Reason       = 'Operator contract passed; execution substrate is not enabled in Phase 5.2.'
        Timestamp    = (Get-Date).ToUniversalTime().ToString('o')
    }
}
