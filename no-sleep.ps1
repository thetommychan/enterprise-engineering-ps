Write-Host "Keep your work session alive (:"

Start-Sleep -seconds 3

Write-Host "To end this script, close the window"

$WShell = New-Object -com "Wscript.Shell"

while ($true)

{

$WShell.sendkeys("{SCROLLLOCK}")
Start-Sleep -Milliseconds 100
$WShell.sendkeys("{SCROLLLOCK}")
Start-Sleep -Seconds 240

}