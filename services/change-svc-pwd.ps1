$server = read-host -Prompt 'Enter a server name'

invoke-command -computername $server -ScriptBlock {
$includes = read-host -prompt "Search for services that include"
# $account = read-host -Prompt "Enter the Account Name"
$password = read-host -prompt "Paste the Password"
# $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$allSvcs = Get-WmiObject Win32_Service | where-object {$_.name -like "*$includes*"}
#$allSvcs = Get-WmiObject Win32_Service | Where-Object { $_.StartName -like "*richmond\P_BGDiad*" }

foreach ($svc in $allSvcs){
    if ($svc.State -ne 'Running'){
    $svc.state
    $svc.change($null,$null,$null,$null,$null,$null,$null,$password,$null,$null)
    } else {
    #$svc.StopService()
    #start-sleep -seconds 2
    $svc.State
    #start-sleep -seconds 2
    #$svc.change($null,$null,$null,$null,$null,$null,$account,$password)
    #$svc.StartService()
    #start-sleep -seconds 2
    }
}
}

<# Code to help build a new service for testing: 
$serviceName = "TestService1"
$displayName = "Notepad Test"
$scriptPath = "C:\vscode\psscripts\playground\OpenTestFile.ps1"
Invoke-Command -ScriptBlock {sc.exe create $serviceName binPath= "Powershell.exe -executionpolicy bypass -File $scriptPath" obj= "Richmond\NTST004" password= ";x!Wdt%cLeOK" start= demand displayname= "$displayName"}

# To delete the Service after done
Invoke-Command -ScriptBlock {sc.exe delete $serviceName}
#>