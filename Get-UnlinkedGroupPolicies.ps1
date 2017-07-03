Function Remove-InvalidFileNameChars {
    [CmdletBinding()] 
     Param( 
        [Parameter( 
            Mandatory=$true, 
            Position=0,  
            ValueFromPipelineByPropertyName=$true 
        )] 
        [String]$Name, 
        [switch]$IncludeSpace 
    ) 
 
    if ($IncludeSpace) { 
        [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '') 
    } 
    else { 
        [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape(-join [System.IO.Path]::GetInvalidFileNameChars())), '') 
    }

}

function Get-UnlinkedGPObjects {
    [CmdletBinding()]
    $ClosestServer=(Get-ADDomainController -DomainName ($env:currentdomain) -Discover -NextClosestSite).Hostname[0]
    Write-Verbose ("Closest server is:"+$ClosestServer)
    $GPOs=Get-GPO -All -Server $ClosestServer | Sort-Object displayname
    $UnlinkedPolicyObjects=@()
    foreach ($Policy in $GPOs) {
        $rpt=($Policy|Get-GPOReport -ReportType Xml -Server $ClosestServer)
        if ($rpt|Select-String -NotMatch "LinksTo"){
            Write-Verbose ($Policy.DisplayName+" appears to have no links")
            $UnlinkedPolicyObjects+=$Policy
        }
    }
    return $UnlinkedPolicyObjects
}

Write-Host "This script will take some time to finish. Please be patient." -ForegroundColor Yellow

if (!$GPObjectList) { 
    Write-Verbose "Reading GPOs"
    $GPObjectList=Get-UnlinkedGPObjects -verbose
}

$GPObjectList|Export-Csv -Path $PSScriptRoot\Unlinked-GPO.csv -Force -NoTypeInformation
$GPObjectList|Select DisplayName