function Get-AdsiComputer {
<#
	.SYNOPSIS
		Get 1 result for a computername search
	.DESCRIPTION
		Uses ADSI to find a computer in AD
	.PARAMETER ADComputerName
		Specifies the exact computername you're looking for.
    .PARAMETER SearchBase
        The LDAP:// URL to use as the base for your search. Ex: LDAP://DC=MyCorp,DC=COM . It will be discovered if you do not specify, but the search will take longer.
	.EXAMPLE
		Get-AdsiComputer -ADComputerName "Server1"
        
		Returns an object for the computer in question
#>
    [CmdletBinding()]
    PARAM (
        [Parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipelineByPropertyName=$true,
	    HelpMessage="Enter a computer name to look up"
        )]
        [String]$ADComputerName,
        [parameter(
            Mandatory=$false,
            Position=1,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage='Search Base'
        )]
        [string]$SearchBase
    )
    PROCESS{
        if (!$SearchBase) {
            $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
            $SearchBase= "LDAP://"+($Domain.GetDirectoryEntry()).DistinguishedName[0]
        }
        try {
            $Searcher=New-Object -TypeName System.DirectoryServices.DirectorySearcher -ErrorAction Stop -ErrorVariable ERRSEARCH
            $Searcher.Filter="(&(objectCategory=Computer)(name=$ADComputername))"
            $Searcher.SizeLimit=1
            $Searcher.SearchRoot=$SearchBase
            ($Searcher.FindOne()).Properties
        }
        catch {
            if ($ERRSEARCH) {Write-Warning "Problem with the search: "+$Error[0].Exception}
        }
    }
} 
