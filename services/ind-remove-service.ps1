$filters = {$_.Name -like "UUPGF BG_Host_Beta_D009"}
$service = Get-WmiObject -ComputerName WDPNDA27 | Where-Object $filters
$svc = {$_.Name -like "UUPGF BG_Host_Beta_D009"}
Start-Transcript c:\ps-logs\remove-services-cutoverNP\logfile.txt -Append
#$password = Read-Host -Prompt "Paste the password, no whitespaces or leading spaces"
#$account = 'Richmond\NP_ECD'
if ($svc){
    write-host $service.Name
    write-host $service.StartName
    if ($service.State -ne 'Running') {
        $ask = Read-Host -Prompt "Are you sure you would like to remove $service.Name?"
        if ($ask -eq "y"){
            Write-Host "Deleting $service.Name"
            $service.Delete()
        } else {
            Write-Host "Not Deleting $service.Name"
        }
    } else {
        write-host "running"
        $service.StopService()
        $ask = Read-Host -Prompt "Are you sure you would like to remove $service.Name?"
        if ($ask -eq "y"){
            Write-Host "Deleting $service.Name"
            $service.Delete()
        } else {
            Write-Host "Not Deleting $service.Name"
        # $service.StartService()
        }     
    
    }
}  else {
    Write-Host "Service does not exist"
}