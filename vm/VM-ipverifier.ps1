
function Test-IPAddress {
    param (
        [string]$IPAddress
    )

    $IsValid = Test-IPAvailability -IPAddress $IPAddress

    return $IsValid
}

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
function Test-IPAddressAvailability
{
    # Variables
    $IsIPAddressValid = $false

while (-not $IsIPAddressValid) {
    $IPAddress = Read-Host -Prompt "Enter an IP Address found on the available_ips.xlsx spreadsheet at \\opnasi02\Server\Tom\scripts\xlsx"

    $IsIPAddressValid = Test-IPAddress -IPAddress $IPAddress

    if (-not $IsIPAddressValid)
        {
            Write-Host -ForegroundColor Black -BackgroundColor White "Please try again."
        }
    }
} Test-IPAddressAvailability