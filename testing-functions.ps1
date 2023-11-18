function Remove-AppDataFolder
{ 
    {[boolean]$AppdataIsGood = $true
    Outputtext "STEP 2: Deleting Appdata folder `r"
    $redir = "\\upgf.com\DFS-UPGF\ctx_users\$Name\REDIR"
    $checkforappdata = Test-Path "$redir\appdata"
    if(!($checkforappdata))
        {
            OutputText "WARNING: APPDATA folder at \\upgf.com\DFS-UPGF\users\$Name\REDIR does not exist.`rThat may not necessarily be a problem. `r`r"
            $AppdataIsGood = $false
        }
    }  
}

# Load each .config file
[xml]$xmlDoc7 = Get-Content -Path '\\wpedia18\c$\Windows\Microsoft.NET\Framework\v4.0.30319\Config\UPGF\EDI_AppSettings_External.config'
$val7 = ($xmlDoc7.configuration.appSettings.add | Where-Object {$_.key -eq "machinetype"})

# Display current
Write-Host -BackgroundColor White -ForegroundColor Black "The last unit standup used the value"$val7.Value

# Prompt to enter the new FLSPlatformId value from the unit standup instructions
$newVal = Read-Host -Prompt "Enter the new value, or just hit Enter to bypass"
if ($newVal -gt '0') {

# Replace the current value of FLSPlatformId with the value entered in  the prompt
Write-Host "Updating..."
$val7.Value = "$newVal"

# Save the .config files with the new FLSPlatformId values
$xmlDoc7.Save('loadstep7 filepath.config')


Unregister-ScheduledTask -TaskName $schedtask -confrim:$false


function Get-XMLModule
{
    $exist = get-module -Name "xpath" -ErrorAction SilentlyContinue
    if (!($exist))
    {
        Install-Module -Name xpath;
        Import-Module -Name xpath;
        Write-Host -ForegroundColor Black -BackgroundColor Green "XML Module Successfully installed"
    }
        else
    {
        Write-Host -ForegroundColor Black -BackgroundColor Green "Module already installed, skipping..."
    }
}