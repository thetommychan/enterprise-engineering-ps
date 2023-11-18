function Get-XMLModule
{
    $exist = get-module -ListAvailable | Where-Object {$_.Name -like "xmlcontentdsc"}
    if (!($exist))
    {
        Install-Module -Name xmlcontentdsc;
        Import-Module -Name xmlcontentdsc;
        Write-Host -ForegroundColor Black -BackgroundColor Green "XML Module Successfully installed"
    }
        else
    {
        Write-Host -ForegroundColor Black -BackgroundColor Green "Module already installed, skipping..."
    }
}