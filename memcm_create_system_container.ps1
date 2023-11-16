[CmdletBinding()]
Param(
  [Parameter(Position=0)]
  [String]$computerName=$ENV:COMPUTERNAME,

  [Parameter(Position=1)]
  [Management.Automation.PSCredential]$sccmDomainCredential,

  [Parameter(Position=2)]
  [String]$sccmDomainController,

  [Parameter(Position=3)]
  [Management.Automation.PSCredential]$containerDomainCredential,

  [Parameter(Position=4)]
  [String]$containerDomainController
)

# Helper Function Definition
Function Get-LdapDirectoryEntry {
  [CmdletBinding()]
  Param(
    [Parameter(Position=0,Mandatory=$true)]
    [String]$Identity,

    [Parameter(Position=1)]
    [Management.Automation.PSCredential]$Credential,

    [Parameter(Position=2)]
    [String]$Server
  )
  Begin{
    $strBuilder=New-Object -TypeName Text.StringBuilder `
      -ArgumentList "LDAP://"
  }
  Process{
    Try{
      if($PSBoundParameters.ContainsKey('Server')){
        [void]$strBuilder.Append("$Server/")
      }

      if($Identity -match "(^(CN|DC|OU)=.+\,(CN|DC|OU)=.+)|rootDse"){
        [void]$strBuilder.Append($Identity)
      }else{
        Write-Error "Identity [$Identity] is not a valid format." `
          -ErrorAction Stop
      }
      $ctorArgs=@(
        $strBuilder.ToString()
      )

      Write-Verbose "Query $($strBuilder.ToString())"
      if($PSBoundParameters.ContainsKey('Credential')){
        $ctorArgs+=$Credential.Username
        $ctorArgs+=$($Credential.GetNetworkCredential().Password)
      }

      $entry=New-Object -TypeName DirectoryServices.DirectoryEntry `
        -ArgumentList $ctorArgs `
        -ErrorAction Stop
      if(!$entry.Path){
        Write-Error "Directory Entry [$Identity] not found." `
          -ErrorAction Stop
      }
      Write-Output $entry
    }Catch{
      Write-Error $_
    }
  }
  End{}
}

# END Helper Function Definition


Try{
  $computerParam=@{
    'ErrorAction'='Stop';
    'Identity'='rootDse';
  }
  if($PSBoundParameters.ContainsKey('sccmDomainCredential')){
    $computerParam.Add('Credential',$sccmDomainCredential)
  }
  if($PSBoundParameters.ContainsKey('sccmDomainController')){
    $computerParam.Add('Server',$sccmDomainController)
  }

  $rootDse=Get-LdapDirectoryEntry @computerParam

  $nameCtx=$rootDse.Properties['defaultNamingContext'].Value

  if(!$nameCtx){
    Write-Error "Error connecting to 'SCCM Computer' RootDse" `
      -ErrorAction Stop
  }
  $computerParam.Identity=$nameCtx
  $domainContainer=Get-LdapDirectoryEntry @computerParam

  # Get CM Computer in AD 

  $computerSearcher=New-Object -TypeName DirectoryServices.DirectorySearcher `
    -ArgumentList $domainContainer

  $computerSearcher.Filter="(&(objectCategory=computer)(cn=$computerName))"
  [void]$computerSearcher.PropertiesToLoad.Add('objectsid')
  $cmComputer=$computerSearcher.FindOne()
  if(!$cmComputer){
    Write-Error "Unable to find AD Computer: $computerName" `
      -ErrorAction Stop
  }
  Write-Verbose "SCCM Computer Found: $($cmComputer.Path)"

  # Get CM Computer SID

  [byte[]]$cmSidBytes=$cmComputer.Properties['objectsid'][0]
  $cmSid=New-Object -TypeName Security.Principal.SecurityIdentifier `
    -ArgumentList $cmSidBytes, 0
  $cmIdentityReference=$cmSid.Translate([Security.Principal.NTAccount])


  # Add System Management Container
  $containerParam=@{
    'Identity'='rootDse';
    'ErrorAction'='Stop';
  }
  if($PSBoundParameters.ContainsKey('containerDomainCredential')){
    $containerParam.Add('Credential',$containerDomainCredential)
  }
  if($PSBoundParameters.ContainsKey('containerDomainController')){
    $containerParam.Add('Server',$containerDomainController)
  }

  $containerRootDse=Get-LdapDirectoryEntry @containerParam
  $containerNameCtx=$containerRootDse.Properties['defaultNamingContext'].Value
  if(!$containerNameCtx){
    Write-Error "Error connecting to 'Container' RootDse" `
      -ErrorAction Stop
  }
  
  $containerParam.Identity=$containerNameCtx
  $containerDomainContainer=Get-LdapDirectoryEntry @containerParam


  $sysMgtName="CN=System Management"
  $systemDN="CN=System,$($containerDomainContainer.distinguishedName.Value)"

  $containerParam.Identity=$systemDN

  $systemEntry=Get-LdapDirectoryEntry @containerParam

  $searcher=New-Object -TypeName DirectoryServices.DirectorySearcher `
    -ArgumentList $systemEntry
  $searcher.SearchScope=1
  $searcher.Filter="(&(objectcategory=container)(cn=System Management))"
  $result=$searcher.FindOne()
  if(!$result){
    Write-Verbose "Adding $sysMgtName container"
    $sysMgtEntry=$systemEntry.Children.Add($sysMgtName,'Container')
    $sysMgtEntry.CommitChanges()
    $result=$searcher.FindOne()
    if(!$result){
      Write-Error "Unable to create System Management container" `
        -ErrorAction Stop
    }
  }else{
    $sysMgtEntry=$result.GetDirectoryEntry()
  }

  # Add AccessRights for CM Computer on System Management container

  $sysMgtDN=$sysMgtEntry.distinguishedName.Value
  Write-Verbose "Checking $sysMgtName permissions"
  $adRights=[DirectoryServices.ActiveDirectoryRights]::GenericAll
  $accessType=[Security.AccessControl.AccessControlType]::Allow
  $inheritance=[DirectoryServices.ActiveDirectorySecurityInheritance]::All

  $fullAccessACE=New-Object -TypeName DirectoryServices.ActiveDirectoryAccessRule `
    -ArgumentList @($cmSid, $adRights, $accessType, $inheritance)

  $sysMgtACE=$sysMgtEntry.ObjectSecurity.GetAccessRules(
    $true, 
    $true, 
    [Security.Principal.NTAccount]
  )

  $cmRightsExist=$sysMgtACE | 
    Where-Object {
      $_.IdentityReference.Value -eq $cmSid.Value -or
      $_.IdentityReference.Value -eq $cmIdentityReference.Value
    }
  if(!$cmRightsExist){
    Write-Verbose "Adding permissions $($cmIdentityReference.Value) to $sysMgtDN"
    $sysMgtEntry.ObjectSecurity.AddAccessRule($fullAccessACE)
    $sysMgtEntry.CommitChanges()
  }else{
    $warn=[String]::Format(
      "Computer: {0} permissions were already added to {1}",
      "$computerName",
      "System Management. Please Verify..."
    )
    Write-Warning $warn 
    Write-Output $cmRightsExist
  }
}Catch{
  Write-Error $_
}Finally{
  if($computerSearcher){
    $computerSearcher.Dispose()
  }
  if($searcher){
    $searcher.Dispose()
  }
}