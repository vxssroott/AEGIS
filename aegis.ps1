[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CommandArgs
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$moduleFiles = @(
    "$root\src\Core\State.ps1",

    "$root\src\Storage\EventStore.ps1",
    "$root\src\Storage\StateStore.ps1",
    "$root\src\Storage\ReportStore.ps1",

    "$root\src\Security\Health.ps1",
    "$root\src\Security\Integrity.ps1",

    "$root\src\Versioning\Version.ps1",

    "$root\src\Exposure\Engine.ps1",
    "$root\src\Verification\Engine.ps1",
    "$root\src\Remediation\Engine.ps1",

    "$root\src\Network\Interfaces.ps1",
    "$root\src\Network\Identity.ps1",
    "$root\src\Network\Leaks.ps1",

    "$root\src\Diagnostics\Doctor.ps1",

    "$root\src\Reporting\Engine.ps1",
    "$root\src\Reporting\Reports.ps1",
    "$root\src\Reporting\Digest.ps1",
    "$root\src\Reporting\Text.ps1",
    "$root\src\Reporting\JSON.ps1",

    "$root\src\Update\Recovery.ps1",
    "$root\src\Update\UpdateTransaction.ps1",

    "$root\src\CLI\Parser.ps1",
    "$root\src\CLI\Help.ps1",
    "$root\src\CLI\CommandBus.ps1",
    "$root\src\CLI\Dispatcher.ps1"
)

foreach ($file in $moduleFiles) {
    if (-not (Test-Path -LiteralPath $file)) {
        throw "Required AEGIS module is missing: $file"
    }

    . $file
}

$parsed = Parse-AegisArguments -Arguments @($CommandArgs)

try {
    Invoke-AegisCommandBus -ParsedCommand $parsed
}
catch {
    Write-Host ""
    Write-Host "AEGIS COMMAND FAILURE" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    exit 1
}
