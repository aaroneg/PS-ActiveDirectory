## User Config ##
# Uncomment the following lines to run in batch mode. Otherwise the script will be interactive.
# $UserFileName="$PSScriptRoot\Add-UsersFromSpreadsheetToGroup.csv"
# $ColumnName=SamAccountName
# $TargetADGroupName=MyGroupName
$Logfile="$PSScriptRoot\Add-UsersFromSpreadsheetToGroup.log"
$ErrorCSVFile="$PSScriptRoot\Add-UsersFromSpreadsheetToGroup.err.csv"

## End of User Config ##

Remove-Variable ColumnName,Users,TargetADGroup,ValidUsers,InvalidUsers -ErrorAction SilentlyContinue
$ValidUsers=@()
$InvalidUsers=@()

If (!(Test-Path $Logfile)) { New-Item $Logfile -Force }

#region Functions
Function Get-FileName($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "CSV (*.csv)| *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

function Get-ColumnName ($InputUsers) {
    Write-Host "This is the first row of your spreadsheet. Please type the column name that contains the user name."
    $InputUsers[0]|Format-Table|Out-Host
    $Column=Read-Host -Prompt "Column"
    return $Column
}
#endregion
"Beginning run:"+(get-date)|Out-File $logFile -Append
if (!$UserFileName) {
    $UserFileName=Get-FileName
}
try {$Users=Import-Csv -Path $UserFileName} catch {"Could not import userlist: "+$_.Exception.Message}
if (!$ColumnName) {$ColumnName=Get-ColumnName($Users)}
if (!$TargetADGroupName) { $TargetADGroupName=Read-Host -Prompt "Target Active Directory group name (or press Control+C to terminate)"}
try { $TargetADGroup=Get-ADGroup -Identity $TargetADGroupName}
catch {
    "$(Get-Date);ERROR;Could not find AD Group;+$TargetADGroupName"| out-file $logFile -Append
    throw "Group Not Found."
}

foreach ($User in $Users) {
    $textUserName=$User.$ColumnName
    try {
        $ADUser=Get-ADuser $textUserName
        $ValidUsers+=$ADUser
        "$(Get-Date);INFO;Located User;$($User.$ColumnName)"| out-file $logFile -Append
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        "$(Get-Date);ERROR;$ErrorMessage;+$($User.$ColumnName)"| out-file $logFile -Append
        $InvalidUsers +=[System.Management.Automation.PSCustomObject]@{UserName=$textUserName; ErrorMessage=$ErrorMessage}
    }
}

Add-ADGroupMember -Identity $TargetADGroup -Members $ValidUsers
$InvalidUsers| Export-csv -Path $ErrorCSVFile -NoTypeInformation
