# Define service name and remote server
$serviceName = Read-Host -Prompt "Enter Service Name"
$remoteServer = Read-Host -Prompt "Enter Remote Server Name"

# Stop the service
Invoke-Command -ComputerName $remoteServer -ScriptBlock { Stop-Service -Name $using:serviceName -Force }

# Delete the service registry key and its subkeys
$serviceRegistryPath = "Registry::\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$serviceName"
Invoke-Command -ComputerName $remoteServer -ScriptBlock { Remove-Item -Path $using:serviceRegistryPath -Recurse }

# Restart the remote server to apply changes (optional)
Restart-Computer -ComputerName $remoteServer -Force