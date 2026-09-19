function Get-AegisPrivacyPolicyPath {
    return Join-Path $PSScriptRoot '..\..\..\data\privacy\policy.json'
}

function Get-AegisDefaultPrivacyPolicy {
    @(
        [pscustomobject]@{
            Id = 'location.default'
            Domain = 'location'
            Enabled = $true
            AutoRemediate = $false
            MinimumSeverity = 'Medium'
            Settings = @{
                DenyLocationConsent = $false
            }
        }
        [pscustomobject]@{
            Id = 'browser.default'
            Domain = 'browser'
            Enabled = $true
            AutoRemediate = $false
            MinimumSeverity = 'Medium'
            Settings = @{
                ProtectCookies = $true
                ProtectHistory = $true
                ProtectCache = $false
            }
        }
        [pscustomobject]@{
            Id = 'artifacts.default'
            Domain = 'artifacts'
            Enabled = $true
            AutoRemediate = $false
            MinimumSeverity = 'Medium'
            Settings = @{
                ProtectPowerShellHistory = $true
                ProtectRecentItems = $true
                ProtectTemp = $false
            }
        }
    )
}

function Initialize-AegisPrivacyPolicy {
    [CmdletBinding()]
    param()

    $path = Get-AegisPrivacyPolicyPath
    $parent = Split-Path $path -Parent

    New-Item -ItemType Directory -Force -Path $parent | Out-Null

    if (-not (Test-Path $path)) {
        Get-AegisDefaultPrivacyPolicy |
            ConvertTo-Json -Depth 20 |
            Set-Content -Path $path -Encoding UTF8
    }

    return $path
}

function Get-AegisPrivacyPolicy {
    [CmdletBinding()]
    param()

    $path = Initialize-AegisPrivacyPolicy
    return @(Get-Content $path -Raw | ConvertFrom-Json)
}

function Save-AegisPrivacyPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Policy
    )

    $path = Initialize-AegisPrivacyPolicy
    $Policy |
        ForEach-Object {
            $_.UpdatedAt = [datetime]::UtcNow
            $_
        } |
        ConvertTo-Json -Depth 20 |
        Set-Content -Path $path -Encoding UTF8
}

function Test-AegisPrivacyPolicyMatch {
    param(
        [Parameter(Mandatory)]
        [AegisPrivacyObservation]$Observation,

        [Parameter(Mandatory)]
        [object]$Policy
    )

    if (-not [bool]$Policy.Enabled) {
        return $false
    }

    if ([string]$Policy.Domain -ne $Observation.Domain) {
        return $false
    }

    $severityOrder = @{
        Info = 0
        Low = 1
        Medium = 2
        High = 3
        Critical = 4
    }

    return (
        $severityOrder[[string]$Observation.Severity] -ge
        $severityOrder[[string]$Policy.MinimumSeverity]
    )
}

function Invoke-AegisPrivacyPolicyEvaluation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AegisPrivacyObservation[]]$Observations,

        [switch]$AutoRemediate
    )

    $policies = Get-AegisPrivacyPolicy
    $decisions = @()

    foreach ($observation in $Observations) {
        $matchingPolicies = @(
            $policies |
                Where-Object {
                    Test-AegisPrivacyPolicyMatch `
                        -Observation $observation `
                        -Policy $_
                }
        )

        if ($matchingPolicies.Count -eq 0) {
            continue
        }

        foreach ($policy in $matchingPolicies) {
            $shouldRemediate = (
                [bool]$policy.AutoRemediate -and
                $AutoRemediate -and
                $observation.Exposed -and
                $observation.Remediable
            )

            $decisions += [pscustomobject]@{
                PolicyId = $policy.Id
                ObservationId = $observation.Id
                Domain = $observation.Domain
                Severity = [string]$observation.Severity
                Exposed = $observation.Exposed
                Remediable = $observation.Remediable
                Action = if ($shouldRemediate) { 'remediate' } else { 'observe' }
                AutoRemediate = $shouldRemediate
            }

            if ($shouldRemediate) {
                Invoke-AegisPrivacyRemediation `
                    -Observation $observation `
                    -Force `
                    -Confirm:$false
            }
        }
    }

    return $decisions
}