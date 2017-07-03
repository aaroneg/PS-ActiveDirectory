function Get-ADSIKnownDomains{
    $LDAPFilter="(objectClass=trustedDomain)"
    $Searcher=New-Object -TypeName System.DirectoryServices.DirectorySearcher -ErrorAction Stop -ErrorVariable ERRSEARCH
    $Searcher.Filter=$LDAPFilter
    $Searcher.SearchRoot=$LDAPRoot
    if ($ERRSEARCH) {throw $ERRSEARCH}
    $trusts=($Searcher.FindAll()).Properties
    $returnTrusts=@()

    $localExplodeDomain=@($env:USERDNSDOMAIN.Split('.'))
    $localShortName=$env:USERDOMAIN
    $localDNSName=$env:USERDNSDOMAIN
    $localSearchRoot="LDAP://dc="+[string]::Join(',dc=',$localExplodeDomain)
    $localTmpObj = New-Object -TypeName PSObject
        $localTmpObj| Add-Member -MemberType NoteProperty -Name ShortName -Value $localShortName
        $localTmpObj| Add-Member -MemberType NoteProperty -Name DNSName -Value $localDNSName
        $localTmpObj| Add-Member -MemberType NoteProperty -Name SearchRoot -Value $localSearchRoot
        $returnTrusts+=$localTmpObj
    $trusts | ForEach-Object {
        $explodeDomain=@($_.name.split('.'))
        $searchRoot="LDAP://dc="+[string]::Join(',dc=',$explodeDomain)
        $tmpObj = New-Object -TypeName PSObject 
        $tmpObj | Add-Member -MemberType NoteProperty -Name ShortName -Value $_.flatname[0]
        $tmpObj | Add-Member -MemberType NoteProperty -Name DNSName -Value $_.name[0]
        $tmpObj | Add-Member -MemberType NoteProperty -Name SearchRoot -Value $searchRoot
        $returnTrusts+=$tmpObj
    }
    return $returnTrusts
}