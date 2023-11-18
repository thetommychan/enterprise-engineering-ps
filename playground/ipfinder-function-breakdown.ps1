    # Specify the path to your XLSX file
    $excelPath = "\\opnasi02\Server\Tom\Scripts\xlsx\vm_ip_export.xlsx"

    # Import the Excel file with custom headers
    $vmData = import-excel $excelPath -WorksheetName Sheet1 -ImportColumns @(3) # import column 3 from excel doc

    # Create an array of all possible IP addresses
    $rangeStart = 30
    $rangeEnd = 254
    $arrayb = $rangeStart..$rangeEnd | ForEach-Object { "10.14.11.$_" }


        #### Start Raw Code ####
    $vmData | ForEach-Object {
        $ipAddress = $_.IPAddress
        if ($ipAddress -match '^10\.14\.11\.(\d+)$') {
            #$usedIP = [int]::Parse($Matches[1])
            $arraya = $arrayb | Where-Object { $_ -ne "10.14.11.$usedIP" }
        }
    }
        #### End Raw Code ####


####Testing####
$vmData | ForEach-Object {
    $ipAddress = $_.IPAddress
    if ($ipAddress -match '^10\.14\.11\.(\d+)$') {
        Write-Host $ipAddress}
    }



# building as job


$scriptBlock = {
    function Test-IPAvailability
    {
        param (
            [string]$IPAddress,
        )

        $pingResult = Test-Connection -ComputerName $using:IPAddress -Count 1 -ErrorAction SilentlyContinue
        $nbtstatResult = Invoke-Expression "nbtstat -a $IPAddress" -ErrorAction SilentlyContinue
        if ($pingResult.StatusCode -ne 0)
        {
            if ($nbtstatResult -match "Host not found.")
            {
                Write-Host "$IPAddress is available for use." -ForegroundColor Green
                return $true
            }
            else
            {
                Write-Host "$IPAddress is not available for use." -ForegroundColor White
                return $false
            }
        }
        else
        {
            Write-Host "$IPAddress is not available for use." -ForegroundColor White
            return $false
        }
    }
}
function Ping-Server
{
    param(
        [string]$IP
    )
    Start-Job -Name "ping1" -ScriptBlock {
        Test-IPAvailability
    } | Out-Null
    $id = Get-Job | Where-Object {$_.Name -eq "ping1"} | Select-Object Id -ExpandProperty Id
    Write-Host -ForegroundColor Yellow "Running ping 1"
    Wait-Job -Id $id | Out-Null
    Remove-Job -Name "ping1" | Out-Null
}
    
###################################################################################################

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

# Install Import-Excel module if not already installed
# Install-Module -Name ImportExcel -Force -AllowClobber

# Import the Excel module
#Import-Module ImportExcel

# Specify the path to your Excel file
$excelPath = "\\opnasi02\Server\Tom\Scripts\xlsx\vm_ip_export.xlsx"

# Load the IP addresses from the Excel file
$ipAddresses = import-excel $excelPath -WorksheetName Sheet1 -ImportColumns @(3)

# Define the script block to test the connection
$testConnectionScript = {
    param (
        [string]$ipAddress
    )

    function Test-IPAvailability
    {
        param (
            [string]$IPAddress
        )

        $pingResult = Test-Connection -ComputerName $using:IPAddress -Count 1 -ErrorAction SilentlyContinue
        $nbtstatResult = Invoke-Expression "nbtstat -a $IPAddress" -ErrorAction SilentlyContinue
        if ($pingResult.StatusCode -ne 0)
        {
            if ($nbtstatResult -match "Host not found.")
            {
                Write-Host "$IPAddress is available for use." -ForegroundColor Green
                return $true
            }
            else
            {
                Write-Host "$IPAddress is not available for use." -ForegroundColor White
                return $false
            }
        }
        else
        {
            Write-Host "$IPAddress is not available for use." -ForegroundColor White
            return $false
        }
    }

    # Output the IP address and whether the connection was successful
    [PSCustomObject]@{
        IPAddress = $ipAddress
        IsReachable = if (Test-IPAvailability) { $true } else { $false }
    }
}

function Set-BatchOptions
{
    param(
        [string]$batchSize
    )
    # Split the IP addresses into batches
    $ipAddresses | Group-Object -Property { [math]::floor($_.PSObject.Properties.MatchGroups[0].Value / $batchSize) } | Set-Variable -Name $
}

# Start parallel jobs for testing connections
$jobs = $batchSize | ForEach-Object
{
    $batch = $_.Group
    Start-Job -ScriptBlock $testConnectionScript -ArgumentList $batch
}

# Wait for all jobs to finish
$jobs | Wait-Job

# Retrieve and display the results of each job
$results = $jobs | Receive-Job
$results | Format-Table -AutoSize

# Clean up by removing the jobs
Remove-Job $jobs
####################################################################################################



####Testing####