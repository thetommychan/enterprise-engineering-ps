param(
    [string]$SourceServer,
    [string]$DestServer
    )

function Get-PhysicalSiteFiles
    {
        param(
            [string]$Source,
            [string]$SiteDirectory,
            [switch]$DirOption,
            [switch]$Physical
        )
        # $cred = Get-Credential
        if ((Test-Path "\\$SourceServer\c$\inetpub\$Source") -and (!($DirOption)) -and (!($Physical)))
        {
            Invoke-Command -ScriptBlock {robocopy \\$sourceServer\c$\inetpub\$Source \\$DestServer\c$\inetpub\$Source /S /E /Z /B /TEE /R:3 /W:3 /MT:8}
        }
        elseif ((Test-Path "\\$SourceServer\c$\inetpub\$Source") -and $DirOption -and (!($Physical)))
        {
            Invoke-Command -ScriptBlock {robocopy \\$sourceServer\c$\inetpub\$SiteDirectory \\$DestServer\c$\inetpub\$SiteDirectory /S /E /Z /B /TEE /R:3 /W:3 /MT:8}
        }
        elseif ((Test-Path "\\$SourceServer\c$\inetpub\$Source") -and $Physical) # getting access denied FIX
        {
            if (!(Test-Path \\opnasi02\server\tom\sites\$SourceServer\$Source))
            {
                New-Item -ItemType Directory -Path "\\opnasi02\server\tom\sites\" -Name "$sourceServer" -Force -ErrorAction SilentlyContinue | Out-Null
                New-Item -ItemType Directory -Path "\\opnasi02\server\tom\sites\$SourceServer" -Name "$Source" -Force -ErrorAction SilentlyContinue | Out-Null
                Invoke-Command -ScriptBlock {robocopy c:\inetpub\$Source \\opnasi02\server\tom\sites\$sourceServer\$Source /S /E /Z /B /TEE /R:3 /W:3 /MT:8}
            }
            else
            {
                Invoke-Command -ScriptBlock {robocopy c:\inetpub\$Source \\opnasi02\server\tom\sites\$sourceServer\ /S /E /Z /B /TEE /R:3 /W:3 /MT:8}
            }
        }
        else
        {
            Write-Host -ForegroundColor White -BackgroundColor DarkGray "No $Source Application on Source, nothing to copy."
        }
    } 

        function Get-DeliveryMethod
    {
        # Check if VMware Tools is installed
        Get-ItemProperty -Path 'HKLM:\SOFTWARE\VMware, Inc.\VMware Tools' -ErrorAction SilentlyContinue

        if ($null -ne $vmCheck)
        {
            Write-Host "This server is running on VMware."
            $true
        }
        else
        {
            Write-Host "This server is not running on VMware."
            $false
        }
    }

    $result = Get-DeliveryMethod
    if ($result -eq $false)
    {
        Get-PhysicalSiteFiles -Source SysCtrBeta -Physical;
        Get-PhysicalSiteFiles -Source wwwroot -Physical;
        Get-PhysicalSiteFiles -Source DockWalk.API -Physical;
        Get-PhysicalSiteFiles -Source DockWalk.API_Beta -Physical;
        Get-PhysicalSiteFiles -Source ws_blue -Physical;
        Get-PhysicalSiteFiles -Source ws_green -Physical;
        Get-PhysicalSiteFiles -Source ws_beta -Physical;
        Get-PhysicalSiteFiles -Source ws -Physical;
        Get-PhysicalSiteFiles -Source DockWalk.Web -Physical;
        Get-PhysicalSiteFiles -Source DockWalk.web_Beta -Physical;
        Get-PhysicalSiteFiles -Source ECDMgmtPortal -DirOption -SiteDirectory wwwrootMgmt -Physical
    }
    else
    {
        Get-PhysicalSiteFiles -Source wwwroot;
        Get-PhysicalSiteFiles -Source DockWalk.API;
        Get-PhysicalSiteFiles -Source DockWalk.API_Beta;
        Get-PhysicalSiteFiles -Source ws_blue;
        Get-PhysicalSiteFiles -Source ws_green;
        Get-PhysicalSiteFiles -Source ws_beta;
        Get-PhysicalSiteFiles -Source ws;
        Get-PhysicalSiteFiles -Source DockWalk.Web;
        Get-PhysicalSiteFiles -Source DockWalk.web_Beta;
        Get-PhysicalSiteFiles -Source ECDMgmtPortal -DirOption -SiteDirectory wwwrootMgmt
    }