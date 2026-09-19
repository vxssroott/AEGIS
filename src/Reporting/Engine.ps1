function New-AegisOperationalReport {
    [CmdletBinding()]
    param(
        [string]$Trigger = "manual",
        [object]$Connectivity = $null,
        [object[]]$Events = @()
    )

    [pscustomobject][ordered]@{
        id           = [guid]::NewGuid().ToString()
        generated_at = (Get-Date).ToUniversalTime().ToString("o")
        trigger      = $Trigger
        host         = $env:COMPUTERNAME
        user         = $env:USERNAME
        powershell   = $PSVersionTable.PSVersion.ToString()
        connectivity = $Connectivity
        event_count  = @($Events).Count
        events       = @($Events)
    }
}
