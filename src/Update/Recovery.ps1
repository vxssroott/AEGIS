Set-StrictMode -Version Latest

function Get-AegisRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function New-AegisBackup {
    $root = Get-AegisRoot
    $backupRoot = Join-Path $root "data\backups"

    $id = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ")
    $destination = Join-Path $backupRoot $id

    New-Item -ItemType Directory -Path $destination -Force | Out-Null

    $critical = @(
        "config",
        "policies",
        "versions",
        "src",
        "aegis.ps1",
        "install.ps1"
    )

    foreach ($item in $critical) {
        $source = Join-Path $root $item

        if (Test-Path $source) {
            Copy-Item $source $destination -Recurse -Force
        }
    }

    return $destination
}

function Get-AegisBackups {
    $root = Get-AegisRoot
    $path = Join-Path $root "data\backups"

    if (-not (Test-Path $path)) {
        return @()
    }

    return @(Get-ChildItem $path -Directory | Sort-Object Name -Descending)
}

function Restore-AegisBackup {
    param(
        [Parameter(Mandatory)]
        [string]$BackupPath
    )

    $root = Get-AegisRoot

    if (-not (Test-Path $BackupPath -PathType Container)) {
        throw "Backup does not exist: $BackupPath"
    }

    $items = Get-ChildItem $BackupPath -Force

    foreach ($item in $items) {
        Copy-Item $item.FullName $root -Recurse -Force
    }

    return $true
}
