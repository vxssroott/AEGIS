Set-StrictMode -Version Latest

function New-AegisDiagnosticReport {
    param(
        [object]$DoctorResult
    )

    $root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    $reportRoot = Join-Path $root "reports"

    if (-not (Test-Path $reportRoot)) {
        New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null
    }

    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ")
    $path = Join-Path $reportRoot "doctor-$timestamp.json"

    $payload = [ordered]@{
        Product = "AEGIS"
        Type = "DiagnosticReport"
        Timestamp = (Get-Date).ToUniversalTime().ToString("o")
        Version = (Get-AegisVersionManifest).Version
        Healthy = [bool]$DoctorResult.Healthy
        Checks = $DoctorResult.Checks
        Failed = $DoctorResult.Failed
    }

    $payload |
        ConvertTo-Json -Depth 10 |
        Set-Content $path -Encoding UTF8

    return $path
}

function Get-AegisReports {
    $root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    $path = Join-Path $root "reports"

    if (-not (Test-Path $path)) {
        return @()
    }

    return @(Get-ChildItem $path -File | Sort-Object LastWriteTime -Descending)
}
