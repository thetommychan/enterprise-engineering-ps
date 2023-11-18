# SID for user whose login history is being queried
$checkuser = '*nfed018*'

# Get information about the user logon history for the last 'n' days
$startDate = (get-date).AddDays(-2)
$DCs = Get-ADDomainController -Filter *

foreach ($DC in $DCs)
    {
    $logonevents = Get-WinEvent -LogName Security -ComputerName $dc.HostName | Where-Object {$_.InstanceId -eq 4624::$_.Timecreated -gt $startDate}
    foreach ($event in $logonevents)
        {
        if (($event.ReplacementStrings[5] -notlike '*$') -and ($event.ReplacementStrings[5] -like $checkuser)) 
        {
            
            # Remote (Logon Type 10)
            if ($event.ReplacementStrings[8] -eq 10)
            {
            write-host "Type 10: Remote Logon`tDate: "$event.TimeGenerated "`tStatus: Success`tUser: "$event.ReplacementStrings[5] "`tWorkstation: "$event.ReplacementStrings[11] "`tIP Address: "$event.ReplacementStrings[18] "`tDC Name: " $dc.Name
            }
            
            # Network(Logon Type 3)
            if ($event.ReplacementStrings[8] -eq 3)
            {
            write-host "Type 3: Network Logon`tDate: "$event.TimeGenerated "`tStatus: Success`tUser: "$event.ReplacementStrings[5] "`tWorkstation: "$event.ReplacementStrings[11] "`tIP Address: "$event.ReplacementStrings[18] "`tDC Name: " $dc.Name
            }
        }
    }
}