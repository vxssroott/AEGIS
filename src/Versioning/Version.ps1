Set-StrictMode -Version Latest

function Get-AegisRepositoryRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Get-AegisVersionManifest {
    $root = Get-AegisRepositoryRoot
    $path = Join-Path $root "versions\current.json"

    if (-not (Test-Path $path)) {
        return [pscustomobject]@{
            Version = "0.0.0"
            Channel = "stable"
            SchemaVersion = 1
            InstalledAt = $null
        }
    }

    return (Get-Content $path -Raw | ConvertFrom-Json)
}

function Set-AegisVersionManifest {
    param(
        [Parameter(Mandatory)]
        [string]$Version,

        [string]$Channel = "stable"
    )

    $root = Get-AegisRepositoryRoot
    $path = Join-Path $root "versions\current.json"

    $manifest = [ordered]@{
        Version = $Version
        Channel = $Channel
        SchemaVersion = 1
        InstalledAt = (Get-Date).ToUniversalTime().ToString("o")
    }

    $manifest |
        ConvertTo-Json -Depth 5 |
        Set-Content -Path $path -Encoding UTF8

    return [pscustomobject]$manifest
}

function Test-AegisVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )

    return $Version -match '^\d+\.\d+\.\d+([\-+][0-9A-Za-z\.-]+)?$'
}

function Compare-AegisVersions {
    param(
        [Parameter(Mandatory)]
        [string]$Current,

        [Parameter(Mandatory)]
        [string]$Candidate
    )

    if (-not (Test-AegisVersion $Current)) {
        throw "Invalid current version: $Current"
    }

    if (-not (Test-AegisVersion $Candidate)) {
        throw "Invalid candidate version: $Candidate"
    }

    $currentCore = ($Current -split '[-+]')[0]
    $candidateCore = ($Candidate -split '[-+]')[0]

    $currentParts = $currentCore.Split(".") | ForEach-Object { [int]$_ }
    $candidateParts = $candidateCore.Split(".") | ForEach-Object { [int]$_ }

    for ($i = 0; $i -lt 3; $i++) {
        if ($candidateParts[$i] -gt $currentParts[$i]) { return 1 }
        if ($candidateParts[$i] -lt $currentParts[$i]) { return -1 }
    }

    return 0
}
