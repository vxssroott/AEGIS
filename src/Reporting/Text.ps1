function ConvertTo-AegisTextReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$Report
    )

    @"
AEGIS OPERATIONAL REPORT
========================

Report ID  : $($Report.id)
Generated  : $($Report.generated_at)
Trigger    : $($Report.trigger)
Host       : $($Report.host)
User       : $($Report.user)
PowerShell : $($Report.powershell)
Events     : $($Report.event_count)

Connectivity
------------
$($Report.connectivity | Out-String)
"@
}
