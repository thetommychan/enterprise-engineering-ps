foreach ($serviceInfo in $servicesData) {
    $serviceName = $serviceInfo.'Service' # Change to your column name
    $serviceAccount = "Richmond\NBCH100"
    $password = ConvertTo-SecureString "Rx$Db6p!2Mz" -AsPlainText -Force

    $batchFilePath = "C:\Scripts (Windows Server)\testing\DummyService.bat" # Change to the path of your batch file

    New-Service -Name $serviceName -DisplayName $serviceName -BinaryPathName $batchFilePath -Description "Dummy service for testing" -StartupType Automatic
    Set-Service -Name $serviceName -Credential (New-Object PSCredential -ArgumentList $serviceAccount, $password)
}


<#Prod#> Invoke-Command -ComputerName wpappa11 -ScriptBlock {Get-Service | Where-Object {$_.Name -Like "*EDRGenerator*"} | Start-Service}
<#Test#> Invoke-Command -ComputerName wtappa11 -ScriptBlock {Get-Service | Where-Object {$_.Name -Like "*EDRGenerator*"} | Start-Service}





function Update-ServiceAccounts {
    param (
        [string]$server,
        [string]$password,
        [switch]$ViewOnly
    )

# Prompt for password without whitespaces or leading spaces
$password = Read-Host -Prompt "Paste the password, no whitespaces or leading spaces"

# Get services based on filters
$services = Get-WmiObject -ComputerName $server Win32_Service | Where-Object { $_.Name -match ($serviceConditions.Keys -join '|') }

# Change logon info for service accounts and provide status updates
foreach ($service in $services) {
    $serviceName = $service.Name
    $startName = $service.StartName

    Write-Host "Updating service '$serviceName' with start name '$startName'"

    if ($service.State -ne 'Running') {
        Write-Host "Service is not running. Changing service account and password."
        $condition = ($serviceConditions.GetEnumerator() | Where-Object { $serviceName -match $_.Key }).Value
        $service.Change($null, $null, $null, $null, $null, $null, $condition, $password, $null, $null)
    } else {
        Write-Host "Service is running. Stopping, changing service account and password, then starting."
        $service.StopService()
        $condition = ($serviceConditions.GetEnumerator() | Where-Object { $serviceName -match $_.Key }).Value
        $service.Change($null, $null, $null, $null, $null, $null, $condition, $password, $null, $null)
        $service.StartService()
    }

    Write-Host "Service '$serviceName' updated."
}


    $serviceConditions = @{
        "BG_DIAD|BG_Purge|BG_Master" = 'Richmond\NP_BGDiad'
        "CustImp" = 'Richmond\NP_CustImport'
        "DispGeo" = 'Richmond\NP_DispGeo'
        "DynRoute" = 'Richmond\NP_DynRoute'
        "UPGF ECD_" = 'Richmond\NP_ECD'
        "BG_HOST|BG_EDGEtoPND|BG_PNDtoEDGE" = 'Richmond\NP_BGHost'
    }

    $services = Get-WmiObject -ComputerName $server Win32_Service | Where-Object { $_.Name -match ($serviceConditions.Keys -join '|') }

    foreach ($service in $services) {
        $serviceName = $service.Name
        $startName = $service.StartName

        Write-Host "Service Name: $serviceName"
        Write-Host "Start Name: $startName"

        if ($ViewOnly) {
            continue
        }

        # Modify service accounts if not in ViewOnly mode
        # Rest of the modification code...
    }
}
