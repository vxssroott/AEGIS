function ConvertTo-AegisJsonReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$Report
    )

    return ($Report | ConvertTo-Json -Depth 30)
}
