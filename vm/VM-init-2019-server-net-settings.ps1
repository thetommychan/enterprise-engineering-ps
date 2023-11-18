# Run this after sysprep-generalize.ps1

function Configure-IPSettings
{
    $IPAddress = Read-Host -Prompt "Enter an IP Address found on the available_ips.xlsx spreadsheet at \\opnasi02\Server\Tom\scripts\xlsx"
    $subnetMask = "255.255.255.0"
    $interfaceAlias = "Ethernet1"
    $defaultGateway = "10.14.11.10"
    $dnsServers = "10.14.11.165", "10.14.18.171"

    # Confirm the settings
    $prompt = Read-Host -Prompt "`nIP Address: $ipAddress `nDefault Gateway: $defaultGateway `nSubnet Mask: $subnetMask `nDNS Server(s): $dnsServers `nDo you want to continue? (y/n)"

    if ($prompt -eq 'y' -or '')
    {
        Write-Host -ForegroundColor Black -BackgroundColor Green "Configuring server..."
        
        # Check if the network adapter exists
        $networkAdapter = Get-NetAdapter | Where-Object { $_.Name -eq $interfaceAlias }

        if ($networkAdapter)
        {
            # Remove existing IP configurations
            Remove-NetIPAddress -InterfaceAlias $interfaceAlias -Confirm:$false
            Remove-NetRoute -InterfaceAlias $interfaceAlias -Confirm:$false
            Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ResetServerAddresses
        }
        else
        {
            Write-Host -ForegroundColor Black -BackgroundColor White "Network adapter not found. Ensure the correct interface alias ('$interfaceAlias') is used."
            return
        }

        # Configure the new IP settings
        New-NetIPAddress -InterfaceAlias $interfaceAlias -DefaultGateway $defaultGateway -IPAddress $ipAddress -PrefixLength 24
        Set-DnsClientServerAddress -InterfaceAlias $interfaceAlias -ServerAddresses $dnsServers
        Set-NetIPInterface -InterfaceAlias $interfaceAlias -InterfaceMetric 1
        Set-NetRoute -InterfaceAlias $interfaceAlias -DestinationPrefix 0.0.0.0/0 -NextHop $defaultGateway
    
        Write-Host -ForegroundColor Black -BackgroundColor Green "IP configuration completed."
        Join-Domain
    }
    elseif ($prompt -eq 'n')
    {
        Write-Host -ForegroundColor Black -BackgroundColor Yellow "Exiting..."
    }
    elseif ($prompt -ne 'y' -or 'n')
    {
        Write-Host -ForegroundColor Black -BackgroundColor Red "Invalid input. Please enter 'y' or 'n'."
        Configure-IPSettings
    }
} 

function Join-Domain
{
    # Set the domain name
    $DomainName = "upgf.com"

    # Prompt for credentials
    $DomainCredential = Get-Credential -Message "Domain Credentials"

    # Set the new computer name
    $NewName = Read-Host -Prompt "Enter the new server name"
    $attempts = 0

    while ($attempts -lt 5)
    {        
        $JoinAttempt = JoinDomainAttempt -NewName $NewName -DomainName $DomainName -DomainCredential $DomainCredential

        if ($JoinAttempt -eq $true)
        {
            # Success message
            Write-Host -ForegroundColor Black -BackgroundColor Green "Server renamed and joined to the domain with DNS Suffix $DomainName."
           
            # Disable Scheduled Tasks
            Write-Host -ForegroundColor Black -BackgroundColor White "Disabling Scheduled Tasks..."
            Disable-ScheduledTask -TaskName "Configure Script 2" -Verbose

            # Reboot Server
            Write-Host -ForegroundColor Black -BackgroundColor Green "Server rebooting..."
            Restart-Computer
            break
        }
        else
        {
            # Failure message
            Write-Host -ForegroundColor Black -BackgroundColor Red "Error: Failed to join the domain. Please enter a different name for the server."
            $NewName = Read-Host -Prompt "Enter the new server name"
            $attempts++
        }
    }

    if ($attempts -ge 5)
    {
        Write-Host -ForegroundColor Black -BackgroundColor Red "Max attempts reached. Server was not joined to the domain."
    }
}

function JoinDomainAttempt
{
    param (
        [string]$NewName,
        [string]$DomainName,
        [PSCredential]$DomainCredential
    )

    # Check if the machine name is available using Test-Connection
    $pingResult = Test-Connection -ComputerName $NewName -Count 1 -ErrorAction SilentlyContinue

    if ($pingResult.StatusCode -eq 0)
    {
        Write-Host -ForegroundColor Black -BackgroundColor Red "Error: Machine name '$NewName' is already in use. Please enter a different name for the server."
        return $false
    }
        $join = Add-Computer -DomainName $DomainName -Credential $DomainCredential -ErrorAction Stop
        $rename = Rename-Computer -NewName $NewName -DomainCredential $DomainCredential -ErrorAction Stop

    try
    {
        $join
        if ($?)
        {
            Write-Host -ForegroundColor Black -BackgroundColor Green "Domain Joined..."
            try
            {
                $rename
                if($?)
                {
                    Write-Host -ForegroundColor Black -BackgroundColor Green "Server renamed and joined to the domain with DNS Suffix $DomainName."
                    # The Rename-Computer cmdlet completed 
                    return $true
                }
            }
            catch
            {
                # An error occurred during the renaming process
                Write-Host "Error: $_"
            }
        }
        else
        {
            Write-Host -ForegroundColor Black -BackgroundColor Red "Error: Failed to join the domain or rename the computer."
            return $false
        }
    }
    catch
    {
        Write-Host -ForegroundColor Black -BackgroundColor Red "Error: $_"
        return $false
    }
}

# Test IP against existing 
function Test-IPAvailability
{
    param (
        [string]$IPAddress
    )
    
    $pingResult = Test-Connection -ComputerName $IPAddress -Count 1 -ErrorAction SilentlyContinue
    $nbtstatResult = Invoke-Expression "nbtstat -a $IPAddress" -ErrorAction SilentlyContinue
    if ($pingResult.StatusCode -ne 0)
    {
        if ($nbtstatResult -match "Host not found.")
        {
            $true
            Write-Host "$IPAddress is available for use." -BackgroundColor Green -ForegroundColor Black

            # # Export the IP immediately upon verification
            # $exportData = [PSCustomObject]@{
            #     IPAddress = $IPAddress
            # }
            # $exportData | Export-Excel -Path "\\opnasi02\Server\Tom\scripts\xlsx\available_ips.xlsx" -WorksheetName "AvailableIPs" -AutoSize -FreezeTopRow
            # # IP Address Available
        }
        else
        {
            $false
            Write-Host "$IPAddress is not available for use." -BackgroundColor White -ForegroundColor Black
             # IP Address Not Available
        }
    }
    else
    {
        $false
        Write-Host "$IPAddress is not available for use." -BackgroundColor White -ForegroundColor Black
        # IP Address Not Available
    }
}

function Test-IPAddress {
    param (
        [string]$IPAddress
    )

    $IsValid = Test-IPAvailability -IPAddress $IPAddress

    return $IsValid
}

$askFirst = Read-Host -Prompt "Do you need to [C]onfigure TCP/IP Settings or just [J]oin the domain?"
if ($askfirst -eq 'c')
    {
        Write-Host -ForegroundColor Black -BackgroundColor Yellow "ENABLE THE NETWORK ADPATER IN VSPHERE BEFORE MOVING FORWARD"
        Configure-IPSettings
    }
    elseif ($askFirst -eq 'j')
    {
        Join-Domain
    }
