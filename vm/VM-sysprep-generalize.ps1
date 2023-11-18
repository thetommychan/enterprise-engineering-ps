# Run this script when the server has been connected to the network
$sysprepPath = "C:\Windows\System32\Sysprep\sysprep.exe"
$sysprepArguments = "/generalize /oobe /reboot /unattend"
# Define the name of the scheduled task
$nextTask = "Configure Script 2"
$lastTask = "Config Script 1"

# Timer
$timer = [Diagnostics.Stopwatch]::StartNew()
while ($timer.elapsed.totalseconds -lt 5) {
$askFirst = Read-Host -Prompt "Generalize? (y/n)"
if ($askfirst -eq 'y' -or '')
    {
        # Modify scheduled tasks
        Write-Host -ForegroundColor Black -BackgroundColor White "Modifying Scheduled Tasks..."
        Enable-ScheduledTask -TaskName $nextTask -TaskPath "\" -Verbose
        Disable-ScheduledTask -TaskName $lastTask -TaskPath "\" -Verbose        

        # Run Sysprep unattended with Generalize option set
        Write-Host -ForegroundColor Black -BackgroundColor Yellow "IF SYSPREP RESTART FAILS THEN MANUALLY RESTART"
        Start-Process -FilePath $sysprepPath -ArgumentList $sysprepArguments -Wait     
        Restart-Computer
        
    }
    else
    {
        "kbye"
    }
}

$timer.stop() 
