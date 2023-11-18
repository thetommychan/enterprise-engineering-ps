function TestIP
{
    param
    (
        [string]$IPAddress
    )
    $pingResult = Test-Connection -ComputerName $IPAddress -Count 1 -ErrorAction SilentlyContinue | Select-Object ResponseTime
    $nbtstatResult = Invoke-Expression "nbtstat -a $IPAddress" -ErrorAction SilentlyContinue

    if (-not $pingResult)
    {
        if ($nbtstatResult -match "Host not found.")
        { # IP Address Available
            return $false
        }
        else 
        {
            return $true
        }
    }
    else
    { # IP Address not available
        return $true 
    } 
}

function Test-IPLoop
{
    do {
        $ipToTest = Read-Host "Enter an IP address for the server"
        $isValid = TestIP -IPAddress $ipToTest
        if ($isValid) {
            Write-Host "IP address $ipToTest is already in use"
        } else {
            Write-Host "IP address -$ipToTest- is available to use"
            return
        }
    } while ($true)
} Test-IPLoop