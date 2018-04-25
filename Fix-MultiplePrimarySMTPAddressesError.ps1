[CmdletBinding()]
PARAM(
  [parameter(Mandatory=$true)][string]$Username
  [parameter($Mandatory=$true)[string]$DomainNameToRemove
)
$User=Get-ADUser $Username
Set-ADUser $User -Remove @{ProxyAddresses="SMTP:$($Username)@$($DomainNameToRemove)"} -Verbose
