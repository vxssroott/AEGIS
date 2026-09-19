Set-StrictMode -Version Latest

function Write-AegisSection {
    param([string]$Title)

    Write-Host ""
    Write-Host ("=" * 64) -ForegroundColor DarkCyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 64) -ForegroundColor DarkCyan
}

function Write-AegisNotImplemented {
    param([string]$Feature)

    Write-Host ""
    Write-Host "NOT IMPLEMENTED" -ForegroundColor Yellow
    Write-Host "  $Feature"
    Write-Host ""
}

function Get-AegisAdminState {
    try {
        return ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )
    }
    catch {
        return $false
    }
}

function Invoke-AegisStatus {

    Write-AegisSection "AEGIS STATUS"

    $manifest = Get-AegisVersionManifest
    $health = Test-AegisHealth

    Write-Host "Version       : $($manifest.Version)"
    Write-Host "Channel       : $($manifest.Channel)"
    Write-Host "Host          : $env:COMPUTERNAME"
    Write-Host "User          : $env:USERNAME"
    Write-Host "Administrator : $(Get-AegisAdminState)"

    Write-Host ""
    Write-Host "CORE HEALTH"

    foreach ($check in @($health.Checks)) {
        $mark = if ($check.Passed) { "[PASS]" } else { "[FAIL]" }
        Write-Host "  $mark $($check.Check) - $($check.Detail)"
    }

    Write-Host ""
    Write-Host "NETWORK"

    try {
        $interfaces = @(Get-AegisNetworkInterfaces)

        Write-Host "  Interfaces : $($interfaces.Count)"

        foreach ($interface in $interfaces) {
            Write-Host "    $($interface.InterfaceAlias) [$($interface.Status)]"
        }
    }
    catch {
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "VERIFICATION"

    try {
        $verification = @(Invoke-AegisVerification)

        foreach ($result in $verification) {
            $mark = if ($result.Passed) { "[PASS]" } else { "[ATTENTION]" }

            Write-Host "  $mark $($result.Check): $($result.Status)"
            Write-Host "       $($result.Evidence)"
        }
    }
    catch {
        Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host ""
}

function Invoke-AegisAuditCommand {

    Write-AegisSection "AEGIS EXPOSURE AUDIT"

    try {
        $results = @(Invoke-AegisExposureScan)

        if ($results.Count -eq 0) {
            Write-Host "No observations returned."
            return
        }

        foreach ($result in $results) {

            $color = switch ([string]$result.Severity) {
                "high"   { "Red" }
                "medium" { "Yellow" }
                "low"    { "DarkYellow" }
                default  { "Gray" }
            }

            Write-Host ""
            Write-Host "[$($result.Severity.ToUpperInvariant())] $($result.Provider)/$($result.Category)" -ForegroundColor $color
            Write-Host "  Target      : $($result.Target)"
            Write-Host "  State       : $($result.CurrentState)"
            Write-Host "  Exposure    : $($result.Exposure)"
            Write-Host "  Evidence    : $($result.Evidence)"
            Write-Host "  Remediation : $($result.RemediationAvailable)"
        }

        try {
            Write-AegisEvent `
                -Category "Audit" `
                -Title "Exposure audit completed" `
                -Summary "$($results.Count) observations returned" `
                -Severity "Info" `
                -Data @{
                    ObservationCount = $results.Count
                } | Out-Null
        }
        catch {
            Write-Host ""
            Write-Host "[WARN] Audit event could not be persisted: $($_.Exception.Message)" -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "Observations: $($results.Count)"
    }
    catch {
        Write-Host "[ERROR] Exposure audit failed: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Invoke-AegisScanCommand {

    Write-AegisSection "AEGIS DEEP LOCAL SCAN"

    Invoke-AegisAuditCommand

    Write-AegisSection "NETWORK LEAK ANALYSIS"

    try {
        $leaks = Test-AegisNetworkLeaks

        Write-Host "Healthy : $($leaks.Healthy)"
        Write-Host "IPv6    : $(@($leaks.IPv6).Count)"
        Write-Host "Issues  : $(@($leaks.Issues).Count)"

        foreach ($issue in @($leaks.Issues)) {
            Write-Host ""
            Write-Host "[$($issue.Severity)] $($issue.Type)" -ForegroundColor Yellow
            Write-Host "  $($issue.Detail)"
        }
    }
    catch {
        Write-Host "[ERROR] Network leak analysis failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-AegisSection "NETWORK IDENTITY"

    try {
        $identity = Get-AegisNetworkIdentity

        Write-Host "Identity Type : $($identity.IdentityType)"
        Write-Host "VPN Detected  : $($identity.VPNDetected)"
        Write-Host "Tor Detected  : $($identity.TorDetected)"
        Write-Host "Proxy Detected: $($identity.ProxyDetected)"
        Write-Host "Interfaces    : $(@($identity.Interfaces).Count)"
        Write-Host "Routes        : $(@($identity.DefaultRoutes).Count)"
    }
    catch {
        Write-Host "[ERROR] Network identity analysis failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Invoke-AegisVerifyCommand {

    Write-AegisSection "AEGIS VERIFICATION"

    $results = @(Invoke-AegisVerification)

    foreach ($result in $results) {

        $color = if ($result.Passed) { "Green" } else { "Yellow" }
        $mark = if ($result.Passed) { "[PASS]" } else { "[ATTENTION]" }

        Write-Host "$mark $($result.Check)" -ForegroundColor $color
        Write-Host "  Status   : $($result.Status)"
        Write-Host "  Evidence : $($result.Evidence)"
        Write-Host ""
    }
}

function Invoke-AegisNetworkCommand {

    param(
        [string]$Subcommand
    )

    switch ($Subcommand) {

        { $_ -in @("", "status", "inspect") } {

            Write-AegisSection "AEGIS NETWORK"

            $interfaces = @(Get-AegisNetworkInterfaces)

            foreach ($interface in $interfaces) {
                Write-Host ""
                Write-Host "$($interface.InterfaceAlias)" -ForegroundColor Cyan
                Write-Host "  Index       : $($interface.InterfaceIndex)"
                Write-Host "  Status      : $($interface.Status)"
                Write-Host "  Description : $($interface.Description)"
                Write-Host "  MAC         : $($interface.MacAddress)"
                Write-Host "  IPv4        : $(@($interface.IPv4) -join ', ')"
                Write-Host "  IPv6        : $(@($interface.IPv6) -join ', ')"
                Write-Host "  Gateway     : $(@($interface.Gateway) -join ', ')"
                Write-Host "  DNS         : $(@($interface.DNS) -join ', ')"
            }

            return
        }

        "interfaces" {

            $interfaces = @(Get-AegisNetworkInterfaces)
            $interfaces | Format-List
            return
        }

        "identity" {

            $identity = Get-AegisNetworkIdentity

            Write-AegisSection "NETWORK IDENTITY"

            $identity | Format-List
            return
        }

        "fingerprint" {

            Write-AegisSection "NETWORK IDENTITY FINGERPRINT"

            $fingerprint = Get-AegisNetworkIdentityFingerprint

            Write-Host $fingerprint
            return
        }

        "leaks" {

            Write-AegisSection "NETWORK LEAK ANALYSIS"

            $result = Test-AegisNetworkLeaks

            Write-Host "Healthy : $($result.Healthy)"
            Write-Host "Issues  : $(@($result.Issues).Count)"

            foreach ($issue in @($result.Issues)) {
                Write-Host ""
                Write-Host "[$($issue.Severity)] $($issue.Type)" -ForegroundColor Yellow
                Write-Host $issue.Detail
            }

            return
        }

        "virtual" {

            Write-AegisSection "VIRTUAL / VPN-LIKE INTERFACES"

            $virtual = @(Get-AegisVirtualInterfaces)

            if ($virtual.Count -eq 0) {
                Write-Host "No matching virtual/VPN-like interfaces detected."
            }
            else {
                $virtual | Format-Table -AutoSize
            }

            return
        }

        "verify" {

            Invoke-AegisVerifyCommand
            return
        }

        default {
            Show-AegisHelp "network"
            return
        }
    }
}

function Invoke-AegisFixCommand {

    param(
        [string]$Subcommand,
        [hashtable]$Options
    )

    if ($Subcommand -eq "" -or $null -eq $Subcommand) {

        Write-AegisSection "AVAILABLE REMEDIATION"

        Write-Host "  firewall"
        Write-Host ""
        Write-Host "Supported remediation:"
        Write-Host "  aegis fix firewall --yes"
        Write-Host ""
        Write-Host "This currently enables disabled Windows Firewall profiles."
        return
    }

    if ($Subcommand -eq "firewall") {

        if (-not (Get-AegisAdminState)) {
            throw "Firewall remediation requires an elevated PowerShell session."
        }

        if (-not $Options.ContainsKey("yes")) {
            Write-Host ""
            Write-Host "REFUSING TO CHANGE SYSTEM STATE." -ForegroundColor Yellow
            Write-Host "This operation enables disabled Windows Firewall profiles."
            Write-Host ""
            Write-Host "Re-run explicitly with:"
            Write-Host "  aegis fix firewall --yes"
            Write-Host ""
            return
        }

        Write-AegisSection "FIREWALL REMEDIATION"

        $result = Invoke-AegisFirewallRemediation

        foreach ($item in @($result)) {
            $item | Format-List
        }

        return
    }

    Show-AegisHelp
}

function Invoke-AegisReportCommand {

    Write-AegisSection "AEGIS DIAGNOSTIC REPORT"

    $doctor = Invoke-AegisDoctor
    $path = New-AegisDiagnosticReport -DoctorResult $doctor

    Write-Host "Report generated:"
    Write-Host $path -ForegroundColor Green

    try {
        Save-AegisReport -Report @{
            id = [guid]::NewGuid().ToString()
            generated_at = (Get-Date).ToUniversalTime().ToString("o")
            type = "diagnostic"
            doctor = $doctor
        } | Out-Null
    }
    catch {
        Write-Host "[WARN] Report store persistence failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Invoke-AegisHistoryCommand {

    Write-AegisSection "AEGIS ACTIVITY HISTORY"

    $root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    $eventDir = Join-Path $root "data\events"

    if (-not (Test-Path $eventDir)) {
        Write-Host "No event history exists yet."
        return
    }

    $files = @(Get-ChildItem $eventDir -File -Filter "*.jsonl" |
        Sort-Object LastWriteTime -Descending)

    if ($files.Count -eq 0) {
        Write-Host "No event history exists yet."
        return
    }

    foreach ($file in $files | Select-Object -First 10) {
        Write-Host ""
        Write-Host "FILE: $($file.Name)" -ForegroundColor Cyan

        Get-Content $file |
            Select-Object -Last 20 |
            ForEach-Object {
                try {
                    $event = $_ | ConvertFrom-Json
                    Write-Host "[$($event.timestamp)] [$($event.severity)] $($event.title)"
                }
                catch {
                    Write-Host $_
                }
            }
    }
}

function Invoke-AegisCapabilitiesCommand {

    Write-AegisSection "IMPLEMENTED AEGIS CAPABILITIES"

    $functionNames = @(
        "Test-AegisHealth",
        "Invoke-AegisExposureScan",
        "Invoke-AegisVerification",
        "Invoke-AegisFirewallRemediation",
        "Get-AegisNetworkInterfaces",
        "Get-AegisNetworkIdentity",
        "Get-AegisNetworkIdentityFingerprint",
        "Test-AegisNetworkLeaks",
        "Invoke-AegisDoctor",
        "Get-AegisTreeFingerprint",
        "New-AegisDiagnosticReport",
        "Get-AegisVersionManifest",
        "New-AegisBackup",
        "Get-AegisBackups",
        "Invoke-AegisUpdateTransaction"
    )

    foreach ($name in $functionNames) {
        $exists = $null -ne (Get-Command $name -ErrorAction SilentlyContinue)

        if ($exists) {
            Write-Host "[IMPLEMENTED] $name" -ForegroundColor Green
        }
        else {
            Write-Host "[MISSING]     $name" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Explicitly unavailable CLI domains:"
    Write-Host "  location"
    Write-Host "  browser"
    Write-Host "  artifacts"
    Write-Host "  policy"
    Write-Host "  watch"
    Write-Host "  service"
}

function Invoke-AegisCommand {

    param(
        [Parameter(Mandatory)]
        [object]$ParsedCommand
    )

    $command = [string]$ParsedCommand.Command
    $subcommand = if ($null -eq $ParsedCommand.Subcommand) { "" } else { [string]$ParsedCommand.Subcommand }
    $options = $ParsedCommand.Options

    if ($options.ContainsKey("help")) {
        if ($command -eq "network") {
            Show-AegisHelp "network"
        }
        else {
            Show-AegisHelp
        }
        return
    }

    if ([string]::IsNullOrWhiteSpace($command)) {
        Show-AegisHelp
        return
    }

    switch ($command) {

        "help" {
            Show-AegisHelp $subcommand
        }

        "status" {
            Invoke-AegisStatus
        }

        "audit" {
            Invoke-AegisAuditCommand
        }

        "scan" {
            Invoke-AegisScanCommand
        }

        "verify" {
            Invoke-AegisVerifyCommand
        }

        "network" {
            Invoke-AegisNetworkCommand -Subcommand $subcommand
        }

        "doctor" {

            Write-AegisSection "AEGIS DOCTOR"

            $doctor = Invoke-AegisDoctor

            Write-Host "Healthy: $($doctor.Healthy)"
            Write-Host ""

            foreach ($check in @($doctor.Checks)) {
                $mark = if ($check.Passed) { "[PASS]" } else { "[FAIL]" }

                Write-Host "$mark $($check.Name)" `
                    -ForegroundColor $(if ($check.Passed) { "Green" } else { "Red" })

                Write-Host "  $($check.Detail)"
            }
        }

        "report" {
            Invoke-AegisReportCommand
        }

        "fingerprint" {

            Write-AegisSection "AEGIS REPOSITORY FINGERPRINT"

            $root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
            $fingerprint = Get-AegisTreeFingerprint -Root $root

            Write-Host "Root:"
            Write-Host $root
            Write-Host ""
            Write-Host "SHA-256:"
            Write-Host $fingerprint -ForegroundColor Green
        }

        "capabilities" {
            Invoke-AegisCapabilitiesCommand
        }

        "version" {

            Write-AegisSection "AEGIS VERSION"

            $manifest = Get-AegisVersionManifest
            $manifest | Format-List
        }

        "fix" {
            Invoke-AegisFixCommand `
                -Subcommand $subcommand `
                -Options $options
        }

        "lockdown" {

            Write-AegisSection "AEGIS LOCKDOWN"

            Write-Host "The currently implemented lockdown primitive is Windows Firewall remediation."
            Write-Host ""

            if (-not $options.ContainsKey("yes")) {
                Write-Host "No system changes were made."
                Write-Host ""
                Write-Host "To explicitly apply supported remediation:"
                Write-Host "  aegis lockdown --yes"
                return
            }

            Invoke-AegisFixCommand `
                -Subcommand "firewall" `
                -Options $options
        }

        "history" {
            Invoke-AegisHistoryCommand
        }

        "rollback" {

            Write-AegisSection "AEGIS RECOVERY BACKUPS"

            $backups = @(Get-AegisBackups)

            if ($backups.Count -eq 0) {
                Write-Host "No recovery backups found."
                return
            }

            foreach ($backup in $backups) {
                Write-Host $backup.FullName
            }

            Write-Host ""
            Write-Host "Rollback is deliberately explicit."
            Write-Host "No backup was restored."
        }

        "update" {

            Write-AegisSection "AEGIS UPDATE MANAGER"

            Write-Host "Installed version:"
            (Get-AegisVersionManifest | Format-List | Out-String).TrimEnd()

            Write-Host ""
            Write-Host "Remote release acquisition and authenticated release verification are not yet implemented."
            Write-Host "No update was attempted."
        }

        "test" {

            Write-AegisSection "AEGIS TESTS"

            $testRoot = Join-Path `
                (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path `
                "tests"

            $tests = @(Get-ChildItem `
                $testRoot `
                -Recurse `
                -File `
                -Filter "*.ps1" `
                -ErrorAction SilentlyContinue)

            if ($tests.Count -eq 0) {
                Write-Host "No test scripts found."
                return
            }

            foreach ($test in $tests) {
                Write-Host ""
                Write-Host "RUNNING: $($test.FullName)" -ForegroundColor Cyan
                & $test.FullName
            }
        }

        "location" {
            Write-AegisNotImplemented "Location command integration"
        }

        "browser" {
            Write-AegisNotImplemented "Browser command integration"
        }

        "artifacts" {
            Write-AegisNotImplemented "Artifact command integration"
        }

        "policy" {
            Write-AegisNotImplemented "Policy command integration"
        }

        "watch" {
            Write-AegisNotImplemented "Interactive watch/monitor command integration"
        }

        "service" {
            Write-AegisNotImplemented "Background Windows service/agent integration"
        }

        default {

            Write-Host ""
            Write-Host "Unknown AEGIS command: $command" -ForegroundColor Yellow
            Write-Host ""
            Show-AegisHelp
        }
    }
}
