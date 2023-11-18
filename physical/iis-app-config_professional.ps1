<#
.SYNOPSIS
    The purposes of this script is to copy and configure an existing IIS 
    site to a new server from an existing server in support of upgrading or 
    migratory efforts. The script collects 3 parameters from the user:
    1. The Source server; the server from which the IIS site will be copied.
    2. The Destination server; the server TO which the iis site will be copied.
    3. Operation to perform; Import Site/Config to the Destination server, Export 
        Site/Config from the Source Server, Both (export from source and import 
        to destination), or Restart IIS.

.DESCRIPTION
    First, the script will collect the information from the parameters. 
    The source server will be the server you intend to copy the IIS Site from.
    The destination server is the target for the new IIS site. UPDATE

.PARAMETER SourceServer
    The 

.PARAMETER DestServer
    Description of the second parameter.

.PARAMETER Parameter3
    Description of the third parameter.

.EXAMPLE
    .\YourScript.ps1 -Parameter1 Value1 -Parameter2 Value2
    Description of what this example does.

.EXAMPLE
    .\YourScript.ps1 -Parameter1 Value1 -Parameter3 Value3
    Another example with different parameters.

.NOTES
    Author: Your Name
    Version: 1.0
    Date: Date created or last modified.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0, HelpMessage="Description of Parameter1")]
    [string]$Parameter1,

    [Parameter(Position=1, HelpMessage="Description of Parameter2")]
    [int]$Parameter2 = 42,

    [Parameter(Position=2, HelpMessage="Description of Parameter3")]
    [switch]$Parameter3
)

# Begin the script logic
Write-Host "Parameter1: $Parameter1"
Write-Host "Parameter2: $Parameter2"
Write-Host "Parameter3: $Parameter3"
function Set-IISSites
{
        param(
            [Parameter(Position=0,mandatory=$true)]
            [string]$SourceServer, # Source server is the server the configuration is being coped from, ideally identical to the server that's being provisioned.
            [Parameter(Position=1,mandatory=$true)]
            [string]$DestServer, # Destination server is the destination the configuration is being copied to, namely the new server.
            [string]$Application # The application suite or web site that is being migrated.
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

            Write-Host "Certificate exported to $exportPath."
        } else {
            Write-Host "Certificate not found for site $siteName."
        }
    }    

    # Export the IIS Site from the Source server in XML format to your local machine
    function Export-IISSites
    {
        [CmdletBinding()]
        param()
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
        param()

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
            [string]$DestServer
        )
        Write-Host -ForegroundColor Yellow "Attempting to add NBCH100 service account to Local Administrators group on $DestServer"
        Invoke-Command -ComputerName $DestServer -ScriptBlock {Get-LocalGroupMember -Group Administrators -Member NBCH100} -ErrorAction SilentlyContinue
        if (!($?))
        {
            Write-Host -ForegroundColor White "NBCH100 Already a member of Local Administrators"
            Write-Output $error[0]
        }
        else
        {
            Invoke-Command -ComputerName $DestServer -ScriptBlock {Add-LocalGroupMember -Group Administrators -Member NBCH100 -Verbose}
            Write-Host -ForegroundColor Green "NBCH100 Added to Local Administrators"
        }
    }

    # The Default Web Site has an ID of 1 by default when exported as an XML because it's the first web site in IIS.
    # This function removes the default site from the XML if it is present. The sites are also then sorted based on ID.
    # If their are 4 sites, the site with the lowest ID (namely 1) will have its' ID changed to 5.
    # If there are 5 sites, the site with the lowest ID (namely 1) will have its' ID changed to 6, etc.
    # This will allow room for the migrated sites to fit in with the existing Default Site on the newly provisioned server without having to remove the Default Site.
    # Some hosts are built without a Default Site. If that's the case, only then will it be necessary to adjust the IDs moving to the new host.
    function Remove-DefaultSite
    {
        $path = 'C:\upgf\websites.xml'
        (Get-Content $path) | Where-Object {$_.trim() -ne "" } | Set-Content $path  # "pretty print" to remove whitespace lines between each line of the xml created in some exports.
        $xml = [xml](Get-Content -Path $path)                                       # create XML object from the website.xml
        $default = $xml.selectsinglenode('//appcmd/SITE') | out-null                # Select the first node under SITE, which would typically be Default Site. If there is no Default Site from the original server, the XML will be modified to account for the Default Site on the new server.
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

    function Remove-AppPool
    {
        param(
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
        $session1 = New-PSSession -ComputerName $DestServer
        Copy-Item 'C:\upgf\websites.xml' 'C:\upgf\' -ToSession $session1 | Out-Null;
        Copy-Item 'C:\upgf\apppools.xml' 'C:\upgf\' -ToSession $session1 | out-null;
        Write-Host -ForegroundColor Green "Copied app pool and site xmls"
    }

    # Copy the IIS Site directories from the Source server to the destination server. These are done as PS Jobs.
    # I'm thinking about converting these to Robocopy jobs to show the output better and maybe work a little faster. - WIP
    function Copy-PNDSites
    {   
        $sourceTest = Get-ChildItem \\$sourceserver\c$\inetpub\
        if (Test-Path $sourceTest)
        {
            # Copy physical IIS Site files
            function Get-PhysicalSiteFiles
            {
                param(
                    [string]$Source,
                    [string]$SiteDirectory,
                    [switch]$DirOption
                )
                if((Test-Path "\\$SourceServer\c$\inetpub\$Source") -and (!($DirOption)))
                {
                    Invoke-Command -ScriptBlock {robocopy \\$sourceServer\c$\inetpub\$Source \\$DestServer\c$\inetpub\$Source /S /E /Z /B /TEE /R:3 /W:3 /MT:8}
                }
                elseif($DirOption)
                {
                    Invoke-Command -ScriptBlock {robocopy \\$sourceServer\c$\inetpub\$SiteDirectory \\$DestServer\c$\inetpub\$SiteDirectory /S /E /Z /B /TEE /R:3 /W:3 /MT:8}
                }
                else
                {
                    Write-Host -ForegroundColor White -BackgroundColor DarkGray "No $Source Application on Source, nothing to copy."
                }
            } 
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
            else
        {
            write-host -ForegroundColor Red -BackgroundColor DarkGray "Unable to reach $SourceServer"
        }
    }

    # Import the App Pool XMLs to the Destination Server
    function Import-AppPools
    {
        Write-Host -ForegroundColor Black -BackgroundColor Yellow "Just copy the contents of each line below within the quotes and paste into cmd prompt to perform the specified action. App Pools go first if performing both:"
        Write-Host -ForegroundColor Green "Import AppPools with: `"C:\Windows\System32\inetsrv\appcmd.exe add apppool /in < c:\upgf\apppools.xml`""
        Write-Host -ForegroundColor Green "Import Sites with: `"C:\Windows\System32\inetsrv\appcmd.exe add site /in < c:\upgf\websites.xml`""
        Invoke-Command -ScriptBlock {psexec \\$DestServer cmd}
    }

    # Stop IIS Service on Destination
    function Stop-IIS
    {
        $DestIP = Test-Connection -ComputerName $DestServer -Count 1 | Select-Object -property IPV4Address -ExpandProperty IPV4Address | Select-Object IPAddressToString -ExpandProperty IPAddressToString
        Write-Host -ForegroundColor Yellow "Attempting to Stop IIS Site on $DestServer"
        Start-Job -Name "iisStop" -ScriptBlock {Start-Process -FilePath "C:\Windows\System32\cmd.exe" -Verb RunAs -ArgumentList {/c iisreset $using:DestIP /stop}} | Out-Null
        $id1 = Get-Job | Where-Object {$_.Name -eq "iisStop"} | Select-Object Id -ExpandProperty Id
        Wait-Job -Id $id1 | Out-Null
        Write-Host -ForegroundColor Green "Stopped IIS on $DestServer"
        Remove-Job -Name "iisStop" | Out-Null
    }
    
    # Start IIS Service on Destination
    function Start-IIS
    {
        $DestIP = Test-Connection -ComputerName wdpndw21 -Count 1 | Select-Object -property IPV4Address -ExpandProperty IPV4Address | Select-Object IPAddressToString -ExpandProperty IPAddressToString
        Write-Host -ForegroundColor Yellow "Attempting to start IIS Site on $DestServer"
        Start-Job -Name "iisStart" -ScriptBlock {Start-Process -FilePath "C:\Windows\System32\cmd.exe" -Verb RunAs -ArgumentList {/c iisreset $using:DestIP /start}} | Out-Null
        $id2 = Get-Job | Where-Object {$_.Name -eq "iisStart"} | Select-Object Id -ExpandProperty Id
        Wait-Job -Id $id2 | Out-Null
        Write-Host -ForegroundColor Black -BackgroundColor Green "Start Success"
        Remove-Job -Name "iisStart" | Out-Null
    }
    
    # Function to just export the IIS files to the local machine from the Source Server.
    function Get-WebServer
    {
        $testE = Test-Connection $SourceServer -Quiet
        if($testE -eq "True")
        {
            Export-IISSites;
            Export-AppPools;
            Remove-DefaultSite;
            Fix-AppPoolXML;
            # Start-Job -Name "qqq9xmb" -ScriptBlock {
            #     $path = 'C:\upgf\websites.xml'
            #     $xml = [xml](Get-Content -Path $path)
            #     $default = $xml.selectsinglenode('//appcmd/SITE')
            #     if ($default.SITE.NAME -eq "Default Web Site")
            #     {                                                                             # Removed 11-13, unsure of need, will delete later
            #         $default.ParentNode.RemoveChild($default)
            #         $xml.Save('C:\upgf\websites.xml')
            #         return $true
            #     }
            #         else
            #     {
            #         Write-Host -ForegroundColor Black -BackgroundColor White "Default Site already removed..."
            #         return $false
            #     }
            # } | Out-Null
            # $id = Get-Job | Where-Object {$_.Name -eq "qqq9xmb"} | Select-Object Id -ExpandProperty Id
            # Write-Host -ForegroundColor Yellow "Removing Default Site..."
            # Wait-Job -Id $id | Out-Null
            # Write-Host -ForegroundColor Green "Successfully removed Default Site"
            # Remove-Job -Name "qqq9xmb" | Out-Null
        }
            else
        {
            Write-Host -ForegroundColor Black -BackgroundColor Green "Unable to reach server defined.Try again..."
            Set-IISSites # Start Over
        }
    }

    # Function to just move the XMLs to the new server and import them into IIS.
    function Set-WebServer
    {
        $testI = Test-Connection $DestServer -Quiet
        if($testI -eq "true")
        {
            Copy-XMLs;
            if ($Application -eq 'pnd' -or $Application -eq '')
            {
                Copy-PNDSites;
            }
            elseif($Application -eq 'adm')
            {
                Copy-ADMSites;
            }
            Import-AppPools;
            Write-Host -ForegroundColor Black -BackgroundColor Green "Import Success. Verify configuration on new server."
        }
        else
        {
            Write-Host -ForegroundColor Yellow -BackgroundColor DarkBlue "Test-Connection failed"
        }
    }
    
    #prompt at the beginning to start the function - WIP Want to make this more
    $ask1 = Read-Host -Prompt "[I]mporting, [E]xporting, [B]oth, or [R]estarting?"
    if ($ask1 -eq 'e')
    {   
        Get-WebServer;
        Write-Host -ForegroundColor Yellow "DON`'T FORGET TO COPY THE CERT!"
    }
        elseif ($ask1 -eq 'i')
    {
        Set-WebServer
    }
        elseif ($ask1 -eq 'b')
    {
        Stop-IIS;
        Get-WebServer;
        Set-WebServer;
        Start-IIS;
        Write-Host -ForegroundColor Yellow "DON`'T FORGET TO COPY THE CERT!"
    }
        elseif ($ask1 -eq 'r')
    {
        Stop-IIS;
        Start-IIS
    }
        else
    {
        Write-Host -ForegroundColor Cyan "Please select a valid option"
        Set-IISSites
    }
} Set-IISSites