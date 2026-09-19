Set-StrictMode -Version Latest

function Get-AegisFileHashSafe {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File does not exist: $Path"
    }

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-AegisTreeFingerprint {
    param(
        [string]$Root
    )

    if ([string]::IsNullOrWhiteSpace($Root)) {
        $Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    }

    $files = Get-ChildItem -LiteralPath $Root -File -Recurse |
        Where-Object {
            $_.FullName -notmatch '\\\.git\\' -and
            $_.FullName -notmatch '\\data\\backups\\' -and
            $_.FullName -notmatch '\\data\\updates\\'
        } |
        Sort-Object FullName

    $records = @()

    foreach ($file in $files) {
        $relative = $file.FullName.Substring($Root.Length).TrimStart("\")
        $hash = Get-AegisFileHashSafe -Path $file.FullName
        $records += "$relative|$hash"
    }

    $payload = ($records -join "`n")

    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        $digest = $sha.ComputeHash($bytes)

        return (-join ($digest | ForEach-Object {
            $_.ToString("x2")
        }))
    }
    finally {
        $sha.Dispose()
    }
}

function Test-AegisFileIntegrity {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$ExpectedHash
    )

    $actual = Get-AegisFileHashSafe -Path $Path

    return [pscustomobject]@{
        Path = $Path
        Expected = $ExpectedHash.ToLowerInvariant()
        Actual = $actual
        Valid = ($actual -eq $ExpectedHash.ToLowerInvariant())
    }
}
