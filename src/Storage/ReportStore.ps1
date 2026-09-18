function Get-AegisRepositoryRoot {
    [CmdletBinding()]
    param()

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Save-AegisReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$Report
    )

    $repoRoot = Get-AegisRepositoryRoot
    $dir = Join-Path $repoRoot "data\reports"

    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $id = if ($Report.id) {
        [string]$Report.id
    }
    else {
        [guid]::NewGuid().ToString()
    }

    $path = Join-Path $dir "$id.json"

    $Report |
        ConvertTo-Json -Depth 30 |
        Set-Content -LiteralPath $path -Encoding UTF8

    return $path
}
