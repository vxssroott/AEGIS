Set-StrictMode -Version Latest

function Invoke-AegisUpdateTransaction {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Apply,

        [scriptblock]$HealthCheck
    )

    $root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

    $backup = New-AegisBackup

    $result = [ordered]@{
        Success = $false
        Backup = $backup
        Started = (Get-Date).ToUniversalTime().ToString("o")
        Completed = $null
        Error = $null
    }

    try {
        & $Apply

        if ($null -ne $HealthCheck) {
            $health = & $HealthCheck

            if ($health -is [bool]) {
                if (-not $health) {
                    throw "Post-update health check failed."
                }
            }
            elseif ($health.PSObject.Properties["Healthy"]) {
                if (-not [bool]$health.Healthy) {
                    throw "Post-update health check failed."
                }
            }
        }

        $result.Success = $true
    }
    catch {
        $result.Error = $_.Exception.Message

        try {
            Restore-AegisBackup -BackupPath $backup | Out-Null
        }
        catch {
            $result.Error += " | Rollback failed: " + $_.Exception.Message
        }
    }

    $result.Completed = (Get-Date).ToUniversalTime().ToString("o")

    return [pscustomobject]$result
}
