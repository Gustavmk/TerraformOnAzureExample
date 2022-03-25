$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file -DisableBasicAuth -EnableCredSSP


$RuleList = @()

$FirewallParam = @{
    DisplayName = 'Windows Remote Management (HTTP-In)'
    Direction = 'Inbound'
    LocalPort = 5985
    Protocol = 'TCP'
    Action = 'Allow'
    Program = 'System'
}
New-NetFirewallRule @FirewallParam

$FirewallParam = @{
    DisplayName = 'Windows Remote Management (HTTPS-In)'
    Direction = 'Inbound'
    LocalPort = 5986
    Protocol = 'TCP'
    Action = 'Allow'
    Program = 'System'
}
New-NetFirewallRule @FirewallParam

$FirewallParam = @{
    DisplayName = 'HTTPS'
    Direction = 'Inbound'
    LocalPort = 443
    Protocol = 'TCP'
    Action = 'Allow'
    Program = 'System'
}
New-NetFirewallRule @FirewallParam

$FirewallParam = @{
    DisplayName = 'HTTP'
    Direction = 'Inbound'
    LocalPort = 8080
    Protocol = 'TCP'
    Action = 'Allow'
    Program = 'System'
}
New-NetFirewallRule @FirewallParam

$FirewallParam = @{
    DisplayName = 'Docker SSL Inbound'
    Direction = 'Inbound'
    LocalPort = 2376
    Protocol = 'TCP'
    Action = 'Allow'
    Program = 'System'
}
New-NetFirewallRule @FirewallParam

