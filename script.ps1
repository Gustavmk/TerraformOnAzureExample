$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file -DisableBasicAuth -EnableCredSSP


$RuleList = @(
    [pscustomobject]@{DisplayName='Windows Remote Management (HTTP-In)'; Direction='Inbound'; LocalPort='5985'; Protocol='TCP'; Action='Allow'; Program='System'}
    [pscustomobject]@{DisplayName='Windows Remote Management (HTTPS-In)'; Direction='Inbound'; LocalPort='5986'; Protocol='TCP'; Action='Allow'; Program='System'}
    [pscustomobject]@{DisplayName='WEB - HTTPS'; Direction='Inbound'; LocalPort='443'; Protocol='TCP'; Action='Allow'; Program='System'}
    [pscustomobject]@{DisplayName='WEB - HTTP - CUSTOM 8080'; Direction='Inbound'; LocalPort='8080'; Protocol='TCP'; Action='Allow'; Program='System'}
    [pscustomobject]@{DisplayName='DOCKER - MGMT- SSL'; Direction='Inbound'; LocalPort='2376'; Protocol='TCP'; Action='Allow'; Program='System'}
    #[pscustomobject]@{DisplayName=''; Direction=''; LocalPort=''; Protocol=''; Action=''; Program=''}
)

Foreach ($rule in $RuleList) {
    $FirewallParam = @{
        DisplayName     = $Rule.DisplayName
        Direction       = $Rule.Direction
        LocalPort       = $Rule.LocalPort
        Protocol        = $Rule.Protocol
        Action          = $Rule.Action
        Program         = $Rule.Program
    }

    New-NetFirewallRule @FirewallParam
}

#$FirewallParam = @{
#    DisplayName = 'Windows Remote Management (HTTP-In)'
#    Direction = 'Inbound'
#    LocalPort = 5985
#    Protocol = 'TCP'
#    Action = 'Allow'
#    Program = 'System'
#}
#
#New-NetFirewallRule @FirewallParam

