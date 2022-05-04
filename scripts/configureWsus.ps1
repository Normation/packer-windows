# inspired from https://smsagent.blog/2014/02/07/installing-and-configuring-wsus-with-powershell/
Set-Location 'C:\Program Files\Update Services\Tools\'
.\wsusutil.exe postinstall CONTENT_DIR=C:\WSUS

# Basic WSUS config
$wsus = Get-WSUSServer
$wsusConfig = $wsus.GetConfiguration()
Set-WsusServerSynchronization -SyncFromMU
$wsusConfig.AllUpdateLanguagesEnabled = $false
$wsusConfig.SetEnabledUpdateLanguages("en")
$wsusConfig.Save()

# Initial sync to retrieve avaiable products
$subscription = $wsus.GetSubscription()
$subscription.StartSynchronizationForCategoryOnly()
write-host 'Beginning first WSUS Sync to get available Products etc' -ForegroundColor Magenta
write-host 'Will take some time to complete'
While ($subscription.GetSynchronizationStatus() -ne 'NotProcessing') {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}
write-host ' '
Write-Host "Sync is done." -ForegroundColor Green

# Select products
write-host 'Setting WSUS Products'
Get-WsusProduct | Where-Object { $_.Product.Title -match 'Windows Server 2019.*' } | Set-WsusProduct

# Configure the Classifications
write-host 'Setting WSUS Classifications'
Get-WsusClassification | Where-Object {
    $_.Classification.Title -in (
    'Critical Updates',
    'Definition Updates',
    'Feature Packs',
    'Security Updates',
    'Service Packs',
    'Update Rollups',
    'Updates')
} | Set-WsusClassification

Start-Sleep -Seconds 10

# Configure Synchronizations
write-host 'Enabling WSUS Automatic Synchronisation'
$subscription.SynchronizeAutomatically=$true

# Set synchronization scheduled for midnight each night
$subscription.SynchronizeAutomaticallyTimeOfDay= (New-TimeSpan -Hours 0)
$subscription.NumberOfSynchronizationsPerDay=1
$subscription.Save()

# Kick off a synchronization
$subscription.StartSynchronization()
write-host 'Starting WSUS Sync, will take some time' -ForegroundColor Magenta
Start-Sleep -Seconds 60 # Wait for sync to start before monitoring
while ($subscription.GetSynchronizationProgress().ProcessedItems -ne $subscription.GetSynchronizationProgress().TotalItems) {
    Write-Progress -PercentComplete (
    $subscription.GetSynchronizationProgress().ProcessedItems*100/($subscription.GetSynchronizationProgress().TotalItems)
    ) -Activity "WSUS Sync Progress"
}
Write-Host "Sync is done." -ForegroundColor Green
