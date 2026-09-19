function Invoke-AegisPrivacyCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('audit','policy','capabilities','remediate','location','browser','artifacts')]
        [string]$Action,

        [string]$ObservationId,

        [switch]$AutoRemediate,

        [switch]$Force
    )

    Import-AegisPrivacyControlPlane

    switch ($Action) {
        'audit' {
            Invoke-AegisPrivacyAudit
        }

        'policy' {
            Invoke-AegisPrivacyPolicy -AutoRemediate:$AutoRemediate
        }

        'capabilities' {
            Get-AegisPrivacyCapabilities
        }

        'remediate' {
            if (-not $ObservationId) {
                throw 'Use -ObservationId with privacy remediate.'
            }

            Invoke-AegisPrivacyRemediationById `
                -ObservationId $ObservationId `
                -Force:$Force
        }

        'location' {
            Get-AegisLocationPrivacyState
        }

        'browser' {
            Get-AegisBrowserPrivacyState
        }

        'artifacts' {
            Get-AegisArtifactPrivacyState
        }
    }
}