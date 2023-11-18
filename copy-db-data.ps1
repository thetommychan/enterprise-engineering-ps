# Copy MSSQLSERVER.CMSDENALI folder from current production server to working server
# Variables
$sqlSource = '\\wposda03\c$\Program Files\Microsoft SQL Server\MSSQL11.CMSDENALI\'
$sqlDestination = 'C:\Program Files\Microsoft SQL Server\'
$sourceFiles = 

# If the file exists already, update SQL files
if (-not (test-path '$sqlDestination\MSSQL11.CMSDENALI'))
    {
        Copy-Item $sqlSource $sqlDestination -Force -Recurse -Verbose
        Write-Host -ForegroundColor Black -BackgroundColor green "SQL Data copied"
    }
    else
    {

    }