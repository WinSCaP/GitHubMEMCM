#requires -RunAsAdministrator

# Define parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$ContentDirectory,

    [string]$WSUSServer = "wsus.local.net"
)

$ContentDirectory "D:\wsusContent"

# Install WSUS role and features
Install-WindowsFeature -Name UpdateServices, UpdateServices-WidDB, UpdateServices-Services, UpdateServices-RSAT, UpdateServices-API, UpdateServices-UI -IncludeManagementTools

# Set the WSUS Content Directory
$ContentDirectory = Join-Path -Path $ContentDirectory -ChildPath "WSUS"

# Create the content directory if it doesn't exist
if (-not (Test-Path -Path $ContentDirectory)) {
    New-Item -Path $ContentDirectory -ItemType Directory
}

# Specify the WSUS server name and port
$WSUSServer = "https://$WSUSServer:8531"

# Import WSUS module
Import-Module UpdateServices

# Configure WSUS
Set-WsusServer -SslCertificateName "WSUS"
Set-WsusServer -SynchronizeAutomatically $true
Set-WsusServer -ContentDir $ContentDirectory
Set-WsusServer -SqlServer $WSUSServer
Set-WsusServer -SyncFromMU $false
Set-WsusServer -Language "Dutch", "English"
Set-WsusServer -Product "All"

# Start WSUS services
Start-Service WSUSService
Start-Service WSUSSynchronizationService

# Perform the initial synchronization
Invoke-WsusServerSynchronization -SyncNow
