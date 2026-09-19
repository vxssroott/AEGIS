Set-StrictMode -Version Latest

function Invoke-AegisCommandBus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$ParsedCommand
    )

    return Invoke-AegisCommand -ParsedCommand $ParsedCommand
}
