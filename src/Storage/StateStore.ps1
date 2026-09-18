function Get-AegisRepositoryRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Save-AegisState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$State
    )

    $repoRoot = Get-AegisRepositoryRoot
    $dir = Join-Path $repoRoot "data\state"

    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $State["timestamp"] = (Get-Date).ToUniversalTime().ToString("o")

    $path = Join-Path $dir "state.json"

    $State |
        ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $path -Encoding UTF8

    return $State
}

function Get-AegisState {
    [CmdletBinding()]
    param()

    $repoRoot = Get-AegisRepositoryRoot
    $path = Join-Path $repoRoot "data\state\state.json"

    if (-not (Test-Path $path)) {
        return $null
    }

    return (
        Get-Content -LiteralPath $path -Raw |
        ConvertFrom-Json
    )
}
