Set-StrictMode -Version Latest

$script:AegisVoiceAvailable = $false
$script:AegisVoiceSynth = $null

try {
    Add-Type -AssemblyName System.Speech -ErrorAction Stop
    $script:AegisVoiceSynth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $script:AegisVoiceAvailable = $true
}
catch {
    $script:AegisVoiceAvailable = $false
}

function Get-AegisVoiceAvailability {
    [pscustomobject]@{
        Available = $script:AegisVoiceAvailable
        Provider  = if ($script:AegisVoiceAvailable) { 'System.Speech' } else { 'Unavailable' }
    }
}

function Invoke-AegisVoiceEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Event
    )

    if (-not $script:AegisVoiceAvailable) {
        return $false
    }

    $severity = [string]$Event.Severity

    if ($severity -eq 'info' -and
        [string]$Event.Type -notin @(
            'transport.active',
            'transport.rotated',
            'transport.recovered'
        )) {
        return $false
    }

    $text = "AEGIS: $([string]$Event.Message)"

    try {
        $script:AegisVoiceSynth.SpeakAsync($text) | Out-Null
        return $true
    }
    catch {
        return $false
    }
}
