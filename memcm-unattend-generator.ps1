# Define MEMCM installation parameters
$MEMCMParameters = @{
    InstallDir              = "C:\\Program Files\\Microsoft Configuration Manager"
    SiteCode                = "P01" # Replace with your site code
    SiteName                = "Primary Site 1" # Replace with your site name
    SMSInstallDir           = "C:\\Program Files\\Microsoft Configuration Manager"
    SDKServer               = "MEMCM01" # Replace with your SDK server name
    ParentSiteCode          = "" # No parent site for a primary site
    JoinCeip                = "0" # Don't join CEIP (0=No, 1=Yes)
    MobileDeviceLanguage    = "0" # Default language (0=Default, 1=All)
    RoleCommunicationSchema = "HTTPorHTTPS" # Use HTTP or HTTPS for role communication
    ClientsUsePKICert       = "0" # Clients don't use a PKI certificate (0=No, 1=Yes)
    PrerequisiteComp        = "0" # Don't install required components (0=No, 1=Yes)
    PrerequisitePath        = "" # No path for prerequisite files
    DatabaseName            = "CM_P01" # Replace with your database name
    SqlServerName           = "DB01" # Replace with your SQL Server name
    DatabaseSize            = "50" # Set initial size of the database (in MB) 
    CCARSiteServer          = "" # No central administration site server
    CasRetryInterval        = "30" # Retry interval for connection attempts (in minutes)
    WaitForCasTimeout       = "60" # Timeout for waiting for the central administration site (in minutes)
}

# Generate MEMCM unattended setup script file
$SetupScriptContent = @"
[Identification]
Action=InstallPrimarySite

[Options]
ProductID=EVAL
SiteCode=$($MEMCMParameters.SiteCode)
SiteName="$($MEMCMParameters.SiteName)"
SMSInstallDir="$($MEMCMParameters.SMSInstallDir)"
SDKServer=$($MEMCMParameters.SDKServer)
ParentSiteCode=$($MEMCMParameters.ParentSiteCode)
PrerequisiteComp=$($MEMCMParameters.PrerequisiteComp)
PrerequisitePath=$($MEMCMParameters.PrerequisitePath)
MobileDeviceLanguage=$($MEMCMParameters.MobileDeviceLanguage)
RoleCommunicationSchema=$($MEMCMParameters.RoleCommunicationSchema)
ClientsUsePKICert=$($MEMCMParameters.ClientsUsePKICert)
JoinCeip=$($MEMCMParameters.JoinCeip)

[SQLConfigOptions]
SQLServerName=$($MEMCMParameters.SqlServerName)
DatabaseName=$($MEMCMParameters.DatabaseName)
SQLServerPort=1433
SQLDataFilePath=
SQLLogFilePath=

[CloudConnectorOptions]
CloudConnector=0
UseProxy=0
ProxyName=
ProxyPort=
UseProxyAuthentication=0
ProxyUserName=
ProxyPassword=

[CASOptions]
CCARSiteServer=$($MEMCMParameters.CCASiteServer)
CasRetryInterval=$($MEMCMParameters.CasRetryInterval)
WaitForCasTimeout=$($MEMCMParameters.WaitForCasTimeout)
"@

# Write the script file
$SetupScriptContent | Out-File -FilePath ".\MEMCM_Unattended.ini"

Write-Host "MEMCM unattended setup script file created at .\MEMCM_Unattended.ini"
