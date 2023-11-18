# Run as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

$adminPrompt = Read-Host -Prompt "Are you running as admin?"
if ($adminPrompt -eq 'y'){
    Write-Host -ForegroundColor Black -back Green "Juice is sufficient"
     if($isAdmin -eq $True){
        continue;
     } else {
        Write-Host "This script requires admin permissions to run. Sign in with your admin account, and try to refrain from lying in the future ;*"
     }
    continue;
} else {
    Write-Host -ForegroundColor Black -BackgroundColor Cyan "Run this command as admin only to avoid file access issues"
    break;
}


# Removing services on test, dev, and QA servers

Start-Transcript c:\ps-logs\remove-services-cutoverNP\logfile.txt -Append
$path = "C:\vscode\server-xmls\pnd-nonprod.xlsx"
$serverlist = Import-Excel -Path $path
#$password = Read-Host -Prompt "Paste the password, no whitespaces or leading spaces"
#$account = 'Richmond\NP_ECD'


# Check for services and change logon info for service accounts

foreach ($server in $serverlist){
    $filter = {$_.Name -like '*UPGF BG_HOST_R2*'}
    $services = Get-WmiObject -computername $server.Servers win32_service | Where-Object $filter
    $svc = {$svc.Name -like '*UPGF BG_HOST_R2*'}
    foreach ($service in $services) {
        # Check for services with names including UPGF_BG_DIAD_R2
        if ($svc){
            write-host $service.Name
            write-host $service.StartName
            if ($service.State -ne 'Running') {
                $ask = Read-Host -Prompt "Are you sure you would like to remove $service.Name from $server?"
                if ($ask -eq "y"){
                    Write-Host "Deleting $service.Name"
                    $service.Delete()
                } else {
                    Write-Host "Not Deleting $service.Name"
                }
            } else {
                write-host "running"
                $service.StopService()
                $ask = Read-Host -Prompt "Are you sure you would like to remove $service.Name from $server?"
                if ($ask -eq "y"){
                    Write-Host "Deleting $service.Name"
                    $service.Delete()
                } else {
                    Write-Host "Not Deleting $service.Name"
                # $service.StartService()
                }                    
            }
        } else {
            Write-Host "$svc.Name does not exist on $server.Servers"
        }
    }   
}
Stop-Transcript