<#
.SYNOPSIS
    The purposes of this script is to copy and configure an existing IIS 
    site to a new server from an existing server in support of upgrading or 
    migratory efforts. The script collects 3 parameters from the user:
    1.  Scope; Import Site/Config to the Destination server, Export 
        Site/Config from the Source Server, Migrate (export from source and import 
        to destination), or Restart IIS. 
    2.  SourceServer; the server from which the IIS site will be migrated.
    3.  DestinationServer; the server to which the iis site will be migrated.
    3.  Restart; Restart IIS on a given server name.

.DESCRIPTION
    Run this script by calling it with at least 2 of the named parameters. Scope is required, and either/both Source/Destination will be inadvertently required next. 
    The intention of this script is to make IIS Site migration simple and quick. With the Export scope, the IIS apppool/site configurations of the target server are exported
    to the local machine as XML files. Next, the XML files are parsed, cleaning up any mistakes that may have been made in export and preparing them for import to their new home.
    Then, the inetpub folder of the target server is copied to a share. If the server has an FTP Site that isn't found in inetpub, this script will miss that directory.
    
    With the Import scope, the target IIS Site is stopped and the IIS apppool/site configuration XMLs are moved from the local machine to the target server. Then, the physical site files are moved from 
    the Import-defined share directory to the server. After the physical site files are moved and the XMLs are copied, psexec runs locally on the target server with an argument
    to import the XML configurations on the target server's IIS Manager. Then, the IIS Site is restarted and a reminder is posted about the IIS Certificate for any sites using SSL.

.PARAMETER Scope
    The SCOPE parameter accepts 3 inputs: Import, Export, and Migrate. When performing any operation, designate the target server approperiately:
    If Import, use Destination
    If Export, use Source
    If Migrate, use Source and Destination

.PARAMETER SourceServer
    The SOURCESERVER is the server from which the IIS Site configuration will be copied or moved. All sites, app pools, settings, etc. will be copied.

.PARAMETER DestinationServer
    The DestinationServer is the server to which the IIS Site configuration will be copied or moved. The Default Site and Default App Pools will remain in tact, and the imported 

.EXAMPLE
    .\iis-mig-tool -Scope Import -DestinationServer ServerB
    This will import the saved configuration from the Server Share if it's present. 
    If it's not present, a message will be displayed: 
    "No source to import from. Please Run 'iis-mig-tool.ps1 -Scope Export -SourceServer <Server Name>' to create a valid configuration to import."

.EXAMPLE
    .\iis-mig-tool -Scope Migrate -SourceServer ServerA -DestinationServer ServerB
    This will migrate the IIS Site configuration from ServerA to ServerB. 
    

.NOTES
    Author: Tom Chandler
    Version: 1.0
    Date: 11/27/2023
#>

param(
    [CmdletBinding()]
    [Parameter(Mandatory = $true, Position = 0, HelpMessage="The Scope defines the action that this script will take against the other named parameters.")]
    [ValidateSet("Import", "Export", "Migrate", "Restart")]
    [string]$Scope,                             # Export site configuration and files from source server and import to new server
    [Parameter(Position=1, HelpMessage="The SourceServer parameter defines the server from which the IIS Site will either be exported or migrated from.")]
    [string]$SourceServer,                      # Source server is the server the configuration is being coped from, ideally identical to the server that's being provisioned
    [Parameter(Position=2, HelpMessage="The DestinationServer parameter defines the server to which the IIS Site will either be imported or migrated to.")]
    [string]$DestinationServer                  # Destination server is the destination the configuration is being copied to, namely the new server.
)

##############################################
################ Logging #####################
##############################################
# try 
# {
#     $logPath = "\\opnasi02\server\tom\scripts\logs\iis"
#     $logDir = Get-Date -Format "yyyy.MMM"
#     $deploymentLog = "iis-migration.$((Get-Date).ToString('yyyy.MM.dd'))"
#     if (Test-Path $logPath\$logDir)
#     {
#         Start-Transcript -Path $logPath\$logDir\$deploymentLog.log -Append
#     }
#     elseif (!(Test-Path $logPath\$logDir))
#     {
#         New-Item -Path $logPath -ItemType Directory -Name $logDir
#         Start-Transcript -Path $logPath\$logDir\$deploymentLog.log -Append
    # }
##############################################
################ Logging #####################
##############################################

    $Global:share = "\\opnasi02\server\tom\sites"
    # Not working, not enough patience
    function Export-ServerCert
    {
        param(
            [string]$SiteName,
            [string]$ExportPath
        )

        # Get the newest certificate for the specified site
        $certificate = Get-ChildItem -Path Cert:\LocalMachine\My | 
            Where-Object { $_.EnhancedKeyUsageList.FriendlyName -contains "Server Authentication" } |
            Sort-Object NotAfter -Descending |
            Select-Object -First 1

        if ($certificate) {
            # Export the certificate to a PFX file
            $password = ConvertTo-SecureString -String "g0f15h!" -Force -AsPlainText
            Export-PfxCertificate -Cert $certificate -FilePath $exportPath -Password $password

            Write-Host -ForegroundColor Green "Certificate exported to $exportPath."
        } else {
            Write-Host -ForegroundColor Yellow "Certificate not found for site $siteName."
        }
    }

    # Export the IIS Site from the Source server in XML format to your local machine
    function Export-IISSites
    {
        [CmdletBinding()]
        param(
            [string]$SourceServer
        )
        Write-Host -ForegroundColor Yellow "Attempting to export websites"
        Invoke-Command -ComputerName $SourceServer -ScriptBlock {& $Env:Windir\system32\inetsrv\appcmd.exe list site /config /xml} -ErrorAction SilentlyContinue | Out-File c:\upgf\websites.xml -Force | Out-Null;
        if ($?)
        {
            Write-Host -ForegroundColor Green "Websites exported successfully"
        }
        else
        {
            Write-Host -ForegroundColor Red "Websites not exported..."
            Write-Output $error[0]
        }
    }

    # Export the IIS App Pools from the Source server in XML format to your local machine
    function Export-AppPools
    {
        [CmdletBinding()]
        param(
            [string]$SourceServer
        )

        Write-Host -ForegroundColor Yellow "Attempting to copy app pools"
        Invoke-Command -ComputerName $SourceServer -ScriptBlock {& $Env:Windir\system32\inetsrv\appcmd.exe list apppool /config /xml} -ErrorAction SilentlyContinue | Out-File c:\upgf\apppools.xml -Force | Out-Null;
        if ($?)
        {
            Write-Host -ForegroundColor Green "AppPools exported successfully"
        }
        else
        {
            Write-Host -ForegroundColor Red "AppPools not exported..."
            Write-Output $error[0]
        }
    }

    # Add the NBCH100 service account to the Local Admin group
    function Set-LocalAdmin
    {
        [CmdletBinding()]
        param(
            [string]$SourceServer,
            [string]$DestinationServer
        )
        Write-Host -ForegroundColor Yellow "Attempting to add NBCH100 service account to Local Administrators group on $DestinationServer"
        Invoke-Command -ComputerName $DestinationServer -ScriptBlock {Get-LocalGroupMember -Group Administrators -Member NBCH100 -ErrorAction SilentlyContinue}
        if ($?)
        {
            Write-Host -ForegroundColor White "NBCH100 Already a member of Local Administrators"
            Write-Output $error[0]
        }
        else
        {
            Invoke-Command -ComputerName $DestinationServer -ScriptBlock {Add-LocalGroupMember -Group Administrators -Member NBCH100 -Verbose}
            Write-Host -ForegroundColor Green "NBCH100 Added to Local Administrators"
        }
    }


    function Format-WebsiteXMLs
    {
        $websitexml = 'C:\upgf\websites.xml'
        (Get-Content $websitexml) | Where-Object {$_.trim() -ne "" } | Set-Content $websitexml
    }

    # App Pool XML export file tends to have spaces in between each line of code causing a conflict during import. This function trims the whitespace between the lines.
    function Format-AppPoolXMLs
    {
        $apppoolxml = 'C:\upgf\apppools.xml'
        (Get-Content $apppoolxml) | Where-Object {$_.trim() -ne "" } | Set-Content $apppoolxml
    }

    # Copy the XML files to the new server on the C: drive for importing.
    function Copy-XMLs
    {   
        [CmdletBinding()]
        param(
            [string]$DestinationServer
        )
        robocopy $share\$DestinationServer\xmls\ \\$DestinationServer\c$\upgf *.xml /S /E /Z /B /TEE /R:3 /W:3 /MT:2
        Write-Host -ForegroundColor Green "Copied app pool and site xmls to $DestinationServer"
    }

    function Export-XMLs
    {
        [CmdletBinding()]
        param(
            [string]$Destination
        )

        if (Test-Path "$Destination\xmls")
        {
            Copy-Item 'C:\upgf\websites.xml' "$Destination\xmls" -Force -Verbose | Out-Null;
            Copy-Item 'C:\upgf\apppools.xml' "$Destination\xmls" -Force -Verbose | Out-Null;
            Write-Host -ForegroundColor Green "Website and Apppool xmls copied to Share"
        }
        elseif (!(Test-Path "$Destination\xmls"))
        {
            New-Item -ItemType Directory -Path $Destination -Name "xmls" | Out-Null
            Copy-Item 'C:\upgf\websites.xml' "$Destination\xmls" -Force -Verbose | Out-Null;
            Copy-Item 'C:\upgf\apppools.xml' "$Destination\xmls" -Force -Verbose | Out-Null;
            Write-Host -ForegroundColor Green "Website and Apppool xmls copied to Share"
        }
        else
        {
            Write-Host "Unable to locate $Destination"
            break
        }
        Write-Host -ForegroundColor Green "Copied app pool and site xmls to $Destination"
    }

    # Copy the IIS Site directories from the Source server to the Destination server. Performed as Robocopy jobs from WPADMA01 for efficiency.
    # Need to intoduce the ability to copy from Source to Share with Export option, and then from Share to Destination with Import option. 
    # Copy physical IIS Site files
    function Get-PhysicalSiteFiles
    {
        param(
            [Parameter(Position = 0, Mandatory = $true)]
            [ValidateSet("Import", "Export", "Migrate")]
            [string]$Scope, 
            [string]$SourceServer,
            [string]$DestinationServer
        )
        if ($Scope -eq "Migrate") # Straight up migrate from one server to another, no switches
        {
            if (!(Test-Path \\$DestinationServer\c$\inetpub))
            {
                New-Item -ItemType Directory -Path "\\$DestinationServer\c$\" -Name "inetpub" -Force -ErrorAction SilentlyContinue | Out-Null
                Write-Host -ForegroundColor Green "Inetpub folder created on $DestinationServer"
                Write-Host -ForegroundColor Green "Migrating Site Files..."
                Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:SourceServer\c$\inetpub\ \\$using:DestinationServer\c$\inetpub\ /S /E /Z /B /TEE /R:3 /W:3 /MT:8 /XF *.log} -ConfigurationName tom
            }
            else
            {
                Write-Host -ForegroundColor Green "Migrating Site Files..."
                Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:SourceServer\c$\inetpub\ \\$using:DestinationServer\c$\inetpub\ /S /E /Z /B /TEE /R:3 /W:3 /MT:8 /XF *.log} -ConfigurationName tom
            }
        }
        elseif ($Scope -eq "Export") # Exporting Source to Share
        {
            if (Test-Path "$share\$SourceServer")
            {
                if (!(Test-Path "$share\$SourceServer\inetpub"))
                {
                    New-Item -ItemType Directory -Path "$share\$SourceServer\" -Name "inetpub" -Force -ErrorAction SilentlyContinue | Out-Null
                    Write-Host -ForegroundColor Cyan "Inetpub folder created on Share"
                    Export-IISSites -SourceServer $SourceServer;
                    Export-AppPools -SourceServer $SourceServer;
                    Format-WebsiteXMLs;
                    Format-AppPoolXMLs;
                    New-Item -ItemType Directory -Path "$share\$SourceServer\" -Name "xmls" -Force -ErrorAction SilentlyContinue | Out-Null
                    Write-Host -ForegroundColor Cyan "XMLs folder created on Share"
                    Export-XMLs -Destination "$Share\$SourceServer\"
                    Write-Host -ForegroundColor Cyan "Copying site files to Share..."
                    Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:SourceServer\c$\inetpub\ $using:share\$using:SourceServer\inetpub /S /E /Z /B /TEE /R:3 /W:3 /NFL /NDL /NP /MT:8 /XF *.log} -ConfigurationName tom
                }
                else
                {
                    Export-IISSites -SourceServer $SourceServer;
                    Export-AppPools -SourceServer $SourceServer;
                    Format-WebsiteXMLs;
                    Format-AppPoolXMLs;
                    New-Item -ItemType Directory -Path "$share\$SourceServer\" -Name "xmls" -Force -ErrorAction SilentlyContinue | Out-Null
                    Export-XMLs -Destination "$Share\$SourceServer\"
                    Write-Host -ForegroundColor Cyan "Copying site files to Share..."
                    Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:SourceServer\c$\inetpub\ $using:share\$using:SourceServer\inetpub /S /E /Z /B /TEE /R:3 /W:3 /NFL /NDL /NP /MT:8 /XF *.log} -ConfigurationName tom
                }
            }
            elseif (!(Test-Path "$share\$SourceServer\"))
            {
                New-Item -ItemType Directory -Path "$share\" -Name "$sourceServer" -Force -ErrorAction SilentlyContinue | Out-Null
                Write-Host -ForegroundColor Cyan "$SourceServer folder created on Share"
                if (!(Test-Path "$share\$SourceServer\inetpub"))
                {
                    New-Item -ItemType Directory -Path "$share\$SourceServer\" -Name "inetpub" -Force -ErrorAction SilentlyContinue | Out-Null
                    Write-Host -ForegroundColor Cyan "Inetpub folder created on Share"
                    Export-IISSites -SourceServer $SourceServer;
                    Export-AppPools -SourceServer $SourceServer;
                    Format-AppPoolXMLs;
                    New-Item -ItemType Directory -Path "$share\$SourceServer\" -Name "xmls" -Force -ErrorAction SilentlyContinue | Out-Null
                    Write-Host -ForegroundColor Cyan "XMLs folder created on Share"
                    Export-XMLs -Destination "$Share\$SourceServer\"
                    Write-Host -ForegroundColor Cyan "Copying site files to Share..."
                    Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:SourceServer\c$\inetpub\ $using:share\$using:SourceServer\inetpub /S /E /Z /B /TEE /R:3 /W:3 /NFL /NDL /NP /MT:8 /XF *.log} -ConfigurationName tom
                }
            }   
        }
        elseif ($Scope -eq "Import") # Importing Source to Desination
        {
            if (!(Test-Path "\\$DestinationServer\c$\inetpub\" -ErrorAction SilentlyContinue))
            {
                New-Item -ItemType Directory -Path "\\$DestinationServer\c$\" -Name "inetpub" -Force -ErrorAction SilentlyContinue | Out-Null
                if ((Test-Path \\$DestinationServer\c$\inetpub -ErrorAction SilentlyContinue))
                {
                    Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy $using:share\$using:DestinationServer\inetpub \\$using:DestinationServer\c$\inetpub\ /S /E /Z /B /TEE /R:3 /W:3 /NFL /NDL /NP /MT:8} -ConfigurationName tom
                }
                else
                {
                    Write-Host -ForegroundColor Red "Unable to reach $Source folder on $DestinationServer"
                }
            }
            else
            {
                Write-Host -ForegroundColor Yellow "inetpub already present on $DestinationServer"
                Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy $using:share\$using:DestinationServer\inetpub \\$using:DestinationServer\c$\inetpub\ /S /E /Z /B /TEE /R:3 /W:3 /NFL /NDL /NP /MT:8} -ConfigurationName tom
            }
        }
        else
        {
            Write-Host -ForegroundColor White -BackgroundColor DarkGray "No $Source Application on Source, nothing to copy."
        }
    }

    function Copy-DeleteScript
    {
        [CmdletBinding()]
        param(
            [string]$DestinationServer
        )
        $share = "\\opnasi02\server\tom\scripts\misc scripts"
        if (Test-Path \\$DestinationServer\c$\upgf)
        {
            Copy-Item "$share\clean-iis.bat" "\\$DestinationServer\c$\upgf\" -Force -ErrorAction SilentlyContinue
            Write-Host -ForegroundColor Green "Cleanup script deployed"
        }
        else
        {
            Write-Host -ForegroundColor Green "Oopsie"
        }
    }

    function Remove-IISConfig
    {
        [CmdletBinding()]
        param(
            [string]$DestinationServer
        )
        Write-Host -ForegroundColor Black -BackgroundColor Yellow "CAUTION: YOU ARE ABOUT TO DELETE ALL IIS SITES AND APP POOLS ON $DestinationServer!"
        $ask = Read-Host -Prompt "Are you sure you want peroform this action(y/n)"
        if ($ask -eq 'y')
        {
            # Copy batch script to delete all existing IIS App Pools and Sites over to destination server, then run the script with psexec and delete the script when it's completed.
            Copy-DeleteScript -DestinationServer $DestinationServer;
            Start-Process -FilePath PsExec -ArgumentList "-s", "\\$DestinationServer", "cmd", "/c", "c:\upgf\clean-iis.bat" -Wait
            Remove-Item -Path \\$DestinationServer\c$\upgf\clean-iis.bat
        }
        else
        {
            Write-Host -ForegroundColor White "IIS Sites and App Pools on $DestinationServer were not modified."
        }
    }

    # Import the App Pool XMLs to the Destination Server
    function Import-XMLs
    {
        [CmdletBinding()]
        param(
            [string]$DestinationServer
        )
        Start-Process -FilePath PsExec -ArgumentList "-s", "\\$DestinationServer", "cmd", "/c", "C:\Windows\System32\inetsrv\appcmd.exe add apppool /in < C:\upgf\apppools.xml"
        Start-Process -FilePath PsExec -ArgumentList "-s", "\\$DestinationServer", "cmd", "/c", "C:\Windows\System32\inetsrv\appcmd.exe add site /in < c:\upgf\websites.xml" -Wait
    }

    # Stop IIS Service on Destination
    function Stop-IIS
    {
        [CmdletBinding()]
        param(
            [string]$SourceServer,
            [string]$DestinationServer
        )
        if ($DestinationServer)
        {
            Start-Process -FilePath PsExec -ArgumentList "-s", "\\$DestinationServer", "cmd", "/c", "iisreset /stop"
        }
        elseif ($sourceServer)
        {
            Start-Process -FilePath PsExec -ArgumentList "-s", "\\$SourceServer", "cmd", "/c", "iisreset /stop"
        }
    }

    # Start IIS Service on Destination
    function Start-IIS
    {
        [CmdletBinding()]
        param(
            [string]$DestinationServer
        )
        if ($DestinationServer)
        {
            Start-Process -FilePath PsExec -ArgumentList "-s", "\\$DestinationServer", "cmd", "/c", "iisreset /start"
        }
        elseif ($sourceServer)
        {
            Start-Process -FilePath PsExec -ArgumentList "-s", "\\$SourceServer", "cmd", "/c", "iisreset /start"
        }
    }

    # Function to just move the XMLs to the new server and import them into IIS.
    function Get-WebServer
    {
        param(
            [Parameter(Position = 0, Mandatory = $true)]
            [ValidateSet("Import", "Export", "Migrate")]
            [string]$Scope,
            [string]$SourceServer,
            [string]$DestinationServer
        )
        if($Scope -eq "Export")
        {
            Get-DeliveryMethod -SourceServer $SourceServer -ErrorAction SilentlyContinue
            Get-PhysicalSiteFiles -Scope Export -SourceServer $SourceServer;
        }
        elseif ($Scope -eq "Import")
        {
            $prompt = Read-Host -Prompt "Are you sure the local xmls are correct? (y/n)"
            if ($prompt -eq 'y' -or '')
            {
                Remove-IISConfig -DestinationServer $DestinationServer;
                Get-DeliveryMethod -DestinationServer $DestinationServer -ErrorAction SilentlyContinue
                Copy-XMLs -DestinationServer $DestinationServer;
                Import-XMLs -DestinationServer $DestinationServer;
                Write-Host -ForegroundColor Yellow "Importing Site Files"
                Get-PhysicalSiteFiles -Scope Import -DestinationServer $DestinationServer;
                Set-LocalAdmin -DestinationServer $DestinationServer;
                Write-Host -ForegroundColor Green "Import Success. Verify configuration on new server."
            }
            elseif ($prompt -eq 'n')
            {
                Write-Host -ForegroundColor Yellow "Verify the local site configs before importing"
                break
            }
        }
        elseif ($scope -eq "Migrate")
        {
            Remove-IISConfig -DestinationServer $DestinationServer;
            Get-DeliveryMethod -SourceServer $SourceServer -DestinationServer $DestinationServer -ErrorAction SilentlyContinue
            Set-LocalAdmin -DestinationServer $DestinationServer;
            Export-IISSites -SourceServer $SourceServer;
            Export-AppPools -SourceServer $SourceServer;
            Format-WebsiteXMLs;
            Format-AppPoolXMLs;
            Export-XMLs -Destination $Share\$SourceServer\
            Copy-XMLs -DestinationServer $DestinationServer;
            Import-XMLs -DestinationServer $DestinationServer;
            Get-PhysicalSiteFiles -Scope Migrate -SourceServer $SourceServer -DestinationServer $DestinationServer;
        }
    }

    # Determine whether or not the server being modified is virtual or physical
    function Get-DeliveryMethod
    {
        [CmdletBinding()]
        param(
            [string]$SourceServer,
            [string]$DestinationServer
        )
        # Check if VMware Tools is installed
        $vmCheck = Invoke-Command -ComputerName $SourceServer -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\VMware, Inc.\VMware Tools' -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue
        $vmCheck2 = Invoke-Command -ComputerName $DestinationServer -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\VMware, Inc.\VMware Tools' -ErrorAction SilentlyContinue} -ErrorAction SilentlyContinue

        if ($SourceServer)
        {   
            if ($null -ne $vmCheck)
            {
                Write-Host -ForegroundColor Cyan "$SourceServer is Virtual"
                $true | Out-Null
            }
            else
            {
                Write-Host -ForegroundColor Cyan "$SourceServer is not Virtual"
                $false | Out-Null
            }
        }
        elseif ($DestinationServer)
        {
            if ($null -ne $vmCheck2)
            {
                Write-Host -ForegroundColor Cyan "$DestinationServer is Virtual"
                $true | Out-Null
            }
            else
            {
                Write-Host -ForegroundColor Cyan "$DestinationServer is not Virtual"
                $false | Out-Null
            }
        }
        elseif ($DestinationServer -and $SourceServer)
        {
            if ($null -ne $vmCheck2 -and $null -ne $vmCheck)
            {
                Write-Host -ForegroundColor Cyan "$DestinationServer is Virtual"
                Write-Host -ForegroundColor Cyan "$SourceServer is Virtual"
                $true | Out-Null
            }
            else
            {
                Write-Host -ForegroundColor Cyan "$DestinationServer is not Virtual"
                $false | Out-Null
            }v
        }
    }

    # Choosing which function to perform
    if ($Scope -eq "Export")
    {   
        Get-WebServer -Scope Export -SourceServer $SourceServer;
        Write-Host -ForegroundColor Yellow "DON`'T FORGET TO COPY THE CERT!"
    }
        elseif ($Scope -eq "Import")
    {
        Get-WebServer -Scope Import -DestinationServer $DestinationServer;
        Write-Host -ForegroundColor Yellow "DON`'T FORGET TO COPY THE CERT!"
    }
        elseif ($Scope -eq "Migrate")
    {
        Stop-IIS -DestinationServer $DestinationServer;
        Get-WebServer -Scope Migrate -SourceServer $SourceServer -DestinationServer $DestinationServer;
        Start-IIS -DestinationServer $DestinationServer;
        Write-Host -ForegroundColor Yellow "DON`'T FORGET TO COPY THE CERT!"
    }
        elseif ($Scope -eq "Restart")
    {
        Stop-IIS -SourceServer $SourceServer;
        Start-IIS -SourceServer $SourceServer;
    }
        else
    {
        Write-Host -ForegroundColor Red "You must enter a valid Scope."
    }

# }
# finally
# {
#     Stop-Transcript
# }