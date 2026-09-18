$ErrorActionPreference='Stop'
$root=Resolve-Path "$PSScriptRoot/../.."
. "$root/src/Exposure/Engine.ps1"
. "$root/src/Verification/Engine.ps1"
$obs=@(Invoke-AegisExposureScan)
$ver=@(Invoke-AegisVerification)
if($null -eq $obs -or $null -eq $ver){throw 'Phase 2 engine validation failed.'}
Write-Host "Phase 2 engines operational: $($obs.Count) observations / $($ver.Count) verification checks" -ForegroundColor Green
