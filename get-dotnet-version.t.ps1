# Get server.NET version

$serverName = Read-Host -Prompt "Enter the name of the server or computer(non-FQDN)"

# Change to server local directory
Set-Location \\$serverName\c$

# Assign reg key of .net version to variable
$dNV = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client').Version

Write-Host "The .NET FrameWork Version on this server is $dNV"

# Go home
Set-Location ~