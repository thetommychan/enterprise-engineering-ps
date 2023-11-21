<#
.SYNOPSIS
    The purposes of this script is to copy and configure an existing IIS 
    site to a new server from an existing server in support of upgrading or 
    migratory efforts. The script collects 3 parameters from the user:
    1.  Scope; Import Site/Config to the Destination server, Export 
        Site/Config from the Source Server, Both (export from source and import 
        to destination), or Restart IIS. 
    2.  SourceServer; the server from which the IIS site will be migrated.
    3.  DestinationServer; the server to which the iis site will be migrated.

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
    .\iis-app-config -Scope Import -DestinationServer ServerB
    This will import the saved configuration from the Server Share if it's present. 
    If it's not present, a message will be displayed: 
    "No source to import from. Please Run 'iis-app-config.ps1 -Scope Export -SourceServer <Server Name>' to create a valid configuration to import."

.EXAMPLE
    .\iis-app-config -Scope Migrate -SourceServer ServerA -DestinationServer ServerB
    This will migrate the IIS Site configuration from ServerA to ServerB. 
    

.NOTES
    Author: Tom Chandler
    Version: 1.0
    Date: Date created or last modified.
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
function Export-ServerCert # Not working, not enough patience
{
    # Define the IIS site name for which you want to export the certificate
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
    Invoke-Command -ComputerName $DestinationServer -ScriptBlock {Get-LocalGroupMember -Group Administrators -Member NBCH100} -ErrorAction SilentlyContinue
    if (!($?))
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

function Set-LocalRemoting
{
    [CmdletBinding()]
    param(
        [string]$SourceServer,
        [string]$DestinationServer
    )
    Write-Host -ForegroundColor Yellow "Checking to see if $env:USERNAME is capable of Remote Management"
    Invoke-Command -ComputerName $DestinationServer -ScriptBlock {Get-LocalGroupMember -Group "Remote Management Users" -Member "$env:UserName"} -ErrorAction SilentlyContinue
    if (!($?))
    {
        Write-Host -ForegroundColor White "$env:UserName already a member or Remote Management Users"
        Write-Output $error[0]
    }
    else
    {
        Invoke-Command -ComputerName $DestinationServer -ScriptBlock {Add-LocalGroupMember -Group "Remote Management Users" -Member "$env:UserName" -Verbose}
        Write-Host -ForegroundColor Green "NBCH100 Added to Local Administrators"
    }
}

# Remove the Default Site from the websites.xml export
function Remove-DefaultSite
{
    [CmdletBinding()]
    param(
        [string]$SourceServer
    )
# The Default Web Site has an ID of 1 by default when exported as an XML because it's the first web site in IIS.
# This function removes the default site from the XML if it is present. The sites are also then sorted based on ID.
# If their are 4 sites, the site with the lowest ID (namely 1) will have its' ID changed to 5.
# If there are 5 sites, the site with the lowest ID (namely 1) will have its' ID changed to 6, etc.
# This will allow room for the migrated sites to fit in with the existing Default Site on the newly provisioned server without having to remove the Default Site.
# Some hosts are built without a Default Site. If that's the case, only then will it be necessary to adjust the IDs moving to the new host.
    $path = 'C:\upgf\websites.xml'
    (Get-Content $path) | Where-Object {$_.trim() -ne "" } | Set-Content $path  # "pretty print" to remove whitespace lines between each line of the xml created in some exports.
    $xml = [xml](Get-Content -Path $path)                                           # create XML object from the website.xml
    $default = $xml.selectsinglenode('//appcmd/SITE')                               # Select the first node under SITE, which would typically be Default Site. If there is no Default Site from the original server, the XML will be modified to account for the Default Site on the new server.
    if ($default.SITE.NAME -eq "Default Web Site")
    {
        $default.ParentNode.RemoveChild($default)
        $xml.Save('C:\upgf\websites.xml')                                       # If the node for Default Site is present, remove the node and save the XML.
                                                                                # No need to sort since the new server will have Default Site.
        Write-Host -ForegroundColor Green "Default Site detected, removed..."             
    }
        else
    {
        $existing = $xml.SelectNodes('//appcmd/SITE')
        $sorted = $existing | Sort-Object -Property SITE.ID
        if ($sorted[0].'SITE.ID' -gt '1')
        {
            Write-Host -ForegroundColor Green "No Default Site on $SourceServer, but Site IDs were not updated. Not sorting..."
        }
        elseif ($sorted[0].'SITE.ID' -eq '1')
        {
            Sort-Websites
            Write-Host -ForegroundColor Green "Websites sorted"                              # If the Node for Default Site is NOT present, adjust the websites.xml to account for the default site that will be in the new host by
            Write-Host -ForegroundColor Yellow "Default Site already removed..."             # reassigning the lowest site ID (namely the site with ID 1) to an ID of 5. This will free up the Site ID 1 slot for the Default Site in the new host.
        }
        
    }
}

# Remove default app pools that may be present in apppools.xml export
function Remove-AppPool
{
    [CmdletBinding()]
    param(
        [string]$SourceServer,
        [string]$DestinationServer,
        [string]$AppPoolName
    )
    # Fix-AppPoolXML;
    $path = 'C:\upgf\apppools.xml'
    $xml = [xml](Get-Content -Path $path)
    $existing = $xml.SelectSingleNode('//appcmd')
    foreach ($pool in $existing){
        $name = $pool.APPPOOL | Select-Object APPPOOL.NAME -ExpandProperty apppool.name
        # Delete Default App Pools to avoid conflicts when importing xml to new server
        if ($name -like $AppPoolName)
        {
            $node = $xml.SelectSingleNode("//appcmd/APPPOOL[@APPPOOL.NAME='$AppPoolName']")
            $node.ParentNode.RemoveChild($node) | Out-Null
            $xml.Save('C:\upgf\apppools.xml') | Out-Null
            Write-Host -ForegroundColor Green "Removed $AppPoolName Successfully"
        }
        else
        {
            Write-Host -ForegroundColor White "No $AppPoolName..."
        }
    }
}

# Sort Site IDs in websites.xml
function Sort-IDs
{
    [CmdletBinding()]
    param(
        [string]$num
    )
    Write-Verbose -Message "Attempting to update the IDs in 'websites.xml'"
        $sorted = $existing | Sort-Object -Property SITE.ID
        if ($sorted.'SITE.ID' -notcontains '2' -and $sorted.'SITE.ID' -contains '1' -and $sorted.'SITE.ID' -contains '3')
        {
            $sorted[0].'SITE.ID' = '2'; $xml.Save('C:\upgf\websites.xml')
            $sorted[0].site.id = '2'; $xml.Save('C:\upgf\websites.xml')
            Write-Host "Site IDs are " $sorted.'SITE.ID'
        }
        else
        {
            $sorted[0].'SITE.ID' = $num; $xml.Save('C:\upgf\websites.xml')
            $sorted[0].site.id = $num; $xml.Save('C:\upgf\websites.xml')
            Write-Host "Site IDs are " $sorted.'SITE.ID'
        }


}

# Iterate through sites and assign non-conflicting IDs
function Sort-Websites
{
    $path = 'C:\upgf\websites.xml'
    $xml = [xml](Get-Content -Path $path)
    $existing = $xml.SelectNodes('//appcmd/SITE')
    $count = $existing | Measure-Object | select-object -property count -ExpandProperty count
    if ($count -lt '5' -and $count -gt '3')
    {   
        Sort-IDs -num '5'
        if ($?)
        {
            Write-Host -ForegroundColor Green "IDs Updated"
        }
        else
        {
            Write-Host -ForegroundColor Red "IDs not updated"
            Write-Output $error[0]
        }
    }
    elseif ($count -lt '6' -and $count -gt '4')
    {
        Sort-IDs -num '6'
        if ($?)
        {
            Write-Host -ForegroundColor Green "IDs Updated"
        }
        else
        {
            Write-Host -ForegroundColor Red "IDs not updated"
            Write-Output $error[0]
        }
    }
    elseif ($count -lt '7' -and $count -gt '5')
    {
        Sort-IDs -num '7'
        if ($?)
        {
            Write-Host -ForegroundColor Green "IDs Updated"
        }
        else
        {
            Write-Host -ForegroundColor Red "IDs not updated"
            Write-Output $error[0]
        }
    } 
    elseif ($count -lt '4' -and $count -gt '2')
    {
        Sort-IDs -num '4'
        if ($?)
        {
            Write-Host -ForegroundColor Green "IDs Updated"
        }
        else
        {
            Write-Host -ForegroundColor Red "IDs not updated"
            Write-Output $error[0]
        }
    }
    elseif ($count -lt '8' -and $count -gt '6')
    {
        Sort-IDs -num '8'
        if ($?)
        {
            Write-Host -ForegroundColor Green "IDs Updated"
        }
        else
        {
            Write-Host -ForegroundColor Red "IDs not updated"
            Write-Output $error[0]
        }
    }  
}

# App Pool XML export file tends to have spaces in between each line of code causing a conflict during import. This function trims the whitespace between the lines.
function Fix-AppPoolXML
{
    $in = 'C:\upgf\apppools.xml'
    $out = 'C:\upgf\apppools.xml'
    (Get-Content $in) | Where-Object {$_.trim() -ne "" } | Set-Content $out
    remove-appPool -AppPoolName 'DefaultAppPool';
    remove-appPool -AppPoolName 'Classic .NET AppPool';
    remove-appPool -AppPoolName '.NET v2.0 Classic';
    remove-appPool -AppPoolName '.NET v2.0';
    remove-appPool -AppPoolName '.NET v4.5 Classic';
    remove-appPool -AppPoolName '.NET v4.5';


}

# Copy the XML files to the new server on the C: drive for importing.
function Copy-XMLs
{   
    [CmdletBinding()]
    param(
        [string]$DestinationServer
    )
    $session1 = New-PSSession -ComputerName $DestinationServer
    # Copy-Item 'C:\upgf\websites.xml' 'C:\upgf\' -ToSession $session1 | Out-Null;
    # Copy-Item 'C:\upgf\apppools.xml' 'C:\upgf\' -ToSession $session1 | Out-Null;
    Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:share\$DestinationServer\xmls \\$using:DestinationServer\c$\ *.xml /S /E /Z /B /NFL /NDL /TEE /R:3 /W:3} -ConfigurationName admin
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
        Copy-Item 'C:\upgf\websites.xml' "$Destination\xmls" | Out-Null;
        Copy-Item 'C:\upgf\apppools.xml' "$Destination\xmls" | Out-Null;
        Write-Host -ForegroundColor Green "Website and Apppool xmls copied to Share"
    }
    elseif (!(Test-Path "$Destination\xmls"))
    {
        New-Item -ItemType Directory -Path $Destination -Name "xmls" | Out-Null
        Copy-Item 'C:\upgf\websites.xml' "$Destination\xmls" | Out-Null;
        Copy-Item 'C:\upgf\apppools.xml' "$Destination\xmls" | Out-Null;
        Write-Host -ForegroundColor Green "Website and Apppool xmls copied to Share"
    }
    else
    {
        Write-Host "Unable to locate $Destination"
        break
    }
    Write-Host -ForegroundColor Green "Copied app pool and site xmls to $SourceServer"
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
    $share = "\\opnasi02\server\tom\sites"
    if ($Scope -eq "Migrate") # Straight up migrate from one server to another, no switches
    {
        if (!(Test-Path \\$DestinationServer\c$\inetpub))
        {
            New-Item -ItemType Directory -Path "\\$DestinationServer\c$\" -Name "inetpub" -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Host -ForegroundColor Green "Inetpub folder created on $DestinationServer"
            Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:SourceServer\c$\inetpub\ \\$using:DestinationServer\c$\inetpub\ /S /E /Z /B /NFL /NDL /TEE /MT:16} -ConfigurationName admin
        }
        else
        {
            Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:SourceServer\c$\inetpub\ \\$using:DestinationServer\c$\inetpub\ /S /E /Z /B /NFL /NDL /TEE /MT:16} -ConfigurationName admin
        }
    }
    elseif ($Scope -eq "Export") # Exporting Source to Share
    {
        if (Test-Path "$share\$SourceServer")
        {
            if (!(Test-Path "$share\$SourceServer\inetpub"))
            {
                New-Item -ItemType Directory -Path "$share\$SourceServer" -Name "inetpub" | Out-Null;
                Export-IISSites -SourceServer $SourceServer;
                Export-AppPools -SourceServer $SourceServer;
                Remove-DefaultSite -SourceServer $SourceServer;
                Fix-AppPoolXML;
                New-Item -ItemType Directory -Path "$share\$SourceServer\" -Name "xmls" -Force -ErrorAction SilentlyContinue | Out-Null
                Export-XMLs -Destination "$Share\$SourceServer\"
                Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:SourceServer\c$\inetpub\ $using:share\$using:SourceServer\inetpub /S /E /Z /B /NFL /NDL /TEE /MT:16} -ConfigurationName admin
            }
            else
            {
                Export-IISSites -SourceServer $SourceServer;
                Export-AppPools -SourceServer $SourceServer;
                Remove-DefaultSite -SourceServer $SourceServer;
                Fix-AppPoolXML;
                New-Item -ItemType Directory -Path "$share\$SourceServer\" -Name "xmls" -Force -ErrorAction SilentlyContinue | Out-Null
                Export-XMLs -Destination "$Share\$SourceServer\"
                Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:SourceServer\c$\inetpub\ $using:share\$using:SourceServer\inetpub /S /E /Z /B /NFL /NDL /TEE /MT:16} -ConfigurationName admin
            }
        }
        elseif (!(Test-Path "$share\$SourceServer\"))
        {
            New-Item -ItemType Directory -Path "$share\" -Name "$sourceServer" -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Host -ForegroundColor Cyan "$SourceServer folder created on Share"
            if (!(Test-Path "$share\$SourceServer\inetpub"))
            {
                New-Item -ItemType Directory -Path "$share\$SourceServer\" -Name "inetpub" | Out-Null;
                Export-IISSites -SourceServer $SourceServer;
                Export-AppPools -SourceServer $SourceServer;
                Remove-DefaultSite -SourceServer $SourceServer;
                Fix-AppPoolXML;
                New-Item -ItemType Directory -Path "$share\$SourceServer\" -Name "xmls" -Force -ErrorAction SilentlyContinue | Out-Null
                Export-XMLs -Destination "$Share\$SourceServer\"
                Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy \\$using:SourceServer\c$\inetpub\ $using:share\$using:SourceServer\inetpub /S /E /Z /B /NFL /NDL /TEE /MT:16} -ConfigurationName admin
            }
        }   
    }
    elseif ($Scope -eq "Import") # Importing Source to Desination
    {
        if (!(Test-Path "\\$DestinationServer\c$\inetpub\"))
        {
            New-Item -ItemType Directory -Path "\\$DestinationServer\c$\" -Name "inetpub" -Force -ErrorAction SilentlyContinue | Out-Null
            if ((Test-Path \\$DestinationServer\c$\inetpub))
            {
                Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy $share\$using:DestinationServer\inetpub \\$using:DestinationServer\c$\inetpub\ /S /E /Z /B /NFL /NDL /TEE /MT:16} -ConfigurationName admin
            }
            else
            {
                Write-Host -ForegroundColor Red "Unable to reach $Source folder on $DestinationServer"
            }
        }
        else
        {
            Write-Host -ForegroundColor Yellow "inetpub already present on $DestinationServer"
            Invoke-Command -ComputerName wpadma01 -ScriptBlock {robocopy $share\$using:DestinationServer\inetpub \\$using:DestinationServer\c$\inetpub\ /S /E /Z /B /NFL /NDL /TEE /MT:16} -ConfigurationName admin
        }
    }
    else
    {
        Write-Host -ForegroundColor White -BackgroundColor DarkGray "No $Source Application on Source, nothing to copy."
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
    Start-Process -FilePath PsExec -ArgumentList "-s", "\\$DestinationServer", "cmd", "/c", "C:\Windows\System32\inetsrv\appcmd.exe add site /in < c:\upgf\websites.xml"
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
        # Move-SiteFiles -Scope Export -SourceServer $SourceServer;
        Get-PhysicalSiteFiles -Scope Export -SourceServer $SourceServer;
    }
    elseif ($Scope -eq "Import")
    {
        $prompt = Read-Host -Prompt "Are you sure the local xmls are correct? (y/n)"
        if ($prompt -eq 'y' -or '')
        {
            Get-DeliveryMethod -DestinationServer $DestinationServer -ErrorAction SilentlyContinue
            Copy-XMLs -DestinationServer $DestinationServer
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
        Get-DeliveryMethod -DestinationServer $DestinationServer -ErrorAction SilentlyContinue
        Set-LocalAdmin -DestinationServer $DestinationServer;
        Import-XMLs -DestinationServer $DestinationServer;
        Write-Host -ForegroundColor Yellow "Migrating Site Files"
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
    $vmCheck = Invoke-Command -ComputerName $SourceServer -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\VMware, Inc.\VMware Tools' -ErrorAction SilentlyContinue} -erroraction silentlycontinue
    $vmCheck2 = Invoke-Command -ComputerName $DestinationServer -ScriptBlock {Get-ItemProperty -Path 'HKLM:\SOFTWARE\VMware, Inc.\VMware Tools' -ErrorAction SilentlyContinue} -erroraction silentlycontinue

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
            Write-Host -ForegroundColor Cyan "$SourceServer is Virtual"
            $true | Out-Null
        }
        else
        {
            Write-Host -ForegroundColor Cyan "$SourceServer is not Virtual"
            $false | Out-Null
        }
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
    Write-Host -ForegroundColor Cyan "Something went wrong"
}