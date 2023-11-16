param(
    [string]$DomainName = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).Name, # domain name
    [string]$computerName=$ENV:COMPUTERNAME, # Domain computer to check
    [string[]]$TargetComputers = @("CM02", "CM03") # Target systems

)

# Get Domain information
$rootDse=New-Object -TypeName DirectoryServices.DirectoryEntry `
  -ArgumentList 'LDAP://rootDse'
$rootName=$rootDse.Properties['defaultNamingContext'].Value

# Function to add a computer to the Administrators group if it's not already a member
function Add-ToAdminGroup {
    param (
        [string]$computerName,
        [string]$primarySite,
        [string]$domain
    )

    $scriptBlock = {
        param($primarySite, $domain)

        $adminGroup = [ADSI]("WinNT://./Administrators,group")
        $computerAccount = [ADSI]("WinNT://$domain/$primarySite$,computer")

        try {
            if ($adminGroup.IsMember($computerAccount.Path) -eq $false) {
                Write-Host "$primarySite is not an administrator on this computer. Adding..."
                $adminGroup.Add($computerAccount.Path)
                Write-Host "$primarySite added to the Administrators group on this computer."
            } else {
                Write-Host "$primarySite is already an administrator on this computer."
            }
        } catch {
            Write-Warning "Failed to add $primarySite to the Administrators group: $_"
        }
    }

    Invoke-Command -ComputerName $computerName -ScriptBlock $scriptBlock -ArgumentList $primarySite, $domain
}

# Main script logic
foreach ($targetComputer in $TargetComputers) {
    try {
        Add-ToAdminGroup -computerName $targetComputer -primarySite $PrimarySiteComputer -domain $DomainName
    } catch {
        Write-Warning "Failed to process ${targetComputer}: $_"
    }
}
