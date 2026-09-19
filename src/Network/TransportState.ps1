Set-StrictMode -Version Latest

$script:AegisTransportStateFile =
    Join-Path $PSScriptRoot '..\..\data\transport\transport-state.json'

New-Item -ItemType Directory -Force `
    -Path (Split-Path $script:AegisTransportStateFile -Parent) | Out-Null

function Get-AegisTransportState {
    [CmdletBinding()]
    param()

    if (-not (Test-Path -LiteralPath $script:AegisTransportStateFile)) {
        return [pscustomobject]@{
            Timestamp = (Get-Date).ToUniversalTime().ToString('o')
            State     = 'Detached'
            ActiveId  = $null
            Verified  = $false
            Identity  = $null
        }
    }

    try {
        return Get-Content -LiteralPath $script:AegisTransportStateFile -Raw |
            ConvertFrom-Json
    }
    catch {
        return [pscustomobject]@{
            Timestamp = (Get-Date).ToUniversalTime().ToString('o')
            State     = 'Failed'
            ActiveId  = $null
            Verified  = $false
            Identity  = $null
        }
    }
}

function Set-AegisTransportState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            'Detached',
            'Establishing',
            'Verifying',
            'Active',
            'Degraded',
            'Rotating',
            'Failed',
            'Recovering'
        )]
        [string]$State,

        [string]$ActiveId = $null,

        [bool]$Verified = $false,

        [string]$Identity = $null
    )

    $record = [pscustomobject]@{
        Timestamp = (Get-Date).ToUniversalTime().ToString('o')
        State     = $State
        ActiveId  = $ActiveId
        Verified  = $Verified
        Identity  = $Identity
    }

    $record |
        ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $script:AegisTransportStateFile -Encoding UTF8

    return $record
}
