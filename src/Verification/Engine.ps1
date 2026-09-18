function Test-AegisFirewall {
    $p=@(Get-NetFirewallProfile -ErrorAction SilentlyContinue)
    [pscustomobject]@{Check='Firewall';Passed=([bool]$p -and -not @($p|? Enabled -eq $false));Status=$(if(-not $p){'Unknown'}elseif(@($p|? Enabled -eq $false)){'Attention'}else{'Protected'});Evidence=$(if(-not $p){'Unable to query firewall'}else{"$(@($p|? Enabled).Count) enabled profile(s)"})}
}
function Test-AegisNetwork {
    $n=@(Get-NetAdapter -ErrorAction SilentlyContinue|? Status -eq 'Up')
    [pscustomobject]@{Check='Network';Passed=([bool]$n);Status=$(if($n){'Operational'}else{'Attention'});Evidence="$($n.Count) active interface(s)"}
}
function Test-AegisDns {
    $d=@(Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue|% ServerAddresses|? {$_})
    [pscustomobject]@{Check='DNS';Passed=([bool]$d);Status=$(if($d){'Configured'}else{'Attention'});Evidence="$($d.Count) resolver address(es)"}
}
function Invoke-AegisVerification { @(Test-AegisFirewall;Test-AegisNetwork;Test-AegisDns) }
