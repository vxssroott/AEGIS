Set-StrictMode -Version Latest

$files = @(
    'TransportTypes.ps1',
    'EventBus.ps1',
    'Voice.ps1',
    'TransportProviders.ps1',
    'TransportState.ps1',
    'TransportVerification.ps1',
    'TransportOrchestrator.ps1'
)

foreach ($file in $files) {
    $path = Join-Path $PSScriptRoot $file

    if (-not (Test-Path -LiteralPath $path)) {
        throw "AEGIS Phase 5 component missing: $file"
    }

    . $path
}

function Get-AegisPhase5Fabric {
    [CmdletBinding()]
    param()

    [pscustomobject]@{
        Version       = '5.0'
        Name          = 'Autonomous Transport Fabric'
        State         = Get-AegisTransportState
        Providers     = @(Get-AegisTransportProviders)
        Voice         = Get-AegisVoiceAvailability
        RecentEvents  = @(Get-AegisRecentEvents -Count 10)
        Mutation      = [pscustomobject]@{
            Enabled = $false
            Reason  = 'Phase 5.0 is observation/control-plane only.'
        }
    }
}
