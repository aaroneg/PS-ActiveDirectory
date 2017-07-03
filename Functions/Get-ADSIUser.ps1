function Get-AdsiUser {
<#
	.SYNOPSIS
		Get 1 result for a Username search
	.DESCRIPTION
		Uses ADSI to find a User in AD
	.PARAMETER ADUserName
		Specifies the exact Username you're looking for.
    .PARAMETER SearchBase
        The LDAP:// URL to use as the base for your search. Ex: LDAP://DC=MyCorp,DC=COM . It will be discovered if you do not specify, but the search will take longer.
	.EXAMPLE
		Get-AdsiUser -ADUserName "john.doe"
        
		Returns an object for the User in question
#>
    [CmdletBinding()]
    PARAM (
        [parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Enter a user SamAccountName to look up"
        )]
        [string]$ADUserName,
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
            $Searcher.Filter="(&(objectCategory=User)(samAccountName=$ADUsername))"
            $Searcher.SizeLimit=1
            $Searcher.SearchRoot=$SearchBase
            ($Searcher.FindOne()).Properties
        }
        catch {
            if ($ERRSEARCH) {Write-Warning "Problem with the search: "+$Error[0].Exception}
        }
    }
}
