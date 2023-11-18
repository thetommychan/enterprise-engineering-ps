# Run this script when the server has been connected to the network
$sysprepPath = "C:\Windows\System32\Sysprep\sysprep.exe"
$sysprepArguments = "/generalize /oobe /reboot /unattend"
# Define the name of the scheduled task
$nextTask = "Configure Script 2"
$lastTask = "Config Script 1"

# Timeout duration in seconds
$timeout_duration = 30

# Function to get user input with a timeout
function Get-UserInputWithTimeout {
    param(
        [string]$prompt,
        [string[]]$validOptions,
        [int]$timeoutSeconds
    )

    $timeout = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        $userInput = Read-Host -Prompt $prompt
        if ($validOptions -contains $userInput) {
            return $userInput
        }

        if ($timeout.Elapsed.TotalSeconds -ge $timeoutSeconds) {
            return $null
        }
    } while ($true)
}

# Ask the user for input with a timeout
$userResponse = Get-UserInputWithTimeout -prompt "Generalize? (y/n)" -validOptions @('y', 'n') -timeoutSeconds $timeout_duration

if ($userResponse -eq 'y') {
    # Modify scheduled tasks
    Write-Host -ForegroundColor Black -BackgroundColor White "Modifying Scheduled Tasks..."
    Enable-ScheduledTask -TaskName $nextTask -TaskPath "\" -Verbose
    Disable-ScheduledTask -TaskName $lastTask -TaskPath "\" -Verbose        

    # Run Sysprep unattended with Generalize option set
    Write-Host -ForegroundColor Black -BackgroundColor Yellow "IF SYSPREP RESTART FAILS THEN MANUALLY RESTART"
    Start-Process -FilePath $sysprepPath -ArgumentList $sysprepArguments -Wait     
    Restart-Computer
} else {
    "kbye"
}

