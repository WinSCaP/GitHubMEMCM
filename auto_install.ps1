#requires -runasadministrator

#Variables



$BaseURL             = 'http://172.17.171.235/sccm_autoinstall/'  # Note Wget Cut-Dirs
$WgetUrl             = $BaseURL + 'wget.exe'
$BaseDir             = 'C:\SCCM_AUTOINSTALL\'
$SccmIso             = $BaseDir + 'ISO/SW_DVD5_Endpoint_Config_Mgr_CML_2303_MultiLang_ConfMgr_MLF_X23-54108.ISO'
$Win2022Iso          = $BaseDir + 'ISO/SW_DVD9_Win_Server_STD_CORE_2022_2108.24_64Bit_English_DC_STD_MLF_X23-54269.ISO'
$ADKDir              = $BaseDir + 'ADK'


# Site configuration
$SCCM_DBServer       = 'DB01'
$SCCM_PrimarySite    = 'CM01'
$SCCM_Distribution1  = 'CM02'
$SCCM_Distribution2  = 'CM03'
$SCCM_WSUSServer     = 'CM02'
$SCCM_EndProt        = 'CM03'
$SCCM_InstallDrive   = 'D'
$WgetCutDirs         = 1
# ToDo
$SCCM_CA             = ''

# Running PreReq on $PrimarySite and 2x Distribution Point
# Invoke-Command -ComputerName $SCCM_Distribution1,$SCCM_Distribution1,$SCCM_Distribution1 -FilePath "$BaseDir\auto_install.ps1"

############### FUNCTIONS ############
Function WaitForProcessEnd { [CmdletBinding()] 
    Param([String]$processName, [String]$msg)
    $processRunning=$true
    Write-Host $msg -NoNewline
    Do {
        Write-Host '.' -NoNewline
        Start-Sleep -Seconds 30
        $process=Get-Process -Name $processName -ErrorAction SilentlyContinue
        if (-Not $process) {
            $processRunning=$false
        }
     } While ($processRunning)
}

If (-Not (Test-Path -PathType Container $BaseDIR)) {
    Try {
        New-Item -Path $BaseDir -Type Directory
        Write-Host "- Created $BaseDir"
    } Catch {
        Write-Error $_
    }
}
Push-Location $BaseDIR

If (-Not (Test-Path "$BaseDir\wget.exe")) {
    Try { 
        Invoke-WebRequest -Uri $WgetUrl -OutFile "$BaseDir\wget.exe"
        Write-Host "- Retrieved wget.exe"
    } Catch {
        Write-Error -Message "Could not download wget.exe"
        Write-Error $_
    } 
}

# ToDo Parameters to ignore index.html and not download SCCM PreReq on other servers than primary Site
Write-Host "-- Retrieving work data, please wait (5 min)"
.\wget.exe -nH -np -m -q $BaseURL --cut-dirs=$WgetCutDirs  | Out-Null

Write-Host "- Setting Up Basics"

Try { 
    # Get SCCM Install Media Setup
    $TempSccmDVD = Mount-DiskImage -PassThru -ImagePath $SccmIso
    $SccmDVD = Get-DiskImage $TempSccmDVD.ImagePath
    $SccmDVDDrive = Get-Volume -DiskImage $SccmDVD
    $SccmDVDDriveLetter = [String]$SccmDVDDrive.DriveLetter + ":"

    #
    $SccmSetupMedia = Join-Path -Path $SccmDVDDriveLetter -ChildPath "SMSSETUP\BIN\X64\setupdl.exe" -ErrorAction Stop

    #
    $SccmPreReqDL = "$BaseDir\SCCM_DL"

    # 
    $ADK_OfflineData = "$ADKDir\ADKoffline"
    $ADKPE_OfflineData = "$ADKDir\ADKPEoffline"

    #
    if(-Not (Test-Path -Path $SccmSetupMedia)){
        Write-Host "SCCM Installation Media not found at: $SccmSetupMedia"
        Write-Error $SccmSetupMedia -ErrorAction Stop
    } else {
        Write-Host "SCCM Installation Media found at: $SccmSetupMedia"
    }

    #
    if(-Not (Test-Path -Path "$ADKDir\adksetup.exe")) { 
        Write-Host "ADK Setup Not Found at: $ADKDir\adksetup.exe"
    } 
    if(-Not (Test-Path -Path "$ADKDir\adkwinpesetup.exe")) { 
        Write-Host "ADK PE Setup Not Found at: $ADKDir\adkwinpesetup.exe"
    } 
    if(-Not (Test-Path -Path "$ADK_OfflineData\adksetup.exe")) { 
        Write-Host "ADK Offline Setup Not Found at: $ADK_OfflineData\adksetup.exe"
    } 
    if(-Not (Test-Path -Path "$ADKDir\adkwinpesetup.exe")) { 
        Write-Host "ADK Offline PE Setup Not Found at: $ADKPE_OfflineData\adkwinpesetup.exe"
    } 

} Catch {
    Write-Error $_
} 

Write-Host "All PreReq Files are found, continuing SCCM Setup"

# Install Windows Features

if (-Not (Get-Module -Name ServerManager -ErrorAction SilentlyContinue)) {
    Import-Module -Name ServerManager -ErrorAction Stop
}
$InstalledWindowsFeatures = Get-WindowsFeature -ErrorAction Stop
$WindowsFeatureList=@(
    'BITS',
    'BITS-IIS-Ext',
    'RDC',
    'RSAT-Bits-Server',
    'RSAT-Feature-Tools',
    'NET-HTTP-Activation',
    'NET-Non-HTTP-Activ',
    'NET-Framework-45-ASPNET',
    'NET-WCF-HTTP-Activation45',
    'NET-WCF-TCP-PortSharing45',
    'Web-Server',
    'Web-Common-Http',
    'Web-Default-Doc',
    'Web-Dir-Browsing',
    'Web-Http-Errors',
    'Web-Static-Content',
    'Web-Http-Redirect',
    'Web-Health',
    'Web-Http-Logging',
    'Web-Request-Monitor',
    'Web-Http-Tracing',
    'Web-Security',
    'Web-Filtering',
    'Web-Basic-Auth',
    'Web-CertProvider',
    'Web-IP-Security',
    'Web-Url-Auth',
    'Web-Windows-Auth',
    'Web-App-Dev',
    'Web-Net-Ext',
    'Web-Net-Ext45',
    'Web-ISAPI-Ext',
    'Web-ISAPI-Filter',
    'Web-Includes',
    'Web-Ftp-Server',
    'Web-Ftp-Service',
    'Web-Mgmt-Tools',
    'Web-Mgmt-Console',
    'Web-Mgmt-Compat',
    'Web-Metabase',
    'Web-Lgcy-Mgmt-Console',
    'Web-Lgcy-Scripting',
    'Web-WMI',
    'Web-Scripting-Tools',
    'Web-Mgmt-Service')

# Special Attention for .Net Framwork 3.5
$NetFrameWork3 = 'NET-Framework-Core'
$NetFrameWork3Installed = $InstalledWindowsFeatures | Where-Object { $_.Name -eq $NetFrameWork3 }
If (-Not ($NetFrameWork3Installed.Installed)) {
    Write-Host "$NetFrameWork3 Not Installed, Checking Windows Media"

    # Get Windows Install Media Setup
    $TempWindowsDVD = Mount-DiskImage -PassThru -ImagePath $Win2022Iso
    $WindowsDVD = Get-DiskImage $TempWindowsDVD.ImagePath
    $WindowsDVDDrive = Get-Volume -DiskImage $WindowsDVD
    $WindowsDVDDriveLetter = [String]$WindowsDVDDrive.DriveLetter + ":"

    #
    $WindowsSetupMedia = Join-Path -Path $WindowsDVDDriveLetter -ChildPath "sources\sxs\" -ErrorAction Stop

    #
    Write-Host "Installing $NetFrameWork3"
    Install-WindowsFeature -Name $NetFrameWork3 -Source $WindowsSetupMedia -ErrorAction Stop
}

# Install Needed Windows Features
Write-Host "Installing required Windows Features"
Install-WindowsFeature -Name $WindowsFeatureList -ErrorAction Stop

# Installing ADK
Write-Host "Installing ADK and PE"
& "$ADK_OfflineData\adksetup.exe" /ceip off /features "OptionId.DeploymentTools OptionId.UserStateMigrationTool" /quiet
WaitForProcessEnd -processName adksetup -msg "Installing ADK"
& "$ADKDir\adkwinpesetup.exe" /features "OptionId.WindowsPreinstallationEnvironment" /quiet
WaitForProcessEnd -processName adksetup -msg "Installing PreInstallation Environment"

#Installing SQL Native Client 2012 SP4+
& "msiexec.exe" /i "$BaseDir\SQLNativeClient\sqlncli.msi" /quiet /forcerestart IACCEPTSQLNCLILICENSETERMS=YES


WaitForProcessEnd -processName msiexec -msg "Installing SQL Native Client and Forcing Restart"

Invoke-Command -ComputerName $SCCM_WSus -FilePath C:\SCCM_AUTOINSTALL\auto_install_wsus.ps1 -ContentDirectory "D:\wsusContent"

.\no_sms_on_drive.ps1 -ServerList $SCCM_PrimarySite,$SCCM_Distribution1,$SCCM_Distribution2 -ExcludeDriveLetter $SCCM_InstallDrive

# Get the domain information
$DomainInfo = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).Name

# Split the domain name 
$SplitDomain = $DomainInfo.Split('.')

# Generate the acronym
$Acronym = $SplitDomain[0].Substring(0,1).ToUpper() + $SplitDomain[1].Substring(0,1).ToUpper() + 'P'

.\memcm_check_system_container.ps1


.\memcm_create_unattend_ini.ps1 -ProductID BXH69-M62YX-QQD6R-3GPWX-8WMFY -SDKServer CM01 -SqlServerName DB01 -ManagementPoint CM01 -DistributionPoint CM02

E:\SMSSETUP\BIN\X64\setup.exe /SCRIPT C:\SCCM_AutoInstall\MEMCM_Unattended.ini

# watch the install log for errors
#Get-Content -Path C:\ConfigMgrSetup.log -Wait


