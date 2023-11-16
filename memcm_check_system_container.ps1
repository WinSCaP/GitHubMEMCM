# Connect to the RootDSE to get the default naming context
$rootDse = New-Object -TypeName DirectoryServices.DirectoryEntry "LDAP://rootDse"
$rootName = $rootDse.Properties['defaultNamingContext'].Value

# Define the path to the CN=System container
$systemPath = "CN=System,$rootName"

# Define the path to the 'System Management' container
$systemMgtPath = "CN=System Management,$systemPath"

# Create a DirectorySearcher to search for the 'System Management' container
$searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]"LDAP://$systemPath")
$searcher.Filter = "(distinguishedName=$systemMgtPath)"

# Perform the search
try {
    $results = $searcher.FindOne()

    if ($results -ne $null) {
        Write-Host "The 'System Management' container already exists."
        # Output the details of the container
        $results.Properties
    } else {
        Write-Host "The 'System Management' container does not exist."
    }
} catch {
    Write-Host "An error occurred while searching: $_"
}
