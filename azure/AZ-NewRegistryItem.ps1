# List of servers
$list = @(Get-AzVM | Where-Object {$_.Name -like "tffpcusvda[a-z][a-z][0-9][0-9][0-9]"} | Select-Object Name -ExpandProperty Name)

# Registry key and value
$registryKey = "HKLM:\SOFTWARE\Policies\Citrix\VCPolicies"
$valueName = "ApplicationLaunchWaitTimeoutMS"
$valueData = 0x0002bf20

# Iterate through each server
foreach ($server in $list)
{
    try
    {
        # Use PowerShell remoting to create the registry key on the remote server
        Invoke-Command -ComputerName $server -ScriptBlock {
            New-Item -Path $using:registryKey -Force
            Set-ItemProperty -Path $using:registryKey -Name $using:valueName -Value $using:valueData
        }

        Write-Host "Registry key created on $server"
    }
    catch
    {
        Write-Host "Failed to create registry key on $server. Error: $_"
    }
}