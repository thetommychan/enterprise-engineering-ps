$Computers =  Get-ADComputer  -Filter {(enabled -eq "true") -and (OperatingSystem -Like "*Windows 10*")} | Select-Object -ExpandProperty Name
foreach($Computer in $Computers) {

    Get-CimInstance Win32_ComputerSystem -ComputerName $Computer | Select-Object -ExpandProperty UserName

}