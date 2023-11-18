# Connect to the server and update spreadsheet
$creds = get-credential
connect-VIServer -Server opvvca01.upgf.com -Credential $creds

# Specify the path to your XLSX file
$excelPath = "C:\vscode\vSphere\VLANs\vm_ip_export.xlsx"

# Import the Excel file
$vmData = Import-Excel -Path $excelPath

# Ensure the 'IPAddress' column is properly split
$vmData = $vmData | ForEach-Object {
    $_.IPAddress = ($_.IPAddress -split '\|')[0].Trim()
    $_
}
# Create an array of all possible IP addresses
$rangeStart = 1
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
# Function to test IP availability
function Test-IPAvailability {
    param (

        [string]$IPAddress
    )
    
    $pingResult = Test-Connection -ComputerName $IPAddress -Count 1 -ErrorAction SilentlyContinue | Select-Object StatusCode
    $nbtstatResult = Invoke-Expression "nbtstat -a $IPAddress" #-ErrorAction SilentlyContinue

    if ($pingResult -notmatch "0") {
        if ($nbtstatResult -match "Host not found.") {
            "Available"
            return $true  # IP Address Available
        } else {
            "Not Available"
            return $false  # IP Address Not Available
        }
    } else {
        "Not Available"
        return $false  # IP Address Not Available
    }
}

# Test and output available IPs to a new XLSX file
$availableIPs = $arrayb | Where-Object { Test-IPAvailability -IPAddress $_ }

# Create an array of custom objects for export
$exportData = $availableIPs | ForEach-Object {
    [PSCustomObject]@{
        IPAddress = $_
    }
}

# Specify the path for the output XLSX file
$outputXLSXPath = "C:\vscode\vSphere\VLANs\available_ips.xlsx"

# Export available IPs to a new XLSX file
$exportData | Export-Excel -Path $outputXLSXPath -WorksheetName "AvailableIPs" -AutoSize -FreezeTopRow
