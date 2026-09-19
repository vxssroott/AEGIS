function Get-AegisOperationalDigest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$Report
    )

    [pscustomobject]@{
        report_id    = $Report.id
        generated    = $Report.generated_at
        trigger      = $Report.trigger
        event_count  = $Report.event_count
        connectivity = if ($Report.connectivity) {
            [bool]$Report.connectivity.Online
        }
        else {
            $null
        }
    }
}
