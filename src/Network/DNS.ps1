Set-StrictMode -Version Latest

function Test-AegisDnsConfiguration {
    [CmdletBinding()]
    param()

    $servers = @()
    $issues = @()

    try {
        $configs = @(Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop)

        foreach ($config in $configs) {
            if ($null -eq $config) {
                continue
            }

            $serverProperty = $config.PSObject.Properties["ServerAddresses"]

            if ($null -eq $serverProperty) {
                continue
            }

            foreach ($server in @($serverProperty.Value)) {
                if ($null -eq $server) {
                    continue
                }

                $text = [string]$server

                if ([string]::IsNullOrWhiteSpace($text)) {
                    continue
                }

                $servers += $text
            }
        }
    }
    catch {
        $issues += [pscustomobject]@{
            Type     = "DNS_ENUMERATION"
            Severity = "High"
            Detail   = $_.Exception.Message
        }
    }

    $servers = @($servers | Sort-Object -Unique)

    foreach ($server in $servers) {
        $parsed = $null

        if (-not [System.Net.IPAddress]::TryParse($server, [ref]$parsed)) {
            $issues += [pscustomobject]@{
                Type     = "DNS_ENDPOINT"
                Severity = "High"
                Detail   = "Invalid DNS endpoint detected: $server"
            }
        }
    }

    $healthy = ($issues.Count -eq 0)

    return [pscustomobject]@{
        Timestamp = (Get-Date).ToUniversalTime().ToString("o")
        Healthy   = $healthy
        Servers   = @($servers)
        Issues    = @($issues)
    }
}
