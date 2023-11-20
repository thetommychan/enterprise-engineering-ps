# Modules Needed: VMWare PowerCLI

function Get-AvailableIPs
{
    # Specify the path to your XLSX file
    $excelPath = "\\opnasi02\Server\Tom\Scripts\xlsx\vm_ip_export.xlsx"

    # Import the Excel file with custom headers
    $vmData = import-excel $excelPath -WorksheetName Sheet1 -ImportColumns @(3)

    # Create an array of all possible IP addresses
    $rangeStart = 30
    $rangeEnd = 254
    $arrayb = $rangeStart..$rangeEnd | ForEach-Object { "10.14.11.$_" }

    # Iterate through the IP addresses in $vmData
    $vmData | ForEach-Object {
        $ipAddress = $_.IPAddress
        if ($ipAddress -match '^10\.14\.11\.(\d+)$') {
            $usedIP = [int]::Parse($Matches[1])
            $arrayb = $arrayb | Where-Object { $_ -ne "10.14.11.$usedIP" }
        }
    }

    # Create an array to store available IPs
    $availableIPs = @()

    # Check the IP availability and add to the $availableIPs array
    $arrayb | ForEach-Object {
        $ipAddress = $_
        if (Test-IPAvailability -IPAddress $ipAddress) {
            $availableIPs += [PSCustomObject]@{
                IPAddress = $ipAddress
            }
        }
    }

    # Export all available IPs to Excel
    $availableIPs | Export-Excel -Path "\\opnasi02\Server\Tom\Scripts\xlsx\available_ips.xlsx" -WorksheetName "AvailableIPs" -AutoSize -FreezeTopRow
}

# Function to test IP availability
function Test-IPAvailability
{
    param (
        [string]$IPAddress
    )

    $pingResult = Test-Connection -ComputerName $IPAddress -Count 1 -ErrorAction SilentlyContinue
    $nbtstatResult = Invoke-Expression "nbtstat -a $IPAddress" -ErrorAction SilentlyContinue
    if ($pingResult.StatusCode -ne 0) {
        if ($nbtstatResult -match "Host not found.") {
            Write-Host "$IPAddress is available for use." -ForegroundColor Green
            return $true
        } else {
            Write-Host "$IPAddress is not available for use." -ForegroundColor White
            return $false
        }
    } else {
        Write-Host "$IPAddress is not available for use." -ForegroundColor White
        return $false
    }
}

# Ensure ImportExcel module is loaded
Import-Module ImportExcel

# Perform Steps
Get-AvailableIPs # Test all available IP addresses and export them to the spreadsheet
