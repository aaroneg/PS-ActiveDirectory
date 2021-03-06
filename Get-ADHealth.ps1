<#
    .NOTES
    Author: Aaron Glenn, @danielewood
    Q: What does this do?
    A: It attempts to validate your AD health to the best of the author's ability

    Q: What format does it output?
    A: Markdown

    Q: Why Markdown?
    A: It's dead simple and I like it

    Q: I don't have any use for markdown. Can I easily adapt this to some other format?
    A: Sigh. Fine. https://social.technet.microsoft.com/wiki/contents/articles/30591.convert-markdown-to-html-using-powershell.aspx
    A: https://pandoc.org/getting-started.html

#>
if (!$PSScriptRoot){$PSScriptRoot=$PWD}
$Report=@()
Clear-Host
$ADForest = [system.directoryservices.activedirectory.Forest]::GetCurrentForest()
Write-Host "Reading forest config"
$Report+="# Forest"
$Report+="* Forest Name:                $($ADForest.Name)"
$Report+="`n## Forest Role Owners"
$Report+="* Forest Schema Role Owner:   $($ADForest.SchemaRoleOwner)"
$Report+="* Forest Naming Role Owner:   $($ADForest.NamingRoleOwner)"
$SchemaRoleOwnerContactable=Test-Connection($ADForest.SchemaRoleOwner) -Count 1 -Quiet
$NamingRoleOwnerContactable=Test-Connection($ADForest.NamingRoleOwner) -Count 1 -Quiet
$Report+="`n## Role Owner Online"
$Report+="* Schema Role Owner Contactable: **$SchemaRoleOwnerContactable**"
$Report+="* Naming Role Owner Contactable: **$NamingRoleOwnerContactable**"
Write-Host "Getting Domains in Forest"
$Report+="`n## Forest Domains"
foreach ($ForestDomain in $ADForest.Domains) {
    $Report+="* $($ForestDomain.Name)"
}
Write-Host "Getting Domain info for Current Domain"
$ADDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$Report+="`n# Current Domain"
$Report+="* Domain Name:                    $($ADDomain.Name)"
$Report+="`n## Domain Role Owners"
$Report+="* Domain PDC Emulator Owner:      $($Addomain.PdcRoleOwner)"
$Report+="* Domain Rid Role Owner:          $($Addomain.RidRoleOwner)"
$Report+="* Domain Infrastructure Owner:    $($Addomain.InfrastructureRoleOwner)"
$PDCContactable=Test-Connection($ADDomain.PdcRoleOwner) -Count 1 -Quiet
$RIDContactable=Test-Connection($ADDomain.RidRoleOwner) -Count 1 -Quiet
$InfraContactable=Test-Connection($ADDomain.InfrastructureRoleOwner) -Count 1 -Quiet
$Report+="`n## Domain Role Owner Online"
$Report+="* PDC contactable : **$PDCContactable**"
$Report+="* RID contactable : **$RIDContactable**"
$Report+="* INF contactable : **$InfraContactable**"
$Report+="`n## Domain Controllers"
$ADControllers=(Get-ADDomain).ReplicaDirectoryServers
Write-Host "Checking domain controllers & service status"

$i=0
Foreach ($ADController in $ADControllers) {
    Write-Progress -Activity "Pinging AD controllers" -Status $ADController -PercentComplete ($i/$ADControllers.Count)
    if(Test-Connection $ADController -Count 1 -Quiet){$Status="**Online**"}else{$Status="**Offline**"}
    $Report+="* "+$ADController+" : "+$Status
    $i++
}

$i=0
$Report+="`n## NetLogon Services"
Foreach ($ADController in $ADControllers) {
    Write-Progress -Activity "Checking NetLogon Service" -Status $ADController -PercentComplete ($i/$ADControllers.Count)
    $Status=(Get-Service -ComputerName $ADController -Name Netlogon -ErrorAction SilentlyContinue).Status 
    $Report+="* "+$ADController+" : **"+$Status+"**"
    $i++
}

$i=0
$Report+="`n## NTDS Services"
Foreach ($ADController in $ADControllers) {
    Write-Progress -Activity "Checking NTDS Service" -Status $ADController -PercentComplete ($i/$ADControllers.Count)
    $Status=(Get-Service -ComputerName $ADController -Name NTDS -ErrorAction SilentlyContinue).Status 
    $Report+="* "+$ADController+" : **"+$Status+"**"
    $i++
}

$i=0
$Report+="`n## DNS Services"
Foreach ($ADController in $ADControllers) {
    Write-Progress -Activity "Checking DNS Service" -Status $ADController -PercentComplete ($i/$ADControllers.Count)
    $Status=(Get-Service -ComputerName $ADController -Name DNS -ErrorAction SilentlyContinue).Status 
    $Report+="* "+$ADController+" : **"+$Status+"**"
    $i++
}

$i=0
$Report+="`n## KDC Services"
Foreach ($ADController in $ADControllers) {
    Write-Progress -Activity "Checking KDC Service" -Status $ADController -PercentComplete ($i/$ADControllers.Count)
    $Status=(Get-Service -ComputerName $ADController -Name KDC -ErrorAction SilentlyContinue).Status 
    $Report+="* "+$ADController+" : **"+$Status+"**"
    $i++
}

$i=0
$Report+="`n## ADWS Services"
Foreach ($ADController in $ADControllers) {
    Write-Progress -Activity "Checking ADWS Service" -Status $ADController -PercentComplete ($i/$ADControllers.Count)
    $Status=(Get-Service -ComputerName $ADController -Name ADWS -ErrorAction SilentlyContinue).Status 
    $Report+="* "+$ADController+" : **"+$Status+"**"
    $i++
}

$i=0
$Report+="`n## Secure Channel to Domain Controllers"
Foreach ($ADController in $ADControllers) {
    Write-Progress -Activity "Testing Secure Channel to Domain Controllers" -Status $ADController -PercentComplete ($i/$ADControllers.Count)
    $Status=Test-ComputerSecureChannel -Server $ADController
    $Report+="* "+$ADController+" : **"+$Status+"**"
    $i++
}

$ReplFailures = (Get-ADReplicationFailure -Scope Domain -ErrorAction SilentlyContinue | where FailureCount -gt 0)
$Report+="`n ## Current Replication failures across the domain"
Foreach ($ReplFailure in $ReplFailures) {
    $Report+="* "+$($ReplFailure.Server)+" : **"+$($ReplFailure.FailureType)+"** : **"+$($ReplFailure.FailureCount)+"**"
    Write-Output "ReplFailure: $($ReplFailure.Server) : **$($ReplFailure.FailureType)** : **$($ReplFailure.FailureCount)**"
}

$Report+="* Replication failures:" + $(($ReplFailures.FailureCount | Measure-Object -Sum ).Sum)


$Report|Set-Clipboard
$Report|Out-File $PSScriptRoot\ADHealth.md -Encoding utf8
