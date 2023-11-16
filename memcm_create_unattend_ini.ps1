param(
    [string]$SMSInstallDir           = "D:\Program Files\Microsoft Configuration Manager",
    [string]$SiteCode                = "P01",
    [string]$SiteName                = "Primary Site 1",
    [string]$SDKServer               = "CM01",
    [string]$ProductID               = "EVAL", # BXH69-M62YX-QQD6R-3GPWX-8WMFY Static Setup Key
    [string]$ParentSiteCode          = "",
    [string]$JoinCeip                = "0",
    [string]$MobileDeviceLanguage    = "0",
    [string]$RoleCommunicationProtocol = "HTTPorHTTPS",
    [string]$ClientsUsePKICert       = "0",
    [string]$PrerequisiteComp        = "1",
    [string]$PrerequisitePath        = "C:\SCCM_AUTOINSTALL\SCCM_DL",
    [string]$DatabaseName            = "CM_P01",
    [string]$SqlServerName           = "DB01",
    [string]$ManagementPoint         = "cmsite.contoso.com",
    [string]$ManagementPointProtocol = "HTTPS",
    [string]$DistributionPoint       = "cmsite.contoso.com",
    [string]$DistributionPointProtocol = "HTTPS",
    [string]$DistributionPointInstallIIS = "1",
    [string]$DatabaseSize            = "50",
    [string]$AdminConsole            = "1",
    [string]$SavePath                = "C:\SCCM_AutoInstall\MEMCM_Unattended.ini"
)

# Generate MEMCM unattended setup script file
$SetupScriptContent = @"
[Identification]
Action=InstallPrimarySite
CDLatest=1

[Options]
ProductID=$ProductID
SiteCode=$SiteCode
SiteName=$SiteName
SMSInstallDir=$SMSInstallDir
SDKServer=$SDKServer
ParentSiteCode=$ParentSiteCode
PrerequisiteComp=$PrerequisiteComp
PrerequisitePath=$PrerequisitePath
MobileDeviceLanguage=$MobileDeviceLanguage
RoleCommunicationProtocol=$RoleCommunicationProtocol
ClientsUsePKICertificate=$ClientsUsePKICert
JoinCeip=$JoinCeip
AdminConsole=$AdminConsole
ManagementPoint=$ManagementPoint
ManagementPointProtocol=$ManagementPointProtocol
DistributionPoint=$DistributionPoint
DistributionPointProtocol=$DistributionPointProtocol
DistributionPointInstallIIS=$DistributionPointInstallIIS

[SQLConfigOptions]
SQLServerName=$SqlServerName
DatabaseName=$DatabaseName
SQLServerPort=1433
;SQLDataFilePath=C:\DATA\
;SQLLogFilePath=C:\LOG\

[CloudConnectorOptions]
CloudConnector=0
UseProxy=0
ProxyName=
ProxyPort=
UseProxyAuthentication=0
ProxyUserName=
ProxyPassword=

[SABranchOptions]
SAActive=1
CurrentBranch=1
"@

# Write the script file
$SetupScriptContent | Out-File -FilePath $SavePath

Write-Host "MEMCM unattended setup script file created at $SavePath"
