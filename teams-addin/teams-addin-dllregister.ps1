# Start transcript to log the script's output
Start-Transcript -Path "C:\scripts\logs\addin-loader-script.log" -Append -IncludeInvocationHeader

# Register DLL
$regsvr32Path = Join-Path "C:\Program Files (x86)\Microsoft\TeamsMeetingAddIn\1.0.23061.1\x64" "Microsoft.Teams.AddinLoader.dll"
Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s `"$regsvr32Path`"" -Wait -NoNewWindow

