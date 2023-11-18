$services = HKLM:\SYSTEM\CurrentControlSet\Services\ # if ($services.DisplayName.Startswith('Ora'))
$odbc6 = HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\q010b
$odbc5 = HKLM:\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\q010
$odbc4 = HKLM:\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\q009
$odbc3 = HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBC.INI\q010b
$odbc2 = HKLM:\SOFTWARE\ODBC\ODBC.INI\q010
$odbc1 = HKLM:\SOFTWARE\ODBC\ODBC.INI\q009
$reg4 = HKLM:\SOFTWARE\ORACLE
$reg3 = HKCR:\CLSID\{057ca4ef-9ff1-49e1-90e4-914148f62551}
$reg2 = HKCR:\TypeLib\{13DABBE3-4594-426B-A54A-7D1640F4A9A9}
$reg1 = HKLM:\SOFTWARE\Microsoft\Fusion\PublisherPolicy\Default\v4.0_Policy.4.112.Oracle.Web__89b483f429c47342
$cmdServices = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\'
$codbc6 = 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\q010b'
$codbc5 = 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\q010'
$codbc4 = 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\q009'
$codbc3 = 'HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBC.INI\q010b'
$codbc2 = 'HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBC.INI\q010'
$codbc1 = 'HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBC.INI\q009'
$creg4 = 'HKEY_LOCAL_MACHINE\SOFTWARE\ORACLE'
$creg3 = 'HKEY_CURRENT_USER\CLSID\{057ca4ef-9ff1-49e1-90e4-914148f62551}'
$creg2 = 'HKEY_CURRENT_USER\TypeLib\{13DABBE3-4594-426B-A54A-7D1640F4A9A9}'
$creg1 = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Fusion\PublisherPolicy\Default\v4.0_Policy.4.112.Oracle.Web__89b483f429c47342'

#stop service
if ($winServ)
{
    $winServ | Stop-Service -Verbose
}
    else
{
    Write-Host "$winServ not present"
}

# Stop AppPools
if ($appPools)
{
    $appPools | Stop-WebAppPool -Verbose
}
    else
{
    Write-Host "$appPools not present"
}

# Clear Registry
if (test-path $reg1)
{
    Invoke-Command  {reg export $creg1 C:\users\qqq9xmb\desktop\reg1.reg}
    Remove-Item -Path $reg1 -Force -Verbose
}
    else
{
    Write-Host "$reg1 not present"
}

# Clear Registry
if ($reg2)
{
    Invoke-Command  {reg export $creg2 C:\users\qqq9xmb\desktop\reg2.reg}
    Remove-Item -Path $reg2 -Force -Verbose
}
    else
{
    Write-Host "$reg2 not present"
}

# Clear Registry
if (test-path $reg3)
{
    Invoke-Command  {reg export $creg3 C:\users\qqq9xmb\desktop\reg3.reg}
    Remove-Item -Path $reg3 -Force -Verbose
}
    else
{
    Write-Host "$reg3 not present"
}

# Clear Registry
if (test-path $odbc1)
{
    Invoke-Command  {reg export $codbc1 C:\users\qqq9xmb\desktop\odbc1.reg}
    Remove-Item -Path $odbc1 -Force -Verbose
}
    else
{
    Write-Host "$odbc1 not present"
}

# Clear Registry
if (test-path $odbc2)
{
    Invoke-Command  {reg export $codbc2 C:\users\qqq9xmb\desktop\odbc2.reg}
    Remove-Item -Path $odbc2 -Force -Verbose
}
    else
{
    Write-Host "$odbc2 not present"
}

# Clear Registry
if (test-path $odbc3)
{
    Invoke-Command  {reg export $codbc3 C:\users\qqq9xmb\desktop\odbc3.reg}
    Remove-Item -Path $odbc3 -Force -Verbose
}
    else    
{
    Write-Host "$odbc3 not present"
}

# Clear Registry
if (test-path $odbc4)
{
    Invoke-Command  {reg export $codbc4 C:\users\qqq9xmb\desktop\odbc4.reg}
    Remove-Item -Path $odbc4 -Force -Verbose
}
    else
{
    Write-Host "$odbc4 not present"
}

# Clear Registry
if (test-path $odbc5)
{
    Invoke-Command  {reg export $codbc5 C:\users\qqq9xmb\desktop\odbc5.reg}
    Remove-Item -Path $odbc5 -Force -Verbose
}
    else
{
    Write-Host "$odbc5 not present"
}

# Clear Registry
if (test-path $odbc6)
{
    Invoke-Command  {reg export $codbc6 C:\users\qqq9xmb\desktop\odbc6.reg}
    Remove-Item -Path $odbc6 -Force -Verbose
}
    else
{
    Write-Host "$odbc6 not present"
}


if ($services.DisplayName.Startswith('Ora'))
{
    Invoke-Command  {reg export $cmdServices C:\users\qqq9xmb\desktop\odbc6.reg}
    #Remove-Item -Path $odbc6 -Force -Verbose
}
    else
{
    Write-Host "$services not present"
}