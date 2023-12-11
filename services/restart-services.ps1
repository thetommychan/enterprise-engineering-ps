<#
.SYNOPSIS
    The purpose of this script is to restart service(s) on a given server. It takes
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
        [Parameter(Mandatory = $true, Position = 0, HelpMessage="The ServerName parameter is the name of the server for which the services are being restarted on")]
        [string]$ServerName,
        [Parameter(Mandatory = $true, Position = 1, HelpMessage="The ServiceNamePattern parameter is the pattern of the display name for the service being restarted. If the full displayname is unknown, place an * after, i.e. PND_DIAD6*")]
        [string]$ServiceNamePattern
    )

function Get-Server
{
    param(
        [string]$ServerName
    )

    # If the server name isn't blank, check against AD.
    if ($ServerName -ne '')
    {
        $servercheck = Get-ADComputer -Filter { Name -eq $serverName } -ErrorAction SilentlyContinue
        # If server name is valid, proceed. If not, prompt again.
        if ($null -ne $servercheck)
        {
            Write-Host -ForegroundColor Green "Valid Server Name"
        }
        else
        {
            Write-Host -ForegroundColor Yellow "Invalid Server Name."
            break;
        }
    }
    else
    {
        Write-Host -ForegroundColor Yellow "Please enter the name of a server"
        break;
    }
} 

function Get-ServiceVerification
{
    param(
        [string]$ServerName,
        [string]$ServiceNamePattern
    )

    if ($ServiceNamePattern -ne '')
    {
        $global:services = Get-Service -ComputerName $serverName | Where-Object { $_.DisplayName -like "$ServiceNamePattern" }
        if ($services)
        {
            Write-Host -ForegroundColor Green "Valid Service Name Pattern"

            # Display services with numbers
            Write-Host -ForegroundColor Black -BackgroundColor Green "Service Details:"
            $serviceList = @{}
            $tableData = @()
            for ($i = 0; $i -lt $services.Count; $i++)
            {
                $serviceList["$($i + 1)"] = $services[$i]
                $rowData = [PSCustomObject]@{
                    'ID'   = $($i + 1)
                    'Service'  = $services[$i].DisplayName
                    'Status'   = $services[$i].Status
                }
                $tableData = @($tableData + $rowData)
            }
    
            $tableData | Format-Table -AutoSize

            # Set global variable for selected services
            $global:SelectedServices = $serviceList
        }
        else
        {
            if ($ServiceNamePattern -notcontains '*')
            {
                Write-Host -ForegroundColor Yellow "No services with the name `"$ServiceNamePattern`" found on $serverName"
                break;
            }
            Write-Host -ForegroundColor Yellow "No services matching the service name pattern `"$ServiceNamePattern`" found on $serverName"
            break;
        }
    }
    else
    {
        Write-Host -ForegroundColor Yellow "Please enter the pattern of a service name or a service display name"
        break;
    }
} 


function Restart-Services
{
    param(
        [string]$ServerName,
        [string]$ServiceNamePattern
    )
    # Check if there are multiple services to restart
    if ($global:SelectedServices.Count -gt 1)
    {
        # Prompt user to restart services by number
        $selectedServiceNumbers = Read-Host -Prompt "Enter the numbers of the services you want to restart (comma-separated)"
        $selectedServiceNumbers = $selectedServiceNumbers -split ',' | ForEach-Object { $_.Trim() }

        # Restart selected services
        $selectedServiceNumbers | ForEach-Object {
            $number = $_
            if ($global:SelectedServices.ContainsKey($number))
            {
                $selectedService = $global:SelectedServices[$number]
                Write-Host "Restarting $($selectedService.DisplayName) on $ServerName..."
                Invoke-Command -ComputerName $ServerName -ScriptBlock {
                    Restart-Service $using:selectedService.DisplayName -Verbose
                } -Verbose
            }
            else
            {
                Write-Host -ForegroundColor Yellow "Invalid service number: $number"
            }
        }
    }
    elseif ($global:SelectedServices.Count -eq 1)
    {
        # Restart the single selected service directly
        $selectedService = $global:SelectedServices.Values[0]
        $confirm = Read-Host -Prompt "Restart $($selectedService.DisplayName) on $ServerName`?"
        if ($confirm -eq 'y' -or $confirm -eq '')
        {
            Invoke-Command -ComputerName $ServerName -ScriptBlock {
                Restart-Service $using:selectedService.DisplayName -Verbose
            }
        }
        elseif ($confirm -eq 'n')
        {
            Write-Host "not restarting any services"
        }
    }
    else
    {
        Write-Host -ForegroundColor Yellow "No services selected for restart."
    }
        $Date = get-date -Format "HH:mmtt | dd/MM/yyyy"
        # Output to log on opnasi02
        $logContent = @"
    $Date`: Restarted services on '$serverName':
    $($services | ForEach-Object { $_.DisplayName })
"@
        $logPath = "\\opnasi02\Server\Tom\Scripts\logs\ServicesRestartLog.txt"
        $logContent | Out-File -Append -FilePath $logPath
}

# Validate the server name against AD
Get-Server -ServerName $ServerName;

# Validate the service name pattern against the services on the given server
Get-ServiceVerification -serverName $serverName -ServiceNamePattern $ServiceNamePattern

# Restart the given services on the named server
Restart-Services -ServerName $ServerName -ServiceNamePattern $ServiceNamePattern
