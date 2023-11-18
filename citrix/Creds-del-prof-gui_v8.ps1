# v5
$User = 'upgf.com\richadmin'
$pswd = ConvertTo-SecureString 'Gb#52xP4zw1' -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user,$pswd
$runuser="$env:userdomain\$env:username"
Start-Process -FilePath C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle hidden  -ArgumentList "-nologo -file \\opnasi02\server\tom\scripts\del-profile-form-v8.ps1 -runtimeuser $runuser" -Credential $cred
