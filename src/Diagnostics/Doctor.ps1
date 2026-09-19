Set-StrictMode -Version Latest

function Invoke-AegisDoctor {
    $root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

    $checks = @()

    $health = Test-AegisHealth

    $checks += [pscustomobject]@{
        Name = "Core health"
        Passed = [bool]$health.Healthy
        Detail = "Required AEGIS components"
    }

    try {
        $fingerprint = Get-AegisTreeFingerprint -Root $root

        $checks += [pscustomobject]@{
            Name = "Integrity fingerprint"
            Passed = ($fingerprint.Length -eq 64)
            Detail = $fingerprint
        }
    }
    catch {
        $checks += [pscustomobject]@{
            Name = "Integrity fingerprint"
            Passed = $false
            Detail = $_.Exception.Message
        }
    }

    try {
        $git = Get-Command git -ErrorAction SilentlyContinue

        $checks += [pscustomobject]@{
            Name = "Git availability"
            Passed = ($null -ne $git)
            Detail = if ($null -ne $git) { $git.Source } else { "Git unavailable" }
        }
    }
    catch {
        $checks += [pscustomobject]@{
            Name = "Git availability"
            Passed = $false
            Detail = $_.Exception.Message
        }
    }

    $failed = @($checks | Where-Object { -not $_.Passed })

    return [pscustomobject]@{
        Healthy = ($failed.Count -eq 0)
        Timestamp = (Get-Date).ToUniversalTime().ToString("o")
        Checks = $checks
        Failed = $failed
    }
}
