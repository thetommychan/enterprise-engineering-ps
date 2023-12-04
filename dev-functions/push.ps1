# push files to file server

function push
{
    param(
        [Parameter(Mandatory)]
        [string[]]$File,
        [string]$Destination,
        [switch]$Overwrite
        )
# Variables
$source = 'C:\vscode\'
$fileServer = '\\opnasi02\server\tom\scripts'

    if ($Overwrite){
        Copy-Item -Path $source\$File $fileServer\$Destination -Force
    } else {
        Copy-Item -Path $source\$File $fileServer\$Destination
    }
}