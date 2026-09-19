Set-StrictMode -Version Latest

function Parse-AegisArguments {
    [CmdletBinding()]
    param(
        [string[]]$Arguments = @()
    )

    $tokens = @($Arguments)

    $command = $null
    $subcommand = $null
    $positionals = @()
    $options = @{}

    foreach ($token in $tokens) {

        if ([string]::IsNullOrWhiteSpace($token)) {
            continue
        }

        if ($token -like '--*=*') {
            $parts = $token.Substring(2).Split('=', 2)
            $options[$parts[0].ToLowerInvariant()] = $parts[1]
            continue
        }

        if ($token.StartsWith('--')) {
            $key = $token.Substring(2).ToLowerInvariant()
            $options[$key] = $true
            continue
        }

        if ($token.StartsWith('-') -and $token.Length -gt 1) {
            $key = $token.Substring(1).ToLowerInvariant()
            $options[$key] = $true
            continue
        }

        if ($null -eq $command) {
            $command = $token.ToLowerInvariant()
            continue
        }

        if ($null -eq $subcommand) {
            $subcommand = $token.ToLowerInvariant()
            continue
        }

        $positionals += $token
    }

    [pscustomobject]@{
        Command    = $command
        Subcommand = $subcommand
        Positionals = @($positionals)
        Options    = $options
        Raw        = @($tokens)
    }
}
