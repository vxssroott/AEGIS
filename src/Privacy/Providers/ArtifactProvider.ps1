function Get-AegisArtifactPrivacyState {
    [CmdletBinding()]
    param()

    $targets = @(
        @{
            Id = 'temp.user'
            Name = 'User temporary files'
            Path = $env:TEMP
            Severity = [AegisPrivacySeverity]::Low
        }
        @{
            Id = 'temp.windows'
            Name = 'Windows temporary files'
            Path = "$env:WINDIR\Temp"
            Severity = [AegisPrivacySeverity]::Low
        }
        @{
            Id = 'recent.items'
            Name = 'Recent items'
            Path = Join-Path $env:APPDATA 'Microsoft\Windows\Recent'
            Severity = [AegisPrivacySeverity]::Medium
        }
        @{
            Id = 'powershell.history'
            Name = 'PowerShell command history'
            Path = Join-Path $env:APPDATA 'Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'
            Severity = [AegisPrivacySeverity]::High
        }
    )

    $results = @()

    foreach ($target in $targets) {
        $exists = Test-Path $target.Path

        $count = 0
        if ($exists) {
            try {
                if ((Get-Item $target.Path).PSIsContainer) {
                    $count = @(Get-ChildItem -Path $target.Path -Force -ErrorAction SilentlyContinue).Count
                } else {
                    $count = 1
                }
            } catch {
                $count = -1
            }
        }

        $observation = [AegisPrivacyObservation]::new()
        $observation.Id = "artifact.$($target.Id)"
        $observation.Domain = 'artifacts'
        $observation.Provider = 'filesystem'
        $observation.Title = $target.Name
        $observation.Description = "Detects privacy-relevant local artifacts."
        $observation.Severity = $target.Severity
        $observation.Exposed = $exists -and ($count -ne 0)
        $observation.Remediable = $exists
        $observation.State = if (-not $exists) { 'absent' } elseif ($count -eq 0) { 'empty' } else { 'present' }
        $observation.Evidence = @{
            Path = $target.Path
            Count = $count
        }

        $results += $observation
    }

    return $results
}