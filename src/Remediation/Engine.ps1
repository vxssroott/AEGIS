function Invoke-AegisFirewallRemediation {
    [CmdletBinding(SupportsShouldProcess)]param()
    if(-not([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Firewall remediation requires an elevated PowerShell session.'}
    Get-NetFirewallProfile -ErrorAction Stop | ? Enabled -eq $false | % { if($PSCmdlet.ShouldProcess($_.Name,'Enable Windows Firewall')){Set-NetFirewallProfile -Name $_.Name -Enabled True}}
    Invoke-AegisVerification
}
