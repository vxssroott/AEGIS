function New-AegisPrivacyTransactionId {
    return "PRV-$([datetime]::UtcNow.ToString('yyyyMMddHHmmssfff'))-$([guid]::NewGuid().ToString('N').Substring(0,8))"
}

function Write-AegisPrivacyTransaction {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Transaction
    )

    $root = Join-Path $PSScriptRoot '..\..\..\data\privacy\transactions'
    New-Item -ItemType Directory -Force -Path $root | Out-Null

    $file = Join-Path $root "$($Transaction.Id).json"
    $Transaction | ConvertTo-Json -Depth 20 | Set-Content -Path $file -Encoding UTF8
    return $file
}

function Invoke-AegisPrivacyRemediation {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [AegisPrivacyObservation]$Observation,

        [switch]$Force
    )

    if (-not $Observation.Remediable) {
        throw "Observation '$($Observation.Id)' is not remediable."
    }

    $transactionId = New-AegisPrivacyTransactionId
    $started = [datetime]::UtcNow

    $transaction = @{
        Id = $transactionId
        ObservationId = $Observation.Id
        Domain = $Observation.Domain
        Provider = $Observation.Provider
        Action = 'remediate'
        StartedAt = $started
        State = 'prepared'
        Backup = $null
        Result = $null
    }

    try {
        switch ($Observation.Domain) {
            'location' {
                $transaction.Backup = Backup-AegisLocationPrivacyState -TransactionId $transactionId

                if ($PSCmdlet.ShouldProcess(
                    'Windows location consent',
                    'Disable location access'
                )) {
                    Set-AegisLocationPrivacy -Action Disable -Confirm:$false
                }
            }

            'browser' {
                $path = [string]$Observation.Evidence.Path

                if (-not $Force) {
                    throw "Browser artifact remediation requires -Force because it deletes local browser state."
                }

                if (-not (Test-Path $path)) {
                    throw "Browser artifact no longer exists: $path"
                }

                $transaction.Backup = Join-Path (
                    Join-Path $PSScriptRoot '..\..\..\data\privacy\backups'
                ) "$transactionId-browser"

                New-Item -ItemType Directory -Force -Path $transaction.Backup | Out-Null

                $target = Get-Item $path

                if ($target.PSIsContainer) {
                    Copy-Item $path (Join-Path $transaction.Backup $target.Name) -Recurse -Force
                } else {
                    Copy-Item $path (Join-Path $transaction.Backup $target.Name) -Force
                }

                if ($PSCmdlet.ShouldProcess($path, 'Remove browser privacy artifact')) {
                    Remove-Item $path -Recurse -Force -ErrorAction Stop
                }
            }

            'artifacts' {
                $path = [string]$Observation.Evidence.Path

                if (-not $Force) {
                    throw "Artifact sanitization requires -Force because it deletes local artifacts."
                }

                if (-not (Test-Path $path)) {
                    throw "Artifact no longer exists: $path"
                }

                $transaction.Backup = Join-Path (
                    Join-Path $PSScriptRoot '..\..\..\data\privacy\backups'
                ) "$transactionId-artifact"

                New-Item -ItemType Directory -Force -Path $transaction.Backup | Out-Null

                $target = Get-Item $path

                if ($target.PSIsContainer) {
                    Get-ChildItem $path -Force -ErrorAction SilentlyContinue |
                        ForEach-Object {
                            try {
                                if ($_.PSIsContainer) {
                                    Copy-Item $_.FullName (Join-Path $transaction.Backup $_.Name) -Recurse -Force
                                } else {
                                    Copy-Item $_.FullName (Join-Path $transaction.Backup $_.Name) -Force
                                }
                            } catch {}
                        }
                } else {
                    Copy-Item $path (Join-Path $transaction.Backup $target.Name) -Force
                }

                if ($PSCmdlet.ShouldProcess($path, 'Sanitize privacy artifact')) {
                    if ($target.PSIsContainer) {
                        Get-ChildItem $path -Force -ErrorAction SilentlyContinue |
                            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    } else {
                        Remove-Item $path -Force -ErrorAction Stop
                    }
                }
            }

            default {
                throw "No remediation provider registered for domain '$($Observation.Domain)'."
            }
        }

        $transaction.State = 'committed'
        $transaction.Result = @{
            Success = $true
            Message = 'Privacy remediation completed.'
        }
    }
    catch {
        $transaction.State = 'failed'
        $transaction.Result = @{
            Success = $false
            Message = $_.Exception.Message
        }
    }

    $transactionFile = Write-AegisPrivacyTransaction -Transaction $transaction

    $result = [AegisPrivacyRemediationResult]::new()
    $result.TransactionId = $transactionId
    $result.ObservationId = $Observation.Id
    $result.Action = 'remediate'
    $result.Success = ($transaction.State -eq 'committed')
    $result.State = $transaction.State
    $result.Message = [string]$transaction.Result.Message
    $result.Evidence = @{
        TransactionFile = $transactionFile
        Backup = $transaction.Backup
    }
    $result.CompletedAt = [datetime]::UtcNow

    return $result
}