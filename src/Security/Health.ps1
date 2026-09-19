Set-StrictMode -Version Latest

function Test-AegisHealth {
    $root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    $checks = @()

    $required = @(
        "aegis.ps1",
        "install.ps1",
        "src",
        "config",
        "tests"
    )

    foreach ($item in $required) {
        $path = Join-Path $root $item

        $checks += [pscustomobject]@{
            Check = "Required:$item"
            Passed = Test-Path $path
            Detail = $path
        }
    }

    $criticalModules = @(
        "src\Core",
        "src\Exposure",
        "src\Remediation",
        "src\Verification",
        "src\Network"
    )

    foreach ($module in $criticalModules) {
        $path = Join-Path $root $module

        $checks += [pscustomobject]@{
            Check = "Module:$module"
            Passed = Test-Path $path
            Detail = $path
        }
    }

    $failed = @($checks | Where-Object { -not $_.Passed })

    return [pscustomobject]@{
        Healthy = ($failed.Count -eq 0)
        Timestamp = (Get-Date).ToUniversalTime().ToString("o")
        Checks = $checks
        FailedChecks = $failed
    }
}
