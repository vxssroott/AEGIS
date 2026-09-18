function Write-AegisAuditEvent {
    param([string]$Action,[string]$Target,[object]$PreviousState,[object]$NewState,[string]$Result,[object]$Verification)
    $dir=Join-Path $PSScriptRoot '../../data/events';New-Item -ItemType Directory -Force $dir|Out-Null
    [pscustomobject]@{Timestamp=(Get-Date).ToUniversalTime().ToString('o');Action=$Action;Target=$Target;PreviousState=$PreviousState;NewState=$NewState;Result=$Result;Verification=$Verification}|ConvertTo-Json -Depth 20 -Compress|Add-Content (Join-Path $dir 'events.jsonl') -Encoding utf8
}
