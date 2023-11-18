
#  WSH - 2022-06-13
#   This is a slightly modified version of the script in the "Workaround" folder.

#WSH (01A) - 2022-07-27 
#   Making all launches of this script run through the registry updates

#01A# $member = get-adgroupmember -Identity "TForce_SwitchedUsers" | where {$_.name -eq $userid}
#01A#    If ($member) { 

# $app1 = start-process -WindowStyle hidden  -filepath "c:\Program Files\Microsoft Office 2016\Office16\WinWord.EXE" -passthru
# wait-process -id $app1.id  -timeout 3
# $processes = get-process -pid $app1.id | Foreach-Object {$_.CloseMainWindow() | out-null}
# ###### (get-process -pid $app1.id).CloseMainWindow() | out-null
# If(get-process -pid $app1.id) {get-process -pid $app1.id | stop-process -force }
# wait-process -id $app1.id -timeout 3

$app2 = start-process -WindowStyle hidden  -filepath "C:\Program Files (x86)\Microsoft\Teams\current\Teams.exe" -passthru 
$app2
wait-process -id $app2.id  -timeout 3
$processes = get-process -pid $app2.id | Foreach-Object {$_.CloseMainWindow() | out-null}
$processes
###### (get-process -pid $app2.id).CloseMainWindow() | out-null
If(get-process -pid $app2.id) {get-process -pid $app2.id | stop-process -force }
wait-process -id $app2.id -timeout 3

start-process -wait "\\upgf.com\dfs-upgf\upgf_files\Published\Outlook\profile.bat"
start-process "c:\Program Files\Microsoft Office 2016\Office16\OUTLOOK.EXE" -argumentlist " /profile TFF_Outlook" 

write-host "O365"
#01A#    }
#01A#    Else {start-process "c:\Program Files\Microsoft Office 2016\Office16\OUTLOOK.EXE"}
