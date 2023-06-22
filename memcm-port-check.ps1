# Define server names
$PrimarySiteServer = "MEMCM01"
$AdditionalMEMCMServers = @("MEMCM02", "MEMCM03")
$DatabaseServer = "DB01"
$Client = "Client01"

# Define port bundles to check

$PortBundles = @(
    @{ Source = $PrimarySiteServer; Target = $DatabaseServer; Ports = @(1433, 4022) },  # MEMCM Site Server to SQL Server
    @{ Source = $Client; Target = $PrimarySiteServer; Ports = @(80, 443, 10123) },       # Client to MEMCM Site Server
    @{ Source = $Client; Target = $DatabaseServer; Ports = @(8530, 8531) },              # Client to SUP/Wsus Server
    @{ Source = $PrimarySiteServer; Target = $Client; Ports = @(10123) }                 # MEMCM Site Server to Client
)

# Add additional checks for MEMCM servers
foreach ($Server in $AdditionalMEMCMServers) {
    $PortBundles += @{ Source = $PrimarySiteServer; Target = $Server; Ports = @(80, 443, 445, 10123) }
    $PortBundles += @{ Source = $Server; Target = $PrimarySiteServer; Ports = @(80, 443, 445, 10123) }
}

# Function to test connection
# The `Test-ConnectionToPorts` function is testing the connection between a source server and a target server on a list of specified ports. It first checks if PSRemoting is available on the source server, and then uses `Invoke-Command` to run a script block on the source server that tests the connection to the target server on each port in the list. It outputs a success message if the connection is successful, an error message if the connection fails, and an error message with details if an error occurs while trying to connect.
function Test-ConnectionToPorts {
    param($SourceServer, $TargetServer, $Ports)

    # Check if PSRemoting is available on SourceServer
    if ((Test-WSMan -ComputerName $SourceServer -ErrorAction SilentlyContinue) -eq $null) {
        Write-Host "Error: PSRemoting is not enabled or accessible on the $SourceServer."
        return
    }

    # Invoke command on the SourceServer
    Invoke-Command -ComputerName $SourceServer -ScriptBlock {
        param($TargetServer, $Ports)

        foreach ($Port in $Ports) {
            try {
                # Set up TCP connection
                $TCPConnection = Test-NetConnection -ComputerName $TargetServer -Port $Port -ErrorAction Stop

                # Check if connection is successful
                if ($TCPConnection.TcpTestSucceeded) {
                    Write-Host "Success: Able to connect to $TargetServer on port $Port from $env:computername."
                } else {
                    Write-Host "Error: Unable to connect to $TargetServer on port $Port from $env:computername."
                }
            } catch {
                Write-Host "Error: An error occurred while trying to connect to $TargetServer on port $Port from $env:computername. Error details: $_"
            }
        }
    } -ArgumentList $TargetServer, $Ports
}

# Iterate over all port bundles and check each connection
# The `foreach` loop is iterating over each port bundle defined in the `$Bundle` array. For each bundle, it calls the `Test-ConnectionToPorts` function with the source server, target server, and list of ports specified in the bundle. The function then tests the connection between the source and target servers on each port in the list and outputs a success message, error message, or error message with details depending on the outcome of each connection test.
foreach ($Bundle in $PortBundles) {
    Test-ConnectionToPorts -SourceServer $Bundle.Source -TargetServer $Bundle.Target -Ports $Bundle.Ports
}
