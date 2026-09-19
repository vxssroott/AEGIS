enum AegisPrivacySeverity {
    Info
    Low
    Medium
    High
    Critical
}

enum AegisPrivacyAction {
    Observe
    Recommend
    Remediate
    Restore
}

class AegisPrivacyObservation {
    [string]$Id
    [string]$Domain
    [string]$Provider
    [string]$Title
    [string]$Description
    [AegisPrivacySeverity]$Severity
    [bool]$Exposed
    [bool]$Remediable
    [string]$State
    [hashtable]$Evidence
    [datetime]$ObservedAt

    AegisPrivacyObservation() {
        $this.ObservedAt = [datetime]::UtcNow
        $this.Evidence = @{}
        $this.State = 'unknown'
    }
}

class AegisPrivacyRemediationResult {
    [string]$TransactionId
    [string]$ObservationId
    [string]$Action
    [bool]$Success
    [string]$State
    [string]$Message
    [hashtable]$Evidence
    [datetime]$StartedAt
    [datetime]$CompletedAt

    AegisPrivacyRemediationResult() {
        $this.Evidence = @{}
        $this.StartedAt = [datetime]::UtcNow
    }
}

class AegisPrivacyPolicy {
    [string]$Id
    [string]$Domain
    [bool]$Enabled
    [bool]$AutoRemediate
    [AegisPrivacySeverity]$MinimumSeverity
    [hashtable]$Settings
    [datetime]$UpdatedAt
}