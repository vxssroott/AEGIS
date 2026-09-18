function New-AegisObservation {
    param([string]$Provider,[string]$Category,[string]$Target,[string]$CurrentState,[string]$Exposure,[string]$Severity='info',[string]$Evidence='', [bool]$RemediationAvailable=$false)
    [pscustomobject]@{
        Timestamp=(Get-Date).ToUniversalTime().ToString('o')
        Provider=$Provider; Category=$Category; Target=$Target; CurrentState=$CurrentState
        Exposure=$Exposure; Severity=$Severity; Evidence=$Evidence
        RemediationAvailable=$RemediationAvailable
    }
}
