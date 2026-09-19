function Get-AegisPrivacyCapabilities {
    [CmdletBinding()]
    param()

    @(
        [pscustomobject]@{
            Id = 'privacy.location.audit'
            Domain = 'location'
            Action = 'audit'
            Platform = 'windows'
            Implemented = $true
        }
        [pscustomobject]@{
            Id = 'privacy.location.remediate'
            Domain = 'location'
            Action = 'remediate'
            Platform = 'windows'
            Implemented = $true
        }
        [pscustomobject]@{
            Id = 'privacy.browser.audit'
            Domain = 'browser'
            Action = 'audit'
            Platform = 'windows'
            Implemented = $true
        }
        [pscustomobject]@{
            Id = 'privacy.browser.remediate'
            Domain = 'browser'
            Action = 'remediate'
            Platform = 'windows'
            Implemented = $true
        }
        [pscustomobject]@{
            Id = 'privacy.artifacts.audit'
            Domain = 'artifacts'
            Action = 'audit'
            Platform = 'windows'
            Implemented = $true
        }
        [pscustomobject]@{
            Id = 'privacy.artifacts.sanitize'
            Domain = 'artifacts'
            Action = 'remediate'
            Platform = 'windows'
            Implemented = $true
        }
        [pscustomobject]@{
            Id = 'privacy.policy.evaluate'
            Domain = 'policy'
            Action = 'evaluate'
            Platform = 'cross-platform'
            Implemented = $true
        }
    )
}