function Get-AegisRepositoryRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Add-AegisNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true)]
        [string]$Summary,

        [ValidateSet("Info","Low","Medium","High","Critical")]
        [string]$Severity = "Info",

        [string]$ReportId = "",

        [bool]$CreatedOffline = $false
    )

    $repoRoot = Get-AegisRepositoryRoot
    $dir = Join-Path $repoRoot "data\notifications"

    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $event = [ordered]@{
        id              = [guid]::NewGuid().ToString()
        timestamp       = (Get-Date).ToUniversalTime().ToString("o")
        severity        = $Severity
        category        = "AEGIS"
        title           = $Title
        summary         = $Summary
        report_id       = $ReportId
        created_offline = $CreatedOffline
        delivery_status = "queued"
        delivered_at    = $null
    }

    $path = Join-Path $dir "queue.jsonl"

    $event |
        ConvertTo-Json -Depth 20 -Compress |
        Add-Content -LiteralPath $path -Encoding UTF8

    return [pscustomobject]$event
}
