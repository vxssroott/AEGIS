. "$PSScriptRoot/../Core/State.ps1"
function Get-AegisNetworkExposure {
    Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up' | ForEach-Object {
        New-AegisObservation 'Network' 'Interface' $_.Name 'Up' 'Active network interface' 'info' "Interface=$($_.Name);Description=$($_.InterfaceDescription)"
    }
    Get-NetConnectionProfile -ErrorAction SilentlyContinue | ForEach-Object {
        $sev=if($_.NetworkCategory -eq 'Public'){'low'}else{'info'}
        New-AegisObservation 'Network' 'NetworkProfile' $_.Name ([string]$_.NetworkCategory) 'Windows network profile' $sev "Interface=$($_.InterfaceAlias);Category=$($_.NetworkCategory)"
    }
}
function Get-AegisDnsExposure {
    Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | ForEach-Object {
        $i=$_
        $_.ServerAddresses | ForEach-Object {
            New-AegisObservation 'DNS' 'Resolver' $i.InterfaceAlias $_ 'Configured DNS resolver' 'info' "Interface=$($i.InterfaceAlias);Server=$_"
        }
    }
}
function Get-AegisFirewallExposure {
    Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
        $enabled=[bool]$_.Enabled
        New-AegisObservation 'Firewall' 'Profile' $_.Name ($(if($enabled){'Enabled'}else{'Disabled'})) 'Windows Firewall profile' ($(if($enabled){'info'}else{'high'})) "Profile=$($_.Name);Enabled=$enabled" $true
    }
}
function Get-AegisLocationExposure {
    $key='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'
    if(Test-Path $key){
        $v=(Get-ItemProperty $key -ErrorAction SilentlyContinue).Value
        New-AegisObservation 'Location' 'OSPermission' 'Windows Location' ([string]$v) 'Windows location capability state' ($(if($v -eq 'Deny'){'info'}else{'medium'})) "Registry=$key" $true
    }
}
function Invoke-AegisExposureScan {
    @(Get-AegisNetworkExposure;Get-AegisDnsExposure;Get-AegisFirewallExposure;Get-AegisLocationExposure)
}
