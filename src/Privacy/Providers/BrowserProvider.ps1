function Get-AegisBrowserPrivacyState {
    [CmdletBinding()]
    param()

    $profiles = @(
        @{
            Name = 'Chrome'
            Registry = 'HKCU:\Software\Google\Chrome\BLBeacon'
        }
        @{
            Name = 'Edge'
            Registry = 'HKCU:\Software\Microsoft\Edge\BLBeacon'
        }
        @{
            Name = 'Firefox'
            Registry = 'HKCU:\Software\Mozilla\Mozilla Firefox'
        }
    )

    $results = @()

    foreach ($browser in $profiles) {
        $installed = Test-Path $browser.Registry

        $observation = [AegisPrivacyObservation]::new()
        $observation.Id = "browser.$($browser.Name.ToLower()).installed"
        $observation.Domain = 'browser'
        $observation.Provider = 'browser.discovery'
        $observation.Title = "$($browser.Name) browser profile"
        $observation.Description = "Detects whether $($browser.Name) appears to be installed."
        $observation.Severity = [AegisPrivacySeverity]::Info
        $observation.Exposed = $installed
        $observation.Remediable = $installed
        $observation.State = if ($installed) { 'detected' } else { 'not_detected' }
        $observation.Evidence = @{
            RegistryPath = $browser.Registry
            Installed = $installed
        }

        $results += $observation
    }

    $results += Get-AegisChromiumBrowserPrivacyObservations -BrowserName 'Chrome'
    $results += Get-AegisChromiumBrowserPrivacyObservations -BrowserName 'Edge'

    return $results
}

function Get-AegisChromiumBrowserPrivacyObservations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Chrome','Edge')]
        [string]$BrowserName
    )

    $base = if ($BrowserName -eq 'Chrome') {
        Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'
    } else {
        Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'
    }

    if (-not (Test-Path $base)) {
        return @()
    }

    $profiles = Get-ChildItem -Path $base -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -eq 'Default' -or $_.Name -like 'Profile *'
        }

    $results = @()

    foreach ($profile in $profiles) {
        $history = Join-Path $profile.FullName 'History'
        $cookies = Join-Path $profile.FullName 'Cookies'
        $cache = Join-Path $profile.FullName 'Cache'

        foreach ($artifact in @(
            @{
                Name = 'history'
                Path = $history
                Severity = [AegisPrivacySeverity]::Medium
            }
            @{
                Name = 'cookies'
                Path = $cookies
                Severity = [AegisPrivacySeverity]::High
            }
            @{
                Name = 'cache'
                Path = $cache
                Severity = [AegisPrivacySeverity]::Low
            }
        )) {
            $exists = Test-Path $artifact.Path

            if (-not $exists) {
                continue
            }

            $observation = [AegisPrivacyObservation]::new()
            $observation.Id = "browser.$($BrowserName.ToLower()).$($profile.Name.ToLower()).$($artifact.Name)"
            $observation.Domain = 'browser'
            $observation.Provider = 'chromium.profile'
            $observation.Title = "$BrowserName $($artifact.Name)"
            $observation.Description = "Browser privacy artifact detected in $($profile.Name)."
            $observation.Severity = $artifact.Severity
            $observation.Exposed = $true
            $observation.Remediable = $true
            $observation.State = 'present'
            $observation.Evidence = @{
                Browser = $BrowserName
                Profile = $profile.Name
                Path = $artifact.Path
            }

            $results += $observation
        }
    }

    return $results
}