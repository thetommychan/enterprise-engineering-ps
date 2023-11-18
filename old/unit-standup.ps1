# Unit Standup Automation
# 1. Right-click the fls-unit-standup powershell script and click 'Run with PowerShell'
# 2. Read the 3 banner messages at the top of the ps window
# 3. Type the new value that is being applied to the key per the unit standup instructions and press Enter
# 4. The script updates and saves the config files
# 5. type y and press Enter to view the first 15 lines of each config file to ensure they were updated appropriately
# 6. UAC Window appears asking for admin priviliges to run the first config step: Click yes and let the first step run
# 7. After the first step is finished running, a new UAC window will appear asking for admin rights to run the next 
#    step. This will happen 5 times, allowing initial load steps 1, 2, 3, 4, and 7 to run in order to complete the unit 
#    standup.
#    IF A UAC WINDOW IS MISSED, CANCEL THE REST OF THE OPERATION AND START OVER. Values should not need to be re-enetered 
#    if the integration steps were already started.

# Load each .config file
[xml]$xmlDoc7 = Get-Content -Path 'loadstep7 filepath.config'
$val7 = ($xmlDoc7.configuration.appSettings.add | Where-Object {$_.key -eq "key"})
[xml]$xmlDoc4 = Get-Content -Path 'loadstep4 filepath.config'
$val4 = ($xmlDoc4.configuration.appSettings.add | Where-Object {$_.key -eq "key"})
[xml]$xmlDoc3 = Get-Content -Path 'loadstep3 filepath.config'
$val3 = ($xmlDoc3.configuration.appSettings.add | Where-Object {$_.key -eq "key"})
[xml]$xmlDoc2 = Get-Content -Path 'loadstep2 filepath.config'
$val2 = ($xmlDoc2.configuration.appSettings.add | Where-Object {$_.key -eq "key"})
[xml]$xmlDoc1 = Get-Content -Path 'loadstep1 filepath.config'
$val1 = ($xmlDoc1.configuration.appSettings.add | Where-Object {$_.key -eq "key"})

# Displays the last FLSPlatformId value used in the most recent unit standup
Write-Host -BackgroundColor White -ForegroundColor Black "The last unit standup used the value"$val7.Value
Write-Host -BackgroundColor Yellow -ForegroundColor Black "IF ANY ERRORS ARE ENCOUNTERED WHILE THIS SCRIPT IS BEING RUN, `nSCREENSHOT OR NOTATE TO THE BEST OF YOUR ABILITY AND NOTIFY TOM CHANDLER"

# Prompt to enter the new FLSPlatformId value from the unit standup instructions
$newVal = Read-Host -Prompt "Enter the new value, or just hit Enter to bypass"
if ($newVal -gt '0') {
Write-Host "Updating..."

# Replace the current value of FLSPlatformId with the value entered in  the prompt
$val7.Value = "$newVal"
$val4.Value = "$newVal"
$val3.Value = "$newVal"
$val2.Value = "$newVal"
$val1.Value = "$newVal"

# Save the .config files with the new FLSPlatformId values
Write-Host "Saving..."

$xmlDoc7.Save('loadstep7 filepath.config')
$xmlDoc4.Save('loadstep4 filepath.config')
$xmlDoc3.Save('loadstep3 filepath.config')
$xmlDoc2.Save('loadstep2 filepath.config')
$xmlDoc1.Save('loadstep1 filepath.config')

Write-Host "Done!"

 }
# Verify the new value was saved to the .config files correctly
$verify = Read-Host -Prompt "Visually confirm current values?(y/n)"
if ($verify -eq 'y') {
    
    Write-Host -BackgroundColor Yellow -ForegroundColor Black "Initial Load Step 7" 
    Get-Content -Path 'loadstep7 filepath.config' -TotalCount 15 
    Write-Host -BackgroundColor Yellow -ForegroundColor Black "Initial Load Step 4"
    Get-Content -Path 'loadstep4 filepath.config' -TotalCount 15
    Write-Host -BackgroundColor Yellow -ForegroundColor Black "Initial Load Step 3"
    Get-Content -Path 'loadstep3 filepath.config' -TotalCount 15
    Write-Host -BackgroundColor Yellow -ForegroundColor Black "Initial Load Step 2"
    Get-Content -Path 'loadstep2 filepath.config' -TotalCount 15
    Write-Host -BackgroundColor Yellow -ForegroundColor Black "Initial Load Step 1"
    Get-Content -Path 'loadstep1 filepath.config' -TotalCount 15

}
$unitStandup = Read-Host -Prompt "Press y to continue with running the integration steps, or press Enter to finish now."
if ($unitStandup -eq 'y') {

# Run the unit standup in order of 1, 2, 3, 4, 7

Start-Process -FilePath 'loadstep7 filepath.config' -Verb RunAs -Wait -ErrorAction Inquire
Start-Process -FilePath 'loadstep4 filepath.config' -Verb RunAs -Wait -ErrorAction Inquire
Start-Process -FilePath 'loadstep3 filepath.config' -Verb RunAs -Wait -ErrorAction Inquire
Start-Process -FilePath 'loadstep2 filepath.config' -Verb RunAs -Wait -ErrorAction Inquire
Start-Process -FilePath 'loadstep1 filepath.config' -Verb RunAs -ErrorAction Inquire
Read-Host -Prompt "Unit Standup is complete. Verify with development that the standup was successful. `nIf the standup was not successful, run again MANUALLY according to unit standup instructions `nand ping Tom on Teams to inform of malfunction. `nPress Enter to exit..."
} else {

Write-Host -BackgroundColor Yellow -ForegroundColor Black "The unit standup has not been performed.`nIf you encountered an error or something did not work as expected, please notify Tom Chandler.
`n This window will close in approx. 30 seconds."
Start-Sleep -Seconds 30

}