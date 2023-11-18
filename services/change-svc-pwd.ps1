﻿$server = read-host -Prompt 'Enter a server name'

invoke-command -computername $server -ScriptBlock {
# $includes = read-host -prompt "Search for services that include"
# $account = read-host -Prompt "Enter the Account Name"
$password = read-host -prompt "Paste the Password"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
# $allSvcs = Get-WmiObject Win32_Service | Select-Object -ExpandProperty Name | Select-String -pattern $includes
$allSvcs = Get-WmiObject Win32_Service | Where-Object { $_.StartName -like "*richmond\NP_ECD*" }

foreach ($svc in $allSvcs){
    if ($svc.State -ne 'Running'){
    write-host 'not running'
    $svc.change($null,$null,$null,$null,$null,$null,$null,$password,$null,$null)
    } else {
    $svc.StopService()
    start-sleep -seconds 2
    write-host 'running'
    start-sleep -seconds 2
    #$svc.change($null,$null,$null,$null,$null,$null,$account,$password)
    $svc.StartService()
    start-sleep -seconds 2
    }
}
}