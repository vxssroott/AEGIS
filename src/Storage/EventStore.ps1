function Get-AegisRepositoryRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Write-AegisEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Category,

        [Parameter(Mandatory=$true)]
        [string]$Title,

        [string]$Summary = "",

        [ValidateSet("Info","Low","Medium","High","Critical")]
        [string]$Severity = "Info",

        [hashtable]$Data = @{}
    )

    $repoRoot = Get-AegisRepositoryRoot
    $eventDir = Join-Path $repoRoot "data\events"

    New-Item -ItemType Directory -Force -Path $eventDir | Out-Null

    $event = [ordered]@{
        id        = [guid]::NewGuid().ToString()
        timestamp = (Get-Date).ToUniversalTime().ToString("o")
        category  = $Category
        title     = $Title
        summary   = $Summary
        severity  = $Severity
        data      = $Data
    }

    $date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
    $file = Join-Path $eventDir "$date.jsonl"

    $event |
        ConvertTo-Json -Depth 20 -Compress |
        Add-Content -LiteralPath $file -Encoding UTF8

    return [pscustomobject]$event
}
