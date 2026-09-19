Set-StrictMode -Version Latest

$script:AegisEventRoot = Join-Path $PSScriptRoot '..\..\data\events'
$script:AegisEventLog = Join-Path $script:AegisEventRoot 'aegis-events.jsonl'

New-Item -ItemType Directory -Force -Path $script:AegisEventRoot | Out-Null

function Publish-AegisEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Type,

        [string]$Category = 'system',

        [ValidateSet('info','warning','critical')]
        [string]$Severity = 'info',

        [Parameter(Mandatory)]
        [string]$Message,

        [object]$Data = $null,

        [switch]$Voice
    )

    $event = [pscustomobject]@{
        EventId   = [guid]::NewGuid().Guid
        Timestamp = (Get-Date).ToUniversalTime().ToString('o')
        Type      = $Type
        Category  = $Category
        Severity  = $Severity
        Message   = $Message
        Data      = $Data
    }

    $json = $event | ConvertTo-Json -Depth 12 -Compress

    Add-Content -LiteralPath $script:AegisEventLog -Value $json -Encoding UTF8

    if ($Voice) {
        try {
            Invoke-AegisVoiceEvent -Event $event
        }
        catch {
            # Voice failure must never break the privacy control plane.
        }
    }

    return $event
}

function Get-AegisRecentEvents {
    [CmdletBinding()]
    param(
        [int]$Count = 25
    )

    if (-not (Test-Path -LiteralPath $script:AegisEventLog)) {
        return @()
    }

    return @(
        Get-Content -LiteralPath $script:AegisEventLog -Tail $Count |
            ForEach-Object {
                try {
                    $_ | ConvertFrom-Json
                }
                catch {
                }
            }
    )
}
