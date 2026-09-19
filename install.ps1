[CmdletBinding()]
param([switch]$SkipPathUpdate)
$ErrorActionPreference = "Stop"
$Root = (Resolve-Path $PSScriptRoot).Path
$Bin = Join-Path $HOME "bin"
$Entry = Join-Path $Root "aegis.ps1"
if (-not (Test-Path $Entry)) { throw "AEGIS entrypoint not found." }
New-Item -ItemType Directory -Force $Bin | Out-Null
foreach ($d in @("data","data\events","data\reports","data\diagnostics","data\backups","data\updates","logs","reports","versions")) { New-Item -ItemType Directory -Force (Join-Path $Root $d) | Out-Null }
$VersionFile = Join-Path $Root "versions\current.json"
if (-not (Test-Path $VersionFile)) { @{version="0.1.0";channel="stable";schemaVersion=1;installedAt=(Get-Date).ToUniversalTime().ToString("o")} | ConvertTo-Json | Set-Content $VersionFile -Encoding UTF8 }
$Launcher = Join-Path $Bin "aegis.ps1"
$LauncherLines = @(
    'param([Parameter(ValueFromRemainingArguments = $true)][string[]]$CommandArgs)'
    '$Entry = Join-Path $HOME "AEGIS\aegis.ps1"'
    'if (-not (Test-Path $Entry)) { Write-Error "AEGIS installation not found."; exit 1 }'
    '& powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $Entry @CommandArgs'
    'exit $LASTEXITCODE'
)
Set-Content $Launcher $LauncherLines -Encoding UTF8
$Cmd = Join-Path $Bin "aegis.cmd"
$CmdLines = @(
    '@echo off'
    'powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\bin\aegis.ps1" %*'
    'exit /b %ERRORLEVEL%'
)
Set-Content $Cmd $CmdLines -Encoding ASCII
if (-not $SkipPathUpdate) {
    $Path = [Environment]::GetEnvironmentVariable("Path","User")
    if (($Path -split ";") -notcontains $Bin) { [Environment]::SetEnvironmentVariable("Path",(($Path.TrimEnd(";") + ";" + $Bin).Trim(";")),"User") }
    if (($env:Path -split ";") -notcontains $Bin) { $env:Path = "$Bin;$env:Path" }
}
Write-Host "AEGIS installation complete." -ForegroundColor Green
