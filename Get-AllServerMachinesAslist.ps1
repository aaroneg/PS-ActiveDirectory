cd $PSScriptRoot
Get-ADComputer -Filter {OperatingSystem -like '*Server*'} |Sort-Object|% { $_.Name|Out-File -Append -FilePath "$PSScriptRoot\ServerList.txt" }