
[CmdletBinding()]
param(
    [string]$ADID
)

function Remove-Session1Hep
{
    [CmdletBinding()]
    param(
        [string]$ADID
    )

    # Construct the path to the Session1.hep file
    $filePath = "\\opnasi02\users\$ADID\Hummingbird\Connectivity\13.00\Profile\Session1.hep"

    # Check if the file exists before attempting to delete it
    if (Test-Path -Path $filePath -PathType Leaf)
    {
        Remove-Item -Path $filePath -Force
        Write-Host -ForegroundColor Green "Session1.hep file for user $ADID has been deleted."
    }
    else
    {
        Write-Host -ForegroundColor Yellow "Session1.hep file for user $ADID not found or already deleted."
    }
} Remove-Session1Hep -ADID $ADID
