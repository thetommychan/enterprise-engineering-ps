function Test-ServerName
{
    param
    (
        [string]$serverName
    )
    # Ping server name and respond true or false if unable to connect
    $ping = Test-NetConnection -ComputerName $serverName
    if ($ping.PingSucceeded -eq $true)
    {
            Write-Host "Valid Machine: $serverName" -BackgroundColor Green -ForegroundColor Black
            return $true
    }
    else
    {
        Write-Host "Cannot ping $serverName..." -BackgroundColor White -ForegroundColor Black
        return $false
    }
}


# Specify the computer name and the target OU's DistinguishedName
$serverName = Read-Host -Prompt "Enter the server/computer name"
$nametest = Test-ServerName -Server $serverName

if ($nametest -eq $true)
{
    # Envrionments
$test = "OU=AppServers_Test,OU=SysMgmt,DC=upgf,DC=com"
$prod = "OU=AppServers,OU=SysMgmt,DC=upgf,DC=com"

# Display current OU
$dn = Get-ADComputer -Identity $serverName | Select-Object -property DistinguishedName -ExpandProperty DistinguishedName | Out-String
$OU = $dn -replace '.+?,OU=(.+?),(?:OU|DC)=.+','$1'
Write-Host -ForegroundColor Black -BackgroundColor White "The specified server's current OU is $OU."

# Prompt for OU
$targetOU = Read-Host -Prompt "Moving to Test or Prod OU? (t/p)"

if ($targetOU -eq 't')
{
    $dnServer = Get-ADComputer -Filter {Name -eq "$serverName"}
    if (!($dnServer.DistinguishedName -like "CN=$serverName,OU=AppServers_Test,OU=SysMgmt,DC=upgf,DC=com"))
    {
        # Move the computer to Test OU
        $objectGUID = Get-ADComputer -Identity $serverName | Select-Object -Property ObjectGUID -ExpandProperty ObjectGUID
        Move-ADObject -Identity $objectGUID -TargetPath $test
        Write-Host "Machine '$serverName' moved to $test."
    }
    else
    {
        Write-Host -ForegroundColor Black -BackgroundColor White "Server already exists in Test OU."
    }
    
}
elseif ($targetOU -eq 'p')
{
    $dnServer = Get-ADComputer -Filter {Name -eq "$serverName"}
    if (!($dnServer.DistinguishedName -like "CN=$serverName,OU=AppServers,OU=SysMgmt,DC=upgf,DC=com"))
    {
        # Move the computer to Test OU
        $objectGUID = Get-ADComputer -Identity $serverName | Select-Object -Property ObjectGUID -ExpandProperty ObjectGUID
        Move-ADObject -Identity $objectGUID -TargetPath $prod
        Write-Host "Machine '$serverName' moved to $prod."
    }
    else
    {
        Write-Host -ForegroundColor Black -BackgroundColor White "Server already exists in Prod OU."
    }
}
}

# May add functionality to batch/individual delete servers in the future... 