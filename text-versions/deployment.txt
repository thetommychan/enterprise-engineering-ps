# Plug-in PowerShell Deployment Script: Just replace the source/destination variables with the source and destination of the files being modified in the
# environment and run the script as administrator.

# Variables
$dest = "\\server\path$\to\destination\files"
$source = "\\server\path$\to\source\files"
$dest1 = Get-ChildItem $dest
$source1 = Get-ChildItem $source
$verify = Write-Host -BackgroundColor Yellow -ForegroundColor Black "The files being modified are as follows:" 

# Verify the source and destination files being deployed (to)
$verify
Write-Host -BackgroundColor Yellow -ForegroundColor Black "`nDestination:"
$dest1
Write-Host -BackgroundColor Yellow -ForegroundColor Black "Source:"
$source1

# Deploy new files to destination if the file paths are correct
$deployment =  Read-Host -Prompt "`nDeploy the source to the destination? y to continue, enter to skip"
if ($deployment -eq 'y') {
 
    Get-ChildItem $dest -Include *.* -File -Recurse | ForEach-Object {$_.Delete()}
    Get-ChildItem $source -Include *.* -File -Recurse | Copy-Item -Destination $dest

    Get-ChildItem $dest
    Write-Host -BackgroundColor Green -ForegroundColor Black "Deployment completed successfully!"
    Read-Host -Prompt "Press Enter to exit..."

} else {
    
    Write-Host -BackgroundColor Yellow -ForegroundColor Black "The deployment has not been performed. Window is closing in 5 seconds"
    Start-Sleep -Seconds 5

}