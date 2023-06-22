# This PowerShell script is getting the current domain information, splitting the domain name into its
# components, generating an acronym using the first letter of each component and adding a 'P' at the
# end, and then printing the acronym along with the full domain name.

# Get the domain information
$DomainInfo = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).Name

# Split the domain name 
$SplitDomain = $DomainInfo.Split('.')

# Generate the acronym
$Acronym = $SplitDomain[0].Substring(0,1).ToUpper() + $SplitDomain[1].Substring(0,1).ToUpper() + 'P'

# Print the acronym
Write-Output "$Acronym for $DomainInfo"