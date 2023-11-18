# Start transcript to log the script's output
Start-Transcript -Path "C:\scripts\logs\addin-loader-script.log" -Append -IncludeInvocationHeader

try {
    # Get the current user's ID
    $userid = (Get-WmiObject -Class win32_process | Where-Object name -Match explorer).getowner().user

    # Define paths
    $usrRoamingFolder = "\\upgf.com\DFS-UPGF\ctx_users\$userid\redir\appdata\Microsoft\AddIns\TeamsMeetingAddIn"
    $localCopy = "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin"

    # Validate local copy of addin
    if (Test-Path "$localCopy\1.0.22304.2" -PathType Container -Verbose) {
	    if (!(Test-Path $UsrRoamingFolder -PathType Container -Verbose)) {
		    New-Item -ItemType Directory -Path "\\upgf.com\DFS-UPGF\ctx_users\$userid\redir\appdata\Microsoft\AddIns\TeamsMeetingAddIn"
		    }
        Copy-Item $localCopy $usrRoamingFolder -Force -Recurse -Verbose | Wait-Process
    }	

    # Installing Registry DLL if not present
    if (Test-Path "$usrRoamingFolder\1.0.22304.2" -PathType Container -Verbose) {
        # Register DLL
        $regsvr32Path = Join-Path $usrRoamingFolder\1.0.22304.2\x64 "Microsoft.Teams.AddinLoader.dll"
        Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s `"$regsvr32Path`"" -Wait -NoNewWindow
    }
} catch {
    Write-Host "Something went wrong: $_"
    # Log error to transcript
    $_ | Out-File -Append -FilePath "C:\scripts\logs\addin-loader-script.log"
} finally {
    # Stop the transcript
    Stop-Transcript
}