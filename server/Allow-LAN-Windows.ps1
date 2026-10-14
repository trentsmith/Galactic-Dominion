# Optional first-time setup. Run in an Administrator PowerShell window.
# Rules only accept traffic from your local subnet on Private networks.
$ErrorActionPreference = 'Stop'
$rules = @(
    @{ Name = 'Galactic Dominion LAN accounts'; Protocol = 'TCP'; Port = 8080 },
    @{ Name = 'Galactic Dominion LAN combat'; Protocol = 'UDP'; Port = 7777 }
)
foreach ($rule in $rules) {
    if (-not (Get-NetFirewallRule -DisplayName $rule.Name -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $rule.Name -Direction Inbound -Action Allow -Protocol $rule.Protocol -LocalPort $rule.Port -Profile Private -RemoteAddress LocalSubnet | Out-Null
    }
}
Write-Host 'Galactic Dominion is allowed for friends on your local network.'
