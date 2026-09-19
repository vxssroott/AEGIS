# ============================================================
# AEGIS PRIVACY CONTROL PLANE
# ============================================================

$script:AegisPrivacyRoot = Split-Path -Parent $PSCommandPath

# ------------------------------------------------------------
# Static types
# ------------------------------------------------------------

$privacyTypes = Join-Path $script:AegisPrivacyRoot 'PrivacyTypes.ps1'

$typesLoaded = $false

try {
    [AegisPrivacySeverity] | Out-Null
    $typesLoaded = $true
}
catch {
    $typesLoaded = $false
}

if (-not $typesLoaded) {
    . $privacyTypes
}

# ------------------------------------------------------------
# Providers / engines
#
# IMPORTANT:
# These are dot-sourced at CONTROL-PLANE SCOPE, not inside a
# function. Therefore their functions remain available.
# ------------------------------------------------------------

$privacyModules = @(
    'CapabilityRegistry.ps1',
    'Providers\LocationProvider.ps1',
    'Providers\BrowserProvider.ps1',
    'Providers\ArtifactProvider.ps1',
    'Remediation\RemediationEngine.ps1',
    'Policies\PolicyEngine.ps1'
)

foreach ($module in $privacyModules) {
    $path = Join-Path $script:AegisPrivacyRoot $module

    if (-not (Test-Path $path)) {
        throw "AEGIS privacy module missing: $path"
    }

    . $path
}

# ------------------------------------------------------------
# Public control-plane initialization
# ------------------------------------------------------------

function Import-AegisPrivacyControlPlane {
    [CmdletBinding()]
    param()

    Initialize-AegisPrivacyPolicy | Out-Null

    [pscustomobject]@{
        Name = 'AEGIS Privacy Control Plane'
        Version = '1.0.0'
        Status = 'operational'
        Root = $script:AegisPrivacyRoot
        InitializedAt = [datetime]::UtcNow
    }
}

function Invoke-AegisPrivacyAudit {
    [CmdletBinding()]
    param()

    Import-AegisPrivacyControlPlane | Out-Null

    $observations = @()

    $observations += @(Get-AegisLocationPrivacyState)
    $observations += @(Get-AegisBrowserPrivacyState)
    $observations += @(Get-AegisArtifactPrivacyState)

    [pscustomobject]@{
        Timestamp = [datetime]::UtcNow
        Count = $observations.Count
        Exposed = @(
            $observations |
                Where-Object { $_.Exposed -eq $true }
        ).Count
        Remediable = @(
            $observations |
                Where-Object { $_.Remediable -eq $true }
        ).Count
        Observations = $observations
    }
}

function Invoke-AegisPrivacyPolicy {
    [CmdletBinding()]
    param(
        [switch]$AutoRemediate
    )

    Import-AegisPrivacyControlPlane | Out-Null

    $audit = Invoke-AegisPrivacyAudit

    $decisions = @(
        Invoke-AegisPrivacyPolicyEvaluation `
            -Observations $audit.Observations `
            -AutoRemediate:$AutoRemediate
    )

    [pscustomobject]@{
        Timestamp = [datetime]::UtcNow
        Audit = $audit
        Decisions = $decisions
    }
}

function Invoke-AegisPrivacyRemediationById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ObservationId,

        [switch]$Force
    )

    Import-AegisPrivacyControlPlane | Out-Null

    $audit = Invoke-AegisPrivacyAudit

    $observation = @(
        $audit.Observations |
            Where-Object { $_.Id -eq $ObservationId }
    ) | Select-Object -First 1

    if ($null -eq $observation) {
        throw "Privacy observation not found: $ObservationId"
    }

    Invoke-AegisPrivacyRemediation `
        -Observation $observation `
        -Force:$Force `
        -Confirm:$false
}