[CmdletBinding(SupportsShouldProcess)]
param()
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path $PSScriptRoot).Path
$Bin = Join-Path $HOME "bin"
$Launcher = Join-Path $Bin "aegis.ps1"
$CmdLauncher = Join-Path $Bin "aegis.cmd"
$UserPath = [Environment]::GetEnvironmentVariable("Path","User")
$Remaining = @($UserPath -split ";" | Where-Object { $_ -and $_ -ne $Bin })
[Environment]::SetEnvironmentVariable("Path",($Remaining -join ";"),"User")
if (($env:Path -split ";") -contains $Bin) { $env:Path = (($env:Path -split ";" | Where-Object { $_ -and $_ -ne $Bin }) -join ";") }
if (Test-Path $Launcher) { Remove-Item $Launcher -Force }
if (Test-Path $CmdLauncher) { Remove-Item $CmdLauncher -Force }
Write-Host "AEGIS launcher removed." -ForegroundColor Green
Write-Host "Repository data and source files were preserved." -ForegroundColor Yellow
