Set-StrictMode -Version Latest

$script:AegisNetworkOperatorOperations = @(
    'InspectNetworkState',
    'EstablishTransport',
    'VerifyTransport',
    'BindTransport',
    'RetireTransport',
    'RotateTransport',
    'RecoverTransport',
    'ApplyFirewallPolicy',
    'ApplyRoutePolicy',
    'ApplyDnsPolicy',
    'ApplyIpv6Policy'
)

$script:AegisNetworkOperatorParameterRules = @{
    InspectNetworkState = @()

    EstablishTransport = @(
        'TransportId'
        'Provider'
        'Kind'
    )

    VerifyTransport = @(
        'TransportId'
    )

    BindTransport = @(
        'TransportId'
        'InterfaceIndex'
    )

    RetireTransport = @(
        'TransportId'
    )

    RotateTransport = @(
        'CurrentTransportId'
        'NextTransportId'
    )

    RecoverTransport = @(
        'TransportId'
        'Reason'
    )

    ApplyFirewallPolicy = @(
        'PolicyId'
        'Mode'
    )

    ApplyRoutePolicy = @(
        'PolicyId'
        'InterfaceIndex'
    )

    ApplyDnsPolicy = @(
        'PolicyId'
        'Servers'
    )

    ApplyIpv6Policy = @(
        'PolicyId'
        'Mode'
    )
}

function Get-AegisNetworkOperatorOperations {
    [CmdletBinding()]
    param()

    return @($script:AegisNetworkOperatorOperations)
}

function Get-AegisNetworkOperatorParameterRules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Operation
    )

    if (-not $script:AegisNetworkOperatorParameterRules.ContainsKey($Operation)) {
        throw ("No parameter contract exists for operation: {0}" -f $Operation)
    }

    return @($script:AegisNetworkOperatorParameterRules[$Operation])
}

function Get-AegisNetworkOperatorContract {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Name                    = 'AegisNetworkOperator'
        Version                 = '1.1'
        PrivilegeProfile        = 'LeastPrivilege'

        AllowedOperations       = @($script:AegisNetworkOperatorOperations)

        ArbitraryProcessExec    = $false
        ArbitraryPowerShellExec = $false
        CredentialAccess        = $false
        BrowserDataAccess       = $false
        UnrestrictedFileWrite   = $false
        UnrestrictedRegistry    = $false
        PolicyDecisionAuthority = $false

        ExplicitOperationOnly   = $true
        ParameterAllowListOnly  = $true

        VerificationRequired    = $true
        AuditRequired           = $true
        RollbackRequired        = $true

        RequestIntegrity        = $true
        RequestExpiryRequired   = $true
        ReplayProtection        = $true

        MutationEnabled         = $false
    }
}

function Test-AegisOperatorMutationRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Request
    )

    $contract = Get-AegisNetworkOperatorContract

    if ($null -eq $Request.Operation) {
        return [pscustomobject]@{
            Allowed = $false
            Reason  = 'Operation is required.'
        }
    }

    $operation = [string]$Request.Operation

    if ($contract.AllowedOperations -notcontains $operation) {
        return [pscustomobject]@{
            Allowed = $false
            Reason  = ("Operation is not permitted: {0}" -f $operation)
        }
    }

    if (-not $contract.ExplicitOperationOnly) {
        return [pscustomobject]@{
            Allowed = $false
            Reason  = 'Explicit-operation-only contract is disabled.'
        }
    }

    if (-not $contract.ParameterAllowListOnly) {
        return [pscustomobject]@{
            Allowed = $false
            Reason  = 'Parameter allow-list protection is disabled.'
        }
    }

    if (-not $contract.VerificationRequired) {
        return [pscustomobject]@{
            Allowed = $false
            Reason  = 'Verification requirement is disabled.'
        }
    }

    if (-not $contract.AuditRequired) {
        return [pscustomobject]@{
            Allowed = $false
            Reason  = 'Audit requirement is disabled.'
        }
    }

    if (-not $contract.RollbackRequired) {
        return [pscustomobject]@{
            Allowed = $false
            Reason  = 'Rollback requirement is disabled.'
        }
    }

    [pscustomobject]@{
        Allowed = $true
        Reason  = 'Request satisfies the operator contract.'
    }
}
