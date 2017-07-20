# The name of the group whose members we need
$group="Group1"
# Read all members of the group
$members=Get-ADGroupMember $group
$members | Select-Object @{Name="Name";Expression={$_.SamAccountName}} | Export-Csv -NoTypeInformation -Append -Path "$PSScriptRoot\$($Group)Members.csv"
