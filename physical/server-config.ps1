# Configure Proxy Settings
function Set-ProxySite
{
    $askProxy = Read-Host -Prompt "Configure proxy settings? (y/n)"
    if ($askProxy -eq 'y')
    {
        $proxEnable = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' | Select-Object ProxyEnable -ExpandProperty ProxyEnable
        if ($proxEnable -eq 0)
        {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value "proxy.upgf.com:8080"
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value "<local>"
            Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
            Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' | Select-Object ProxyEnable, ProxyServer, ProxyOverride, AutoConfigURL
            Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Proxy Settings Updated"
        }
            else
        {
            Write-Host -ForegroundColor Black -BackgroundColor DarkBlue "Proxy Settings already set. If this is not right, change them manually."
            Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' | Select-Object ProxyEnable, ProxyServer, ProxyOverride, AutoConfigURL
        }
    }
        else
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Not configuring proxy settings..."
    }
}

# Install NETfx
function Get-NETFx
{
    $askNetFx = Read-Host -Prompt "Install .NET dependencies from ISO file? (y/n)"
    if ($askNetFx -eq 'y')
    {
        #Import-Module servermanager;
        $svrmgr = Get-Process | Where-Object {$_.Name -eq "ServerManager"}
        if ($svrmgr)
        {
            Write-Host "Closing Server Manager..."
            $svrmgr | Stop-Process
        }
            else
        {
            Write-Host "Server Manager is not running, no action needed."
        }
        # Check .NET
        $dotNetCheck =  get-windowsfeature Web-Server
        $cd = Get-Volume | Where-Object {$_.DriveType -eq "CD-ROM"}
        if (!($dotNetCheck.InstallState -eq "Installed"))
        {
            if (!($cd))
            {
	        $dL = $cd.DriveLetter
                Read-Host -Prompt "MOUNT SERVER ISO AND PRESS ENTER TO CONTINUE...";
                Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Installing .NETfx3..."
                Copy-Item "${dL}:\Sources\sxs" "C:\UPGF\.NETfx" -Force -Recurse | Out-Null
                Install-WindowsFeature -Name NET-Framework-Core -Source "C:\upgf\.NETfx"
                Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Configure Server Roles as needed, and close Server Manager when done.";
                Start-Sleep -Seconds 3;
                Start-Process -FilePath "C:\Windows\system32\ServerManager.exe" -Wait;
            }
            else
            {
	        $dL = $cd.DriveLetter
                Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Virtual media is insterted, installing .NETfx3..."
                Copy-Item "${dL}:\Sources\sxs" "C:\UPGF\.NETfx" -Force -Recurse | Out-Null
                Install-WindowsFeature -Name NET-Framework-Core -Source "C:\upgf\.NETfx"
                Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Configure Server Roles as needed, and close Server Manager when done.";
                Start-Sleep -Seconds 3;
                Start-Process -FilePath "C:\Windows\system32\ServerManager.exe" -Wait;
            }
        }
        else
        {
            Write-Host -ForegroundColor White -BackgroundColor DarkBlue ".NETfx3 is already installed..."
        }
    }
        else
    {
        Write-Host -ForegroundColor White -BackgroundColor DarkBlue "Not installing .NET Dependencies..."
    }
}

# Modules
<#$iisMod = Get-Module -Name "IISAdministration"
if (!($iisMod))
{
    Install-Module iisadministration
}

Import-Module IISAdministration
#>

# Stop Nagios Service
function Stop-NagiosService
{
    $status = "Stopped"
    $service = Get-Service -Name "NSCP"
    $stopNagios = $service | Stop-Service -Verbose;
    $service.WaitForStatus($status, '00:00:15');
}

# Get good Nagios config from another server
function Get-NagiosFix
{
    $newNagios = '\\WQPNDW22\c$\Program Files\NSClient++'
    Stop-NagiosService
    $service = Get-Service -Name "NSCP"
    if ($service.Status -eq "Stopped")
    {
        if (Test-Path $newNagios)
        {
            Copy-Item $newNagios 'C:\Program Files\' -Force -Recurse
            if ($?)
            {
                Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Nagios Client Updated on local machine..."
            }
                else
            {
                Write-Host -ForegroundColor Red -BackgroundColor DarkBlue "There was an issue copying... Ensure Nagios service is stopped and copy the Program Files\NSClient++ folder from WQPNDW22."
            }
        }
    }
        else
    {
        Write-Host -ForegroundColor Red -BackgroundColor DarkBlue "There was an issue stopping the Nagios Service..."
    }
}
# Install Nagios
function Get-Nagios
{
    $askNagios = Read-Host -Prompt "Install Nagios? (y/n)"
    if ($askNagios -eq 'y')
    {
        $nagiosService = Get-Service | Where-Object {$_.Name -like "NSCP*"}
        If (!($nagiosService))
        {
            Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing Nagios..."
            Copy-Item "\\opnasi01\software\Server\Downloaded Software\Nagios\Upgrade\Nagios Upgrade (S.O).ps1" "C:\upgf\" | Out-Null;
            Rename-Item 'C:\upgf\Nagios Upgrade (S.O).ps1' 'nagios-upgrade.ps1';
            $installNagios = Invoke-Expression -Command 'C:\upgf\nagios-upgrade.ps1'
            if ($installNagios)
            {
                Get-NagiosFix
            }
                else
            {
                Write-Host "There was an issue installing Nagios..."
            }

        }
        else
        {
            Write-Host -ForegroundColor White -BackgroundColor DarkBlue "Nagios is already installed..."
        }
    }
        else
    {
        Write-Host -ForegroundColor White -BackgroundColor DarkBlue "Not installing Nagios..."
    }
}

# Install SymantecAV
function Get-SymantecAV
{
    $askAv = Read-Host -Prompt "Install SymantecAV? (y/n)"
    if ($askAv -eq 'y')
    {
        If (!(Test-Path "C:\Program Files (x86)\Symantec"))
        {

            Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing Symantec AV..."
            Start-Process -Filepath '\\opnasi01\Software\Server\Downloaded Software\SymantecAV\14.3.7388.4000\setup.exe' -Wait;
        }
        else
        {
            Write-Host -ForegroundColor White -BackgroundColor DarkBlue "SymantecAV is already installed..."
        }
    }
        else
    {
        Write-Host -ForegroundColor White -BackgroundColor DarkBlue "Not installing SymantecAV..."
    }
}

# Install Dell OpenManage
function Get-OpenManage
{
    $askOm = Read-Host -Prompt "Install Dell OpenManage? (y/n)"
    if ($askOm -eq 'y')
    {
        If (!(Test-Path "C:\Program Files\Dell"))
        {

            Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing Dell OpenManage..."
            New-Item -ItemType Directory "C:\OpenManage";
            Copy-Item -Path "\\wqpndw21\c`$\OpenManage" -Destination "C:\" -Force -Recurse | Out-Null;
            Start-Process -Filepath 'C:\OpenManage\windows\setup.exe' -Wait;
        }
        else
        {
            Write-Host -ForegroundColor White -BackgroundColor DarkBlue "OpenManage is already installed..."
        }
    }
        else
    {
        Write-Host -ForegroundColor White -BackgroundColor DarkBlue "Not installing Dell OpenManage..."
    }
}

function Get-Ports
{
    Start-Process -FilePath "C:\Windows\System32\cmd.exe" -verb runas -ArgumentList {/c "C:\Program Files\EMC Networker\nsr\bin\nsrports" -S 7937-8103}
    if ($?)
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Ports registered Successfully"
    }
        else
    {
        Write-Host -ForegroundColor Yellow -BackgroundColor DarkBlue "There seemed to have been an issue. Run these from CMD to manually register ports:"
        Write-Host "CD C:\Program Files\EMC Networker\nsr\bin\ || nsrports -S 7937-8103"
    }
}

# Install EMC Networker
function Get-EMC
{
    $askEmc = Read-Host -Prompt "Install  EMC Networker? (y/n)"
    if ($askEmc -eq 'y')
    {
        $networker = "C:\Program Files\EMC Networker"
        If (!(Test-Path "$networker"))
        {
            Start-Process "\\opnasi02\server\tom\"
            Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing EMC Netorker..."
            Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Backup Server: lpnwki02.upgf.com"
            Start-Process -Filepath '\\opnasi02\server\Tom\Networker Install\NetWorker-19.7.0.1.exe' -Wait; 
            Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing Extended Networker Client"
            Start-Process -Filepath '\\opnasi02\server\Tom\Networker Install\lgtoxtdclnt-19.7.0.1' -Wait;
            Get-Ports              
        }
        else
        {
            Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "EMC Networker is already installed..."
        }

    }
        else
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Not installing Crowdstrike..."
    }
}


function Set-ScheduledBMR
{
    $checkSt = Get-ScheduledTask -TaskName "BMR" -ErrorAction SilentlyContinue
    if (!($checkSt))
    {
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 04:00
        $action = New-ScheduledTaskAction -Execute 'c:\Program Files\Cristie\NBMR\nbmrcfg.exe' -Argument '/format all'
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        Register-ScheduledTask -TaskName "BMR" -Trigger $trigger -Action $action -User "SYSTEM" -Force -Settings $settings -Verbose
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Scheduled task created:"
        $checkSt
    }
        else
    {
        Write-Host -ForegroundColor Yellow -BackgroundColor DarkBlue "Scheduled task already exists:"
        $checkSt
    }
}

# Copy files from share to local machine
function Get-CristieFiles
{
    $cwres = '\\opnasi02\server\Tom\Cristie Install\Cristie Program_Files\Cristie NSR Res files\CristieWindows.res'
    $group = '\\opnasi02\server\Tom\Cristie Install\Cristie Program_Files\Cristie NSR Res files\NetworkerGroupResCreate.bat'
    $cnfg = '\\opnasi02\server\Tom\Cristie Install\Cristie Program_Files\Cristie Windows files\cristienbmrcfg.bat'
    if (Test-Path $cnfg)
    {
        Copy-Item $cnfg 'C:\Windows\' -Force -Verbose | Out-Null;
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "File copied from share..."
    }
        else
    {
        Write-Host "Unable to reach $cnfg..."
    }
    if (Test-Path $cwres -and Test-Path $group)
    {
        Copy-Item $cwres 'C:\Program Files\EMC Networker\NSR\res\' -Verbose | Out-Null;
        Copy-Item $group 'C:\Program Files\EMC Networker\NSR\res\' -Verbose | Out-Null;
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Files copied from share..."
    }
        else
    {
        Write-Host "Unable to reach $cwres or $group..."
    }
}

function Get-CristieSetup
{
    Start-Process cmd -Verb RunAs -WorkingDirectory C:\UPGF -ArgumentList {/c SetupNBMRSuite822.exe /silent /ISFeatureInstall:NBMR /SuiteInstallDir=`"C:\Program Files\Cristie`" /debuglogC:\setup.log; nbmrcfg.exe /format all}
    if ($?)
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Ports registered Successfully"
    }
        else
    {
        Write-Host -ForegroundColor Yellow -BackgroundColor DarkBlue "There seemed to have been an issue. Run these from CMD to manually register ports:"
        Write-Host "CD C:\UPGF || SetupNBMRSuite822.exe /silent /ISFeatureInstall:NBMR /SuiteInstallDir=`"C:\Program Files\Cristie`" /debuglogC:\setup.log || nbmrcfg.exe /format all"
    }
}

# Install Cristie
function Get-Cristie
{
    $askCristie = Read-Host -Prompt "Install Cristie? (y/n)"
    if ($askCristie -eq 'y')
    {
        if (!(Test-Path "C:\Program Files\Cristie"))
        {
            $cristie = "\\opnasi01\software\Server\Downloaded Software\Cristie\Cristie\Cristie Program_Files\Install\SetupNBMRSuite822.exe"
            Copy-Item $cristie "C:\UPGF" -Verbose
            Get-CristieSetup
            Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Creating Scheduled Task..."
            Set-ScheduledBMR;
            Start-ScheduledTask -TaskName "BMR" -Verbose;
            Get-CristieFiles
        }
            else
        {
           Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Cristie is already installed..."
        }
    }
        else
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Not installing Cristie..."
    }
}

# Install Crowdstrike
function Get-Crowdstrike
{
    $askCs = Read-Host -Prompt "Install Crowdstrike? (y/n)"
    if ($askCs -eq 'y')
    {
        $crowdstrike = Get-Service | Where-Object {$_.Name -eq "CSFalconService"}
        If (!($crowdstrike))
        {
            Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Install Crowdstrike now from `"\\opnasi01\software\Server\Downloaded Software\CrowdStrike\CrowdStrike_UPS_Freight\CS Falcon Sensor Installation\InstCS_701_17311-tff.bat`"..."
            Start-Process -FilePath "cmd.exe" -Verb RunAs -Wait;
        }
        else
        {
            Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Crowdstrike is already installed..."
        }
    }
        else
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Not installing Crowdstrike..."
    }
}

# Install OCS Inventory
function Get-OCSInventory
{
    $askOcs = Read-Host -Prompt "Install OCS Inventory? (y/n)"
    if ($askOcs -eq 'y')
    {
        $oscinv = Get-Service | Where-Object {$_.Name -eq "OCS Inventory Service"}
        If (!($oscinv))
        {
            Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing OCS Inventory..."
            Start-Process -Filepath '\\opnasi02\server\scripts\ocs_local.bat ' -Wait;
        }
        else
        {
            Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "OCS Inventory is already installed..."
        }
    }
        else
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Not installing OCS Inventory..."
    }
}

# Install URL ReWrite Module for IIS
function Get-URLRewrite
{
    $askUrl = Read-Host -Prompt "Install URL Rewrite Module? (y/n)"
    if ($askUrl -eq 'y')
    {
    Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing URL ReWrite Module for IIS..."
    Start-Process -Filepath '\\opnasi01\Software\Server\Downloaded Software\URL_ReWrite\rewrite_amd64.msi' -Wait -ErrorAction SilentlyContinue;
    }
        else
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Not installing URL Rewrite Module..."
    }
}

# If the Oracle DataAccess file doesn't exist, copy from share
function Get-DataAccessFile
{
    $file = 'C:\Windows\Microsoft.NET\assembly\GAC_64\'
    if (!(Test-Path '$file\Oracle.DataAccess'))
    {
        copy-item -Path '\\opnasi02\server\Documents\PND\ECD\Oracle.DataAccess' -Destination $file -Force -Recurse
    }
    else
    {
        Write-Host 'Oracle.DataAccess file exists already...'
    }
}

# Install Oracle 19c
function Install-Oracle
{
    param(
        [Parameter(Mandatory)]
        [string]$Version
    )
    if ($Version -eq '19')
    {
        if (!(Test-Path "C:\oracle_64\product\19.0.0\client_1\bin"))
        {
            Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing Oracle 19c..."
            Invoke-Command -ScriptBlock {robocopy "\\opnasi01\Software\Server\Downloaded Software\Oracle\Oracle19\ODAC1931_x64" "C:\upgf" /S /E /Z /B /TEE /R:3 /W:3 /MT:8} -ErrorAction SilentlyContinue
            Write-Host -BackgroundColor DarkBlue -ForegroundColor Green "Oracle 19c copied successfully..."
            Start-Process -FilePath "C:\upgf\setup.exe" -Wait;
            Get-TNSNames;
            Get-DataAccessFile
        }
        else
        {
            Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Oracle 19C already installed..."
        }    
    }
    elseif ($Version -eq '12')
    {
        if (!(Test-Path "C:\oracle_64\product\12.1.0\client_1\bin"))
        {
            Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing Oracle 12c..."
            Invoke-Command -ScriptBlock {robocopy "\\opnasi01\software\server\Downloaded Software\Oracle\Oracle12c\winx64_12102_clientb\client" "C:\upgf" /S /E /Z /B /TEE /R:3 /W:3 /MT:8} -ErrorAction SilentlyContinue
            Write-Host -BackgroundColor DarkBlue -ForegroundColor Green "Oracle 12c copied successfully..."
            Start-Process -FilePath "C:\upgf\setup.exe" -Wait;
            Get-TNSNames;
            Write-Host -BackgroundColor DarkBlue -ForegroundColor Yellow "Don't forget to configure the ODBC Connections!"
        }
        else
        {
            Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Oracle 12C already installed..."
        } 
    }
        else
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Not installing Oracle..."
    }
}

# Install DB2 - QA Dependent
function Get-DB2
{
    $askdb2 = Read-Host -Prompt "Install DB2? (y/n)"
    if ($askdb2 -eq 'y')
    {
        Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing DB2 RunTime..."
        Start-Process -Filepath '\\opnasi01\software\Server\Downloaded Software\Db2\10.5_DataServerRuntime\v10.5fp11_ntx64_rtcl_EN.exe' -Wait;
        # Copy the license from the Share and register the server
        Invoke-Command -ScriptBlock {robocopy "\\WQPNDW22\c$\UPGF\" "C:\UPGF\" "db2consv_ee.lic"} | out-null
        Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Initiating DB2 Licensing..."
        Start-Process -FilePath "C:\Windows\System32\cmd.exe" -verb runas -ArgumentList {/c "C:\Program Files\IBM\SQLLIB\BIN\db2licm" -a C:\UPGF\db2consv_ee.lic}
        if ($?)
        {
            Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "License Registered Successfully"
        }
            else
        {
            Write-Host -ForegroundColor Yellow -BackgroundColor DarkBlue "There seemed to have been an issue. Run these from CMD to manually register license:"
            Write-Host "cd C:\Program Files\IBM\$sqllib\BIN || db2licm -a C:\UPGF\db2consv_ee.lic"
        }
    }
        else
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Not installing DB2..."
    }
}

# Install C++ Add-Ons
function Get-CPlus
{
    $askCplus = Read-Host -Prompt "Install C++ Add-Ons? (y/n)"
    if ($askCplus -eq 'y')
    {
        # Install Visual C++ 2010 Redistributable Package
        Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing Visual C++ 2010 Redis. Package..."
        Start-Process -Filepath '\\opnasi01\software\Server\Downloaded Software\Microsoft Visual C++ 2010 Redistributable Package\vcredist_x64.exe' -Wait;
        # Install Visual C++ 2013 Redistributable Package for Visual Studio
        Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing Visual C++ 2013 Redis. Package for Visual Studio..."
        Start-Process -Filepath '\\opnasi01\software\Server\Downloaded Software\Microsoft Visual C++ 2013 Redistributable _12.0.30501_for Visual Studio\vcredist_x64.exe' -Wait;
        # Install Visual C++ 2015-2019 Redistributable Package
        Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Installing Visual C++ 2015-2019 Redis. Package..."
        Start-Process -Filepath '\\opnasi01\software\Server\Downloaded Software\Microsoft Visual C++ 2015-2019 Redistributable_14.29.30040\VC_redist.x64.exe' -Wait;
    }
        else
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Not installing C++ Add-Ons..."
    }
}

# Copy tnsnames.ora file from another server
function Get-TNSNames # - QA Dependent
{
    $source = "\\opnasi02\server\Tom\scripts\WQPNDW2X\"
    if (Test-Path $source)
    {   
        if ($Version -eq "19")
        {
            Copy-Item "$source\tnsnames.ora" "C:\oracle_64\product\19.0.0\client_1\Network\Admin\" -Verbose -Force
        }
        elseif ($Version -eq "12")
        {
            Copy-Item "$source\tnsnames.ora" "C:\oracle_64\product\12.1.0\client_1\Network\Admin\" -Verbose -Force
        }
        else
        {
            write-host "nope"
        }
        
    }
        else
    {
        Write-Host -ForegroundColor Black -BackgroundColor Red "The source file at $source is unavailable..."
    }
}

# Create the System DSN for Q009
function Get-ODBC # - QA Dependent
{
    $askodbc = Read-Host -Prompt "Configure ODBC Connections? (y/n)"
    if ($askodbc -eq 'y')
    {
        Write-Host -ForegroundColor White "Create System DSN for [e]009"
        Start-Process -Filepath 'c:\windows\System32\odbcad32.exe' -Wait;
    }
        else
    {
        Write-Host -ForegroundColor Green "Not configuring ODBC Connections..."
    }
}

# Start Patching
function Get-Patch
{
    $askPatch = Read-Host -Prompt "Patch? (y/n)"
    if ($askPatch -eq 'y')
    {
        Write-Host -BackgroundColor DarkBlue -ForegroundColor White "Beginning System Patches..."
        Start-Process -Filepath \\opnasi02\server\patches\mspatches\rlocalpatch.bat -Wait;
    }
        else
    {
        Write-Host -ForegroundColor Green -BackgroundColor DarkBlue "Not pathcing..."
    }
}

function Show-MainMenu
{
$homeMenuOptions = @"
Home Menu:
$masterPrompt
1. Set Proxy Settings (Beta)
2. Install .NET Dependencies from ISO
3. Install Nagios
4. Install Symantec AV
5. Install Dell OpenManage
6. Install Crowdstrike
7. Install OCS Inventory
8. Install URL Rewrite Module
9. Install Oracle [12c/19c]
10. Install DB2
11. Install C++ Dependencies
12. Configure ODBC Settings for Oracle
13. Patch
14. Install EMC Networker
15. Install Cristie
16. Send It
17. Exit
"@
Write-Host $homeMenuOptions
$choice = Read-Host "Enter the number of the function you need to perform"

switch ($choice) {
    "1" {
        # Code for Option 1
        Write-Host -BackgroundColor DarkBlue -ForegroundColor Yellow "This Feature isn't quite ready yet..."
        #Set-ProxySite;
        Show-MainMenu
    }
    "2" {
        # Code for Option 2
        Get-NETFx;
        Show-MainMenu
    }
    "3" {
        # Code for Option 3
        Get-Nagios;
        Show-MainMenu
    }
    "4" {
        # Code for Option 4
        Get-SymantecAV;
        Show-MainMenu
    }
    "5" {
        # Code for Option 5
        Get-OpenManage;
        Show-MainMenu
    }
    "6" {
        # Code for Option 6
        Get-Crowdstrike;
        Show-MainMenu
    }
    "7" {
        # Code for Option 7
        Get-OCSInventory;
        Show-MainMenu
    }
    "8" {
        # Code for Option 8
        Get-URLRewrite;
        Show-MainMenu
    }
    "9" {
        # Code for Option 9
        Install-Oracle;
        Show-MainMenu
    }
    "10" {
        # Code for Option 10
        Get-DB2;
        Show-MainMenu
    }
    "11" {
        # Code for Option 11
        Get-CPlus;
        Show-MainMenu
    }
    "12" {
        # Code for Option 12
        Get-ODBC;
        Show-MainMenu
    }
    "13" {
        # Code for Option 13
        Get-Patch;
        Show-MainMenu
    }
    "14" {
        # Code for Option 14
        Get-EMC;
        Show-MainMenu
    }
    "15" {
        # Code for Option 15
        Get-Cristie;
        Show-MainMenu
    }
    "16" {
        # Code for Option 16
        Get-NETFx;
        Get-Nagios;
        Get-SymantecAV;
        Get-OpenManage;
        Get-Crowdstrike;
        Get-OCSInventory;
        Get-URLRewrite;
        Install-Oracle;
        Get-DB2;
        Get-CPlus;
        Get-ODBC;
        Get-EMC;
        Get-Cristie;
        Get-Patch
    }
    "17" {
        # Code for Option 17
        break
    }
    default {
        Write-Host "Invalid choice. Please select a valid option.";
        Show-MainMenu
    }
} 
} Show-MainMenu
