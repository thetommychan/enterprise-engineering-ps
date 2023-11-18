# Prompt for the username
$username = Read-Host "Enter the ADID whose HEP file should be deleted"

# Construct the path to the Session1.hep file
$filePath = "\\opnasi02\users\$username\Hummingbird\Connectivity\13.00\Profile\Session1.hep"

# Check if the file exists before attempting to delete it
if (Test-Path -Path $filePath -PathType Leaf)
{
    Remove-Item -Path $filePath -Force
    Write-Host "Session1.hep file for user $username has been deleted."
}
else
{
    Write-Host "Session1.hep file for user $username not found or already deleted."
}
