# Create Teams Add-In Directory
function Get-TeamsAddin {

    param (
        [string]$addinDest,
        [string]$addinSource,
        [string]$newProfilePath
    )
    # Get the current user's ID
    $userid = (Get-WmiObject -Class win32_process | Where-Object name -Match explorer).getowner().user[0]

    # Define paths
    $usrRoamingFolder = "\\upgf.com\DFS-UPGF\ctx_users\$userid\redir\appdata\Microsoft\AddIns\TeamsMeetingAddIn"
    $localCopy = "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin"

    # Validate local copy of addin
    if (!(Test-Path "$localCopy\1.0.22304.2" -PathType Container -Verbose)) {
        if (!(Test-Path $UsrRoamingFolder -PathType Container -Verbose)) {
            New-Item -ItemType Directory -Path "\\upgf.com\DFS-UPGF\ctx_users\$userid\redir\appdata\Microsoft\AddIns\TeamsMeetingAddIn"
            }
        Copy-Item $localCopy $usrRoamingFolder -Force -Recurse -Verbose | Wait-Process
    } 
}
Get-TeamsAddin -addinDest $usrRoamingFolder -addinSource $localCopy

# Get available IPs from spreadsheet

function Get-AvailableIPs 
{
    # Specify the path to your XLSX file
    $excelPath = "\\opnasi02\Server\Tom\scripts\xlsx\vm_ip_export.xlsx"

    # Import the Excel file
    $vmData = Import-Excel -Path $excelPath

    # Ensure the 'IPAddress' column is properly split
    $vmData = $vmData | ForEach-Object {
        $_.IPAddress = ($_.IPAddress -split '\|')[0].Trim()
        $_
    }

    # Create an array of all possible IP addresses
    $rangeStart = 30
    $rangeEnd = 254
    $arrayb = $rangeStart..$rangeEnd | ForEach-Object { "10.14.11.$_" }

    # Iterate through the IP addresses in $vmData
    $vmData | ForEach-Object {
        $ipAddress = $_.IPAddress
        if ($ipAddress -match '^10\.14\.11\.(\d+)$')
        {
            $usedIP = [int]::Parse($Matches[1])
            $arrayb = $arrayb | Where-Object { $_ -ne "10.14.11.$usedIP" }
        }
    }

    # Call the Test-IPAvailability function for each IP address in $arrayb
    $arrayb | ForEach-Object {
        $ipAddress = $_
        Test-IPAvailability -IPAddress $ipAddress
    }
}

# Function to test IP availability
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
            Write-Host "$IPAddress is available for use." -BackgroundColor Green -ForegroundColor Black

            # Export the IP immediately upon verification
            $exportData = [PSCustomObject]@{
                IPAddress = $IPAddress
            }
            $exportData | Export-Excel -Path "\\opnasi02\Server\Tom\scripts\xlsx\available_ips.xlsx" -WorksheetName "AvailableIPs" -AutoSize -FreezeTopRow
            # IP Address Available
        }
        else
        {
            Write-Host "$IPAddress is not available for use." -BackgroundColor White -ForegroundColor Black
             # IP Address Not Available
        }
    }
    else
    {
        Write-Host "$IPAddress is not available for use." -BackgroundColor White -ForegroundColor Black
        # IP Address Not Available
    }
}

# Configure TCP/IP settings on server for 10.14.11.x IP address and join to domain

function Configure-IPSettings
{
    # Variables
    $ipAddress = Read-Host -Prompt "Enter an IP Address from the VM-IPFinder.ps1 at \\opnasi02\server\tom\scripts"
    $subnetMask = "255.255.255.0"
    $interfaceAlias = "Ethernet1"
    $defaultGateway = "10.14.11.10"
    $dnsServers = "10.14.11.165", "10.14.11.171"  # Replace with your DNS server addresses

    # Confirm the settings
    $prompt = Read-Host -Prompt "`nIP Address: $ipAddress `nDefault Gateway: $defaultGateway `nSubnet Mask: $subnetMask `nDNS Server(s): $dnsServers `nInterface: $interfaceAlias `nDoes this look right? (y/n)"

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
} Configure-IPSettings