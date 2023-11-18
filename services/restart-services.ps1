# Prompt user for server name
$serverName = Read-Host "Enter the server name"

# Get all services on the specified server with names matching the pattern
$servicePattern = Read-Host -Prompt "Enter the service name pattern (e.g., bg* or PND_DIAD6*)"
$services = Get-Service -ComputerName $serverName | Where-Object { $_.DisplayName -like "$servicePattern" }

# Display selected services for verification
Write-Host "Selected services:"
$services | ForEach-Object { Write-Host $_.DisplayName }

# Confirm restart with the user
$confirmRestart = Read-Host "Do you want to restart the selected services? (yes/no)"

if ($confirmRestart -eq "y") {
    # Restart selected services
    foreach ($service in $services) {
        Write-Host "Restarting service: $($service.DisplayName)..."
        Restart-Service -InputObject $service
    }
    
    # Output to log on Server B
    $logContent = @"
Restarted services on '$serverName':
$($services | ForEach-Object { $_.DisplayName })
"@
    $logPath = "\\opnasi02\Server\Tom\Scripts\logs\ServicesRestartLog.txt"
    $logContent | Out-File -Append -FilePath $logPath

    Write-Host "All selected services on '$serverName' have been restarted."
} else {
    Write-Host "Services will not be restarted."
}