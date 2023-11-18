
#  WSH - 2022-06-13
#   This is a slightly modified version of the script in the "Workaround" folder.

# Create Teams Add-In Directory
function Get-TeamsAddin {
$usrRoamingFolder = "C:\Users\$env:username\AppData\Roaming\Microsoft\AddIns\TeamsMeetingAddin"
$localCopy = "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin\1.0.23061.1"
if (Test-Path $usrRoamingFolder){
        break;
    } else {
        mkdir $usrRoamingFolder
        Write-Host $usrRoamingFolder
        cp $localCopy $usrRoamingFolder -Force -Recurse
        regsvr32.exe /n /i:user /s "C:\Users\$env:username\AppData\Roaming\Microsoft\AddIns\TeamsMeetingAddin\1.0.23061.1\x64\Microsoft.Teams.AddinLoader.dll"
    }
} Get-TeamsAddin



#WSH (01A) - 2022-07-27 
#   Making all launches of this script run through the registry updates

$userid = $env:UserName

#01A# $member = get-adgroupmember -Identity "TForce_SwitchedUsers" | where {$_.name -eq $userid}
#01A#    If ($member) { 

$app = start-process -WindowStyle hidden  -filepath "c:\Program Files\Microsoft Office 2016\Office16\WinWord.EXE" -passthru
wait-process -id $app.id  -timeout 3
$processes = get-process -pid $app.id | Foreach-Object {$_.CloseMainWindow() | out-null}
###### (get-process -pid $app.id).CloseMainWindow() | out-null
If(get-process -pid $app.id) {get-process -pid $app.id | stop-process -force }
wait-process -id $app.id -timeout 3
start-process -wait "\\upgf.com\dfs-upgf\upgf_files\Published\Outlook\profile.bat"
start-process "c:\Program Files\Microsoft Office 2016\Office16\OUTLOOK.EXE" -argumentlist " /profile TFF_Outlook" 

write-host "O365"
#01A#    }
#01A#    Else {start-process "c:\Program Files\Microsoft Office 2016\Office16\OUTLOOK.EXE"}






