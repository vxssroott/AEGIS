function New-AegisReport {
    param([object[]]$Observations,[object[]]$Verification)
    [pscustomobject]@{
        SchemaVersion='1.0'
        GeneratedAt=(Get-Date).ToUniversalTime().ToString('o')
        Host=$env:COMPUTERNAME
        ObservationCount=$Observations.Count
        VerificationCount=$Verification.Count
        Observations=$Observations
        Verification=$Verification
    }
}
function Save-AegisReport {
    param([object]$Report)
    $dir=Join-Path $PSScriptRoot '../../data/reports';New-Item -ItemType Directory -Force $dir|Out-Null
    $path=Join-Path $dir ("report-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $Report|ConvertTo-Json -Depth 30|Set-Content $path -Encoding utf8
    $Report|ConvertTo-Json -Depth 30|Set-Content (Join-Path $dir 'latest.json') -Encoding utf8
    $path
}
