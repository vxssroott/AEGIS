$ErrorActionPreference = 'Stop'

$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " AEGIS CLI TESTS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

& powershell.exe `
    -NoLogo `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File (Join-Path $root "aegis.ps1") `
    version

if ($LASTEXITCODE -ne 0) {
    throw "CLI version command failed."
}

& powershell.exe `
    -NoLogo `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File (Join-Path $root "aegis.ps1") `
    status

if ($LASTEXITCODE -ne 0) {
    throw "CLI status command failed."
}

& powershell.exe `
    -NoLogo `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File (Join-Path $root "aegis.ps1") `
    verify

if ($LASTEXITCODE -ne 0) {
    throw "CLI verify command failed."
}

& powershell.exe `
    -NoLogo `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File (Join-Path $root "aegis.ps1") `
    network `
    interfaces

if ($LASTEXITCODE -ne 0) {
    throw "CLI network interfaces command failed."
}

& powershell.exe `
    -NoLogo `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File (Join-Path $root "aegis.ps1") `
    capabilities

if ($LASTEXITCODE -ne 0) {
    throw "CLI capabilities command failed."
}

Write-Host ""
Write-Host "[PASS] AEGIS CLI control plane is operational." -ForegroundColor Green
