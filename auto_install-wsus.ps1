$ContentDirectory = "D:\wsusContent"

# Install WSUS role and features
Install-WindowsFeature -Name UpdateServices, UpdateServices-WidDB, UpdateServices-Services, UpdateServices-RSAT, UpdateServices-API, UpdateServices-UI -IncludeManagementTools

# Set the WSUS Content Directory
$ContentDirectory = Join-Path -Path $ContentDirectory -ChildPath "WSUS"

# Create the content directory if it doesn't exist
if (-not (Test-Path -Path $ContentDirectory)) {
    New-Item -Path $ContentDirectory -ItemType Directory
}

# Specify the WSUS server name and port
$WSUSServer = "wsus01.ad.irisstraat.nl"


### Configure post-deplpyment settings
. "C:\Program Files\Update Services\Tools\WsusUtil.exe" postinstall CONTENT_DIR=$ContentDirectory


# Import WSUS module
Import-Module UpdateServices

# Start WSUS services
Start-Service WSUSService

### REBOOT IS NEEDED HERE !!!

$Wsus = Get-WsusServer
# Connect to WSUS server configuration
$wsusConfig = $wsus.GetConfiguration()
# Set to download updates from $WSUSServer
Set-WsusServerSynchronization -UssServerName $WSUSServer -PortNumber 8531 -UseSSL

# Set Update Languages to English and Dutch and save configuration settings
$wsusConfig.AllUpdateLanguagesEnabled = $false   
[System.Collections.Specialized.StringCollection]$WsusLanguages = "en"        
[System.Collections.Specialized.StringCollection]$WsusLanguages += "nl"

$wsusConfig.SetEnabledUpdateLanguages($WsusLanguages)           
$wsusConfig.Save()

### Start the WSUS synchronization
$wsus.GetSubscription().StartSynchronizationForCategoryOnly()
start-sleep 15

### Starting while loop, which ensures that the synchronization finishes before continuing
while ($wsus.GetSubscription().GetSynchronizationStatus() -ne "NotProcessing") {
$time = get-date -UFormat "%H:%M:%S"
$total = $wsus.GetSubscription().getsynchronizationprogress().totalitems
$processed = $wsus.GetSubscription().getsynchronizationprogress().processeditems
$process = $processed/$total
$progress = "{0:P0}" -f $process
Write-Host ""
Write-Host "The first synchronization isn't completed yet $time"
Write-Host "Kindly have patience, the progress is $progress"
Start-Sleep 10
}
Write-Host "The synchronization has completed at $time" -ForegroundColor Green
Write-Host "The WSUS Configuration will now continue"  -ForegroundColor Green

### Configure the Products
write-host 'Setting WSUS Products'
Get-WsusProduct | where-Object {
    $_.Product.Title -in (
    'Windows 10')
} | Set-WsusProduct

### Configure classifications
write-host 'Setting WSUS Classifications'
Get-WsusClassification | Where-Object {
    $_.Classification.Title -in (
    'Critical Updates',
    'Security Updates')
} | Set-WsusClassification

### Configure Synchronizations
write-host 'Enabling WSUS Automatic Synchronisation'
$subscription = $wsus.GetSubscription()
$subscription.SynchronizeAutomatically=$true

### Set synchronization scheduled for midnight each night
$subscription.SynchronizeAutomaticallyTimeOfDay= (New-TimeSpan -Hours 0)
$subscription.NumberOfSynchronizationsPerDay=1
$subscription.Save()

### Create computer target group
$wsus.CreateComputerTargetGroup("Updates")

### Configure Default Approval
write-host 'Configuring default automatic approval rule'
[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
$rule = $wsus.GetInstallApprovalRules() | Where {
    $_.Name -eq "Default Automatic Approval Rule"}
$class = $wsus.GetUpdateClassifications() | ? {$_.Title -In (
    'Critical Updates',
    'Security Updates')}
$class_coll = New-Object Microsoft.UpdateServices.Administration.UpdateClassificationCollection
$class_coll.AddRange($class)
$rule.SetUpdateClassifications($class_coll)
$rule.Enabled = $True
$rule.Save()

### Configure that computers are assigned to correct group


### Remove WSUS configuration pop-up when opening WSUS Management Console
$wsusConfig.OobeInitialized = $true
$wsusConfig.Save()

### Start Synchronization
$wsus.GetSubscription().StartSynchronization()