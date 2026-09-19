$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

$modules = @(
    "src\Versioning\Version.ps1",
    "src\Security\Integrity.ps1",
    "src\Security\Health.ps1",
    "src\Update\Recovery.ps1",
    "src\Update\UpdateTransaction.ps1",
    "src\Diagnostics\Doctor.ps1",
    "src\Reporting\Reports.ps1"
)

foreach ($module in $modules) {
    $path = Join-Path $Root $module

    if (-not (Test-Path $path)) {
        throw "Missing module: $module"
    }

    . $path
}

Write-Host ""
Write-Host "AEGIS PHASE 5 VALIDATION" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan

$manifest = Get-AegisVersionManifest
if ($null -eq $manifest) {
    throw "Version manifest failed."
}

Write-Host "[PASS] Version engine loaded."

if (-not (Test-AegisVersion "1.2.3")) {
    throw "Semantic version validation failed."
}

Write-Host "[PASS] Version validation works."

if ((Compare-AegisVersions "1.0.0" "1.1.0") -ne 1) {
    throw "Version comparison failed."
}

Write-Host "[PASS] Version comparison works."

$fingerprint = Get-AegisTreeFingerprint -Root $Root

if ($fingerprint -notmatch '^[0-9a-f]{64}$') {
    throw "Invalid repository fingerprint."
}

Write-Host "[PASS] Repository fingerprint generated."

$health = Test-AegisHealth

if (-not $health.Healthy) {
    Write-Host ""
    $health.FailedChecks | Format-Table -AutoSize
    throw "AEGIS health check failed."
}

Write-Host "[PASS] Health check passed."

$doctor = Invoke-AegisDoctor

if (-not $doctor.Healthy) {
    $doctor.Failed | Format-Table -AutoSize
    throw "Doctor diagnostics failed."
}

Write-Host "[PASS] Doctor diagnostics passed."

$report = New-AegisDiagnosticReport -DoctorResult $doctor

if (-not (Test-Path $report)) {
    throw "Diagnostic report was not created."
}

Write-Host "[PASS] Diagnostic report generated."

$backup = New-AegisBackup

if (-not (Test-Path $backup)) {
    throw "Backup was not created."
}

Write-Host "[PASS] Backup engine created snapshot."

Write-Host ""
Write-Host "PHASE 5 CORE VALIDATION PASSED" -ForegroundColor Green
Write-Host "Fingerprint : $fingerprint"
Write-Host "Report      : $report"
Write-Host "Backup      : $backup"
Write-Host ""
