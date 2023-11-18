# Modules Needed: VMWare PowerCLI

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

# Perform Steps
Get-AvailableIPs # Test all available IP addresses and export them to the spreadsheet
