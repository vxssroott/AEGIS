function Get-AegisLocationPrivacyState {
    [CmdletBinding()]
    param()

    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
    )

    $observations = @()

    foreach ($path in $paths) {
        if (-not (Test-Path $path)) {
            continue
        }

        $item = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue

        $value = $item.Value
        if ($null -eq $value) {
            $value = 'unknown'
        }

        $observation = [AegisPrivacyObservation]::new()
        $observation.Id = 'location.windows.consent'
        $observation.Domain = 'location'
        $observation.Provider = 'windows.location'
        $observation.Title = 'Windows location access'
        $observation.Description = "Windows location consent state from $path."
        $observation.Severity = [AegisPrivacySeverity]::Medium
        $observation.Exposed = ($value -eq 'Allow')
        $observation.Remediable = $true
        $observation.State = [string]$value
        $observation.Evidence = @{
            Path = $path
            Value = $value
        }

        $observations += $observation
    }

    if ($observations.Count -eq 0) {
        $observation = [AegisPrivacyObservation]::new()
        $observation.Id = 'location.windows.consent'
        $observation.Domain = 'location'
        $observation.Provider = 'windows.location'
        $observation.Title = 'Windows location access'
        $observation.Description = 'Location consent state could not be determined.'
        $observation.Severity = [AegisPrivacySeverity]::Low
        $observation.Exposed = $false
        $observation.Remediable = $false
        $observation.State = 'unknown'
        $observations += $observation
    }

    return $observations
}

function Backup-AegisLocationPrivacyState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TransactionId
    )

    $backupRoot = Join-Path $PSScriptRoot '..\..\..\data\privacy\backups'
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

    $file = Join-Path $backupRoot "$TransactionId-location.json"

    $state = @()

    foreach ($path in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
    )) {
        if (Test-Path $path) {
            $item = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            $state += [pscustomobject]@{
                Path = $path
                Value = $item.Value
            }
        }
    }

    $state | ConvertTo-Json -Depth 10 | Set-Content -Path $file -Encoding UTF8
    return $file
}

function Set-AegisLocationPrivacy {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Disable','Restore')]
        [string]$Action,

        [string]$BackupFile
    )

    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
    )

    if ($Action -eq 'Disable') {
        foreach ($path in $paths) {
            if (Test-Path $path) {
                if ($PSCmdlet.ShouldProcess($path, 'Disable location consent')) {
                    Set-ItemProperty -Path $path -Name Value -Value 'Deny' -ErrorAction Stop
                }
            }
        }
        return
    }

    if (-not $BackupFile -or -not (Test-Path $BackupFile)) {
        throw 'A valid location backup is required for restoration.'
    }

    $state = Get-Content $BackupFile -Raw | ConvertFrom-Json

    foreach ($entry in @($state)) {
        if (Test-Path $entry.Path) {
            if ($PSCmdlet.ShouldProcess($entry.Path, 'Restore location consent')) {
                Set-ItemProperty -Path $entry.Path -Name Value -Value ([string]$entry.Value) -ErrorAction Stop
            }
        }
    }
}