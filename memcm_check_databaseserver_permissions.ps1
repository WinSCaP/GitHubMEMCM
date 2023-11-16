# NEEDS FIXING

param(
    [string]$DatabaseServer = "DB01", # Replace with your DB server name
    [string]$ComputerAccount = "CM01$", # Domain computer account to check
    [string]$ServiceName = "MSSQLSERVER", # SQL Server service name
    [string]$SQLInstance = "MSSQLSERVER" # SQL Server instance name
)

# Function to check and add a computer to the Administrators group
function Update-AdminGroupMembership {
    param (
        [string]$server,
        [string]$computer
    )

    $group = [ADSI]"WinNT://$server/Administrators,group"
    $computerAccount = "WinNT://$computer,computer"

    try {
        $isMember = $group.Invoke("IsMember", $computerAccount)
        if (-not $isMember) {
            Write-Host "$computer is not a member of the Administrators group on $server. Adding..."
            $group.Add($computerAccount)
            Write-Host "$computer added to the Administrators group on $server."
        } else {
            Write-Host "$computer is already a member of the Administrators group on $server."
        }
    } catch {
        Write-Warning "Failed to check or modify group membership: $_"
    }
}

# Function to check if the current user is a member of the MSSQL sysadmin group
function Is-SysAdmin {
    param (
        [string]$sqlInstance
    )

    try {
        $sqlQuery = "SELECT IS_SRVROLEMEMBER('sysadmin')"
        $connectionString = "Server=$sqlInstance; Integrated Security=True;"
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $command = New-Object System.Data.SqlClient.SqlCommand $sqlQuery, $connection
        $connection.Open()
        $result = $command.ExecuteScalar()
        $connection.Close()

        return $result -eq 1
    } catch {
        Write-Warning "Failed to check sysadmin group membership: $_"
        return $false
    }
}

# Update Administrators group membership
Update-AdminGroupMembership -server $DatabaseServer -computer $ComputerAccount

# Check if current user is a member of the MSSQL sysadmin group
if (Is-SysAdmin -sqlInstance $SQLInstance) {
    Write-Host "The current user is a member of the sysadmin group on $SQLInstance."
} else {
    Write-Host "The current user is NOT a member of the sysadmin group on $SQLInstance."
}
