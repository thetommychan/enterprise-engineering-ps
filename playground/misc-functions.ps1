function-Set-LocalRemoting
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
    # Format-AppPoolXMLs;
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