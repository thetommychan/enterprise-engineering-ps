# Get servername
$server = read-host -Prompt "What server?"

Invoke-command  -ComputerName $server -ScriptBlock
{
import-module WebAdministration

# Get all application pools
$AppPools = Get-ChildItem IIS:\AppPools

# Recycle each application pool
foreach ($AppPool in $AppPools) 
    {
    Write-Host "Recycling application pool: $($AppPool.Name)"
    $AppPool.Recycle()
    }
Write-Host "All application pools have been recycled."
}

Invoke-WebRequest -uri "https://download.sysinternals.com/files/PSTools.zip" -OutFile "C:\psexec.zip"


$default = $xml.SelectSingleNode("//appcmd/APPPOOL[@APPPOOL.NAME='DefaultAppPool']")
$classic = $xml.SelectSingleNode("//appcmd/APPPOOL[@APPPOOL.NAME='Classic .NET AppPool']")
$classic2 = $xml.SelectSingleNode("//appcmd/APPPOOL[@APPPOOL.NAME='.NET v2.0 Classic']")
$net2 = $xml.SelectSingleNode("//appcmd/APPPOOL[@APPPOOL.NAME='.NET v2.0']")
$classic45 = $xml.SelectSingleNode("//appcmd/APPPOOL[@APPPOOL.NAME='.NET v4.5 Classic']")
$net45 = $xml.SelectSingleNode("//appcmd/APPPOOL[@APPPOOL.NAME='.NET v4.5']")  