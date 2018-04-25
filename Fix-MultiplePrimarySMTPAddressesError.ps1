<#
    .SYNOPSIS
        Removes "username@libr.net" SMTP address, which makes the account valid for use with exchange
    .EXAMPLE
        Fix-MultiplePrimarySMTPAddresses.ps1 -Username jdoe -domain "contoso.com"
#>

[CmdletBinding()]
PARAM(
  [parameter(Mandatory=$true)][string]$Username
  [parameter($Mandatory=$true)[string]$DomainNameToRemove
)
<#
This fixes an issue where exchange complains that an object is corrupt because there are multiple primary smtp addresses
#>
$User=Get-ADUser $Username
Set-ADUser $User -Remove @{ProxyAddresses="SMTP:$($Username)@$($DomainNameToRemove)"} -Verbose
