Set-StrictMode -Version Latest

function Get-AegisRequestFingerprint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Request
    )

    $parameterPairs = @(
        foreach ($key in @($Request.Parameters.Keys | Sort-Object)) {
            $value = $Request.Parameters[$key]

            if ($value -is [System.Array]) {
                $valueText = (@($value) | ForEach-Object { [string]$_ }) -join ','
            }
            elseif ($null -eq $value) {
                $valueText = '<null>'
            }
            else {
                $valueText = [string]$value
            }

            "$key=$valueText"
        }
    )

    $canonical = @(
        "RequestId=$($Request.RequestId)"
        "CorrelationId=$($Request.CorrelationId)"
        "Operation=$($Request.Operation)"
        "Parameters=$($parameterPairs -join '|')"
        "RequestedBy=$($Request.RequestedBy)"
        "Reason=$($Request.Reason)"
        "CreatedAt=$($Request.CreatedAt)"
        "ExpiresAt=$($Request.ExpiresAt)"
    ) -join "`n"

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($canonical)
    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        return ([BitConverter]::ToString(
            $sha.ComputeHash($bytes)
        )).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function New-AegisNetworkOperatorRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Operation,

        [AllowNull()]
        [hashtable]$Parameters = @{},

        [string]$Reason = '',

        [string]$RequestedBy = 'AEGIS-ControlPlane',

        [string]$CorrelationId = ([guid]::NewGuid().Guid),

        [ValidateRange(1,3600)]
        [int]$ExpiresInSeconds = 60
    )

    $created = (Get-Date).ToUniversalTime()

    $request = [pscustomobject]@{
        RequestId       = [guid]::NewGuid().Guid
        CorrelationId   = $CorrelationId
        Operation       = $Operation
        Parameters      = $Parameters
        Reason          = $Reason
        RequestedBy     = $RequestedBy

        Authorized      = $false
        AuthorizedBy    = $null
        AuthorizedAt    = $null

        Verified        = $false
        VerificationId = $null

        Audited         = $false
        AuditId         = $null

        RollbackReady   = $false
        RollbackId      = $null

        MutationAllowed = $false
        LifecycleState  = 'Created'

        CreatedAt       = $created.ToString('o')
        ExpiresAt       = $created.AddSeconds($ExpiresInSeconds).ToString('o')

        Fingerprint     = $null
    }

    $request.Fingerprint = Get-AegisRequestFingerprint -Request $request

    return $request
}

function Approve-AegisNetworkOperatorRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Request,

        [string]$AuthorizedBy = 'AEGIS-ControlPlane',

        [string]$VerificationId = '',

        [string]$AuditId = '',

        [string]$RollbackId = '',

        [switch]$VerificationPassed,

        [switch]$AuditPrepared,

        [switch]$RollbackPrepared
    )

    $now = (Get-Date).ToUniversalTime()

    if ($now -gt ([datetime]$Request.ExpiresAt)) {
        $Request.LifecycleState = 'Expired'
        $Request.MutationAllowed = $false
        return $Request
    }

    $Request.Authorized = $true
    $Request.AuthorizedBy = $AuthorizedBy
    $Request.AuthorizedAt = $now.ToString('o')

    $Request.Verified = [bool]$VerificationPassed
    $Request.VerificationId = $VerificationId

    $Request.Audited = [bool]$AuditPrepared
    $Request.AuditId = $AuditId

    $Request.RollbackReady = [bool]$RollbackPrepared
    $Request.RollbackId = $RollbackId

    if (
        $Request.Verified -and
        $Request.Audited -and
        $Request.RollbackReady
    ) {
        $Request.LifecycleState = 'Ready'
    }
    else {
        $Request.LifecycleState = 'Authorized'
    }

    $Request.MutationAllowed = (
        $Request.Authorized -and
        $Request.Verified -and
        $Request.Audited -and
        $Request.RollbackReady -and
        $Request.LifecycleState -eq 'Ready'
    )

    return $Request
}

function Test-AegisNetworkOperatorRequestIntegrity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Request
    )

    $current = Get-AegisRequestFingerprint -Request $Request

    [pscustomobject]@{
        Valid          = ($current -eq [string]$Request.Fingerprint)
        Expected       = [string]$Request.Fingerprint
        Calculated     = $current
        ReplayDetected = $false
        Expired        = (
            (Get-Date).ToUniversalTime() -gt
            ([datetime]$Request.ExpiresAt)
        )
    }
}
