Set-StrictMode -Version Latest

function Invoke-AegisTransportOrchestrator {
    [CmdletBinding()]
    param(
        [switch]$Autonomous,

        [switch]$Voice,

        [switch]$Persist
    )

    $providers = @(Get-AegisTransportProviders)
    $state = Get-AegisTransportState

    Publish-AegisEvent `
        -Type 'transport.observed' `
        -Category 'transport' `
        -Severity 'info' `
        -Message "Observed $($providers.Count) transport candidate(s)." `
        -Data $providers `
        -Voice:$false | Out-Null

    $activeCandidates = @(
        $providers |
            Where-Object {
                $_.Active -eq $true
            }
    )

    if ($activeCandidates.Count -eq 0) {

        $newState = Set-AegisTransportState `
            -State 'Degraded' `
            -ActiveId $null `
            -Verified $false

        Publish-AegisEvent `
            -Type 'transport.degraded' `
            -Category 'privacy' `
            -Severity 'warning' `
            -Message 'Privacy transport boundary has no active transport.' `
            -Data $newState `
            -Voice:$Voice | Out-Null
    }
    else {

        $candidate = $activeCandidates |
            Sort-Object Priority |
            Select-Object -First 1

        $verification = Test-AegisTransportVerification `
            -Transport $candidate

        if ($verification.Verified) {

            $newState = Set-AegisTransportState `
                -State 'Active' `
                -ActiveId $candidate.Id `
                -Verified $true

            Publish-AegisEvent `
                -Type 'transport.active' `
                -Category 'transport' `
                -Severity 'info' `
                -Message "Verified transport active: $($candidate.Provider)." `
                -Data $verification `
                -Voice:$Voice | Out-Null
        }
        else {

            $newState = Set-AegisTransportState `
                -State 'Verifying' `
                -ActiveId $candidate.Id `
                -Verified $false

            Publish-AegisEvent `
                -Type 'transport.verification_required' `
                -Category 'privacy' `
                -Severity 'warning' `
                -Message "Transport detected but not yet trusted: $($candidate.Provider)." `
                -Data $verification `
                -Voice:$Voice | Out-Null
        }
    }

    $snapshot = [pscustomobject]@{
        Timestamp       = (Get-Date).ToUniversalTime().ToString('o')
        Autonomous      = [bool]$Autonomous
        CurrentState    = Get-AegisTransportState
        Providers       = @($providers)
        ActiveCandidate = @($activeCandidates)
        Voice           = Get-AegisVoiceAvailability
        Mutation        = [pscustomobject]@{
            RoutesModified   = $false
            DNSModified      = $false
            FirewallModified = $false
            VPNModified      = $false
            ProxyModified    = $false
            TorModified      = $false
        }
    }

    if ($Persist) {
        $snapshot |
            ConvertTo-Json -Depth 15 |
            Set-Content `
                -LiteralPath (Join-Path $RuntimeRoot 'phase5-transport-last.json') `
                -Encoding UTF8
    }

    return $snapshot
}
