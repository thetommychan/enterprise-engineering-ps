# Logging
$logPath = "\\opnasi02\Server\Tom\scripts\logs\UPMv1.0\error_log.txt"
Start-Transcript $logPath -Append -IncludeInvocationHeader

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$adminPrompt = Read-Host -Prompt "Are you running as admin?"
if ($adminPrompt -ne 'y' -or $isAdmin -eq $True)
{
    Write-Host -ForegroundColor Black -BackgroundColor Green "Verified Admin"
}
else
{
    Write-Host -ForegroundColor White -BackgroundColor Red "This script requires admin permissions to run. Please sign in with your admin account and run again."
    break
}

# Common paths
$tomPath = "\\opnasi02\Server\Tom\"
$scriptsServerPath = "\\opnasi02\Server\Tom\scripts"
$pkgdest = "C:\Program Files\WindowsPowerShell\Modules\PackageManagement"
$psgdest = "C:\Program Files\WindowsPowerShell\Modules\PowerShellGet"
$house = "C:\Windows\System32"
$psrepo = "C:\Users\$env:UserName\AppData\Local\Microsoft\Windows\PowerShell\PowerShellGet"
$repoSce = "\\opnasi02\server\Tom\ps-packages\psget\2.2.5\PSRepositories.xml"
$ps5Profile = "C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1"
$psISEProfile = "C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShellISE_profile.ps1"
$ps5pbackup = "\\opnasi02\server\Tom\scripts\logs\backups\Powershell5 Profiles"
$psISEpbackup = "\\opnasi02\server\Tom\scripts\logs\backups\PowershellISE Profiles"

# Function to copy files and unblock them
function Copy-FilesAndUnblock
{
    param (
        [string]$source,
        [string]$destination
    )

    if (Test-Path "\\opnasi02\Server\Tom\scripts")
    {
        Copy-Item $source $destination -Recurse -Verbose
        Get-ChildItem $destination -Recurse | Unblock-File -Verbose
        Write-Host -ForegroundColor Black -BackgroundColor Green "Package Management files unblocked and copied from source"
    }
    else
    {
        Write-Host "The source is unreachable. Source is $source."
    }
}

# Update Module
function Update-Modules
{
    param (
        [string]$moduleName,
        [string]$pkgSource,
        [string]$destPath
    )
    $testver = Get-Module -ListAvailable | Where-Object {$_.Name -eq "$moduleName"} | Select-Object Version -ExpandProperty Version | Select-Object Minor -ExpandProperty Minor
    if (!($testver -gt 0))
    {
        Set-Location $destPath -Verbose
        Copy-FilesAndUnblock -source $pkgSource -destination $destPath
        Set-Location $house -Verbose
    }
    else
    {
        Write-Host -ForegroundColor Black -BackgroundColor Green "$moduleName is already updated"
    }
}

# Update PackageManagement and PowerShellGet Modules
Update-Modules -moduleName "PackageManagement" -pkgSource "$tomPath\ps-packages\packagemanagement\1.4.8.1" -destPath $pkgdest
Update-Modules -moduleName "PowerShellGet" -pkgSource "$tomPath\ps-packages\psget\2.2.5" -destPath $psgdest

# Update PowerShell profiles
function Update-Profile
{
    param (
        [string]$profilePath,
        [string]$backupPath,
        [string]$newProfilePath,
        [string]$profileName
    )
    
        $newestBackup = Get-ChildItem $backupPath | Sort-Object LastWriteTime | Select-Object -Last 1 | Select-Object -Property Name -ExpandProperty Name
        $backupName = "${userid}_$(Get-Date -UFormat %d-%m-%Y-%H.%M.%S)_$newestBackup.ps1"
    if (!(Test-Path $profilePath))
    {
        # Create Powershell Profiles
        New-Item -ItemType File -Name "Microsoft.PowerShell_profile.ps1" -Path "C:\Windows\System32\WindowsPowerShell\v1.0\" -Force
        New-Item -ItemType File -Name "Microsoft.PowerShellISE_profile.ps1" -Path "C:\Windows\System32\WindowsPowerShell\v1.0\" -Force
        if (!(Test-Path $backupPath))
        {
            New-Item -ItemType Directory -Path $backupPath
            Copy-Item $profilePath $backupPath -Verbose | Out-Null            
            Rename-Item "$backupPath\$newestBackup" -NewName $backupName -Force
            Copy-Item $newProfilePath $profilePath -Force -Verbose
            Write-Host "New $profileName profile imported, and backup created and stored in $backupPath"
        }
        else
        {
            Copy-Item $profilePath $backupPath -Verbose | Out-Null
            Rename-Item "$backupPath\$newestBackup" -NewName $backupName -Force
            Copy-Item $newProfilePath $profilePath -Force -Verbose
            Write-Host "New $profileName profile imported, and backup created and stored in $backupPath"
        }
    }
    else
    {
        if (!(Test-Path $backupPath))
        {
            New-Item -ItemType Directory -Path $backupPath
            Copy-Item $profilePath $backupPath -Verbose | Out-Null            
            Rename-Item "$backupPath\$newestBackup" -NewName $backupName -Force
            Copy-Item $newProfilePath $profilePath -Force -Verbose
            Write-Host "New $profileName profile imported, and backup created and stored in $backupPath"
        }
        else
        {
            Copy-Item $profilePath $backupPath -Verbose | Out-Null
            Rename-Item "$backupPath\$newestBackup" -NewName $backupName -Force
            Copy-Item $newProfilePath $profilePath -Force -Verbose
            Write-Host "New $profileName profile imported, and backup created and stored in $backupPath"
        }
    }
}

$askForProfile = Read-Host -Prompt "Would you like to update your profile? (y/n)"

# Prompt user
if ($askForProfile -eq "y")
{
Update-Profile -profilePath $ps5Profile -backupPath $ps5pbackup -newProfilePath "$scriptsServerPath\Microsoft.PowerShell_profile.ps1" -profileName "PS5 Profile"
Update-Profile -profilePath $psISEProfile -backupPath $psISEpbackup -newProfilePath "$scriptsServerPath\Microsoft.PowerShellISE_profile.ps1" -profileName "PSISE Profile"
}
else
{
    Write-Host -ForegroundColor Black -BackgroundColor White "Skipping profile update..."
}

# Verify and update PSRepo directory
function Update-Repository
{
    param (
        [string]$RepositorySource,
        [string]$RepositoryDestination
    )
    if (!(Test-Path $psrepo\PSRepositories.xml))
    {
        $testRepo = Test-Path "$psrepo\PSRepositories.xml" -ErrorAction SilentlyContinue
        if (!($testRepo))
        {
            Write-Host -ForegroundColor Black -BackgroundColor Green "Creating Directory"
            Set-Location "C:\Users\$env:UserName\AppData\Local\Microsoft\Windows\PowerShell" -Verbose
            New-Item -ItemType Directory "PowerShellGet" -Force -Verbose
            Copy-Item $RepositorySource $RepositoryDestination -Force -Verbose
        }
        else
        {
            Write-Host -ForegroundColor Black -BackgroundColor White "Directory Exists, skipping create..."
        }
    }

    else
    {
        Write-Host -ForegroundColor Black -BackgroundColor Green "Updating PowerShell Repository"
        Copy-Item $RepositorySource $RepositoryDestination -Force -Verbose
        Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -Verbose
        Write-Host -ForegroundColor Black -BackgroundColor Green "PowerShell Gallery added as Trusted"
    }
} 


# Prompt to update local repository connection

$psrepo = "C:\Users\$env:UserName\AppData\Local\Microsoft\Windows\PowerShell\PowerShellGet"
    $repoSce = "\\opnasi02\server\Tom\ps-packages\psget\2.2.5\PSRepositories.xml"
$askForRepo = Read-Host -Prompt "Would you like to update your PowerShell Repository? (y/n)"
if ($askForRepo -eq "y")
{
    Update-Repository -RepositorySource $repoSce -RepositoryDestination $psRepo
}
else
{
    Write-Host -ForegroundColor Black -BackgroundColor White "Skipping Repository Update..."
}
# Reset location
Set-Location $house

Write-Host -ForegroundColor Black -BackgroundColor Green "Script output will be reported in the log file"
