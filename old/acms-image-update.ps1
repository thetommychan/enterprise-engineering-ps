# Promotion PowerShell Script.
# This script is designed to pull the latest applicaton image from the Release directory and automatically deploy it to the necessary environment
# PRE-REQUISITES:
# 1. Copy a link to the release directory to your ZDT/Local Jump Host, and try to make it as easily navigable as possible; 
#    ex. U:\Application\, and inside should be all the versioned app folders synced with the release directory in SharePoint
# 2. Update this script's $newImage variable in the 'while' loop to match the location of the release directory that's been copied to your ZDT/Jump Host drive
# DIRECTIONS
#


# variables
$drive = $pwd
$env = Read-Host -Prompt "Which Environment?: dev/test/int/qa/stage/proto" -ErrorAction Ignore
$s1 = '\\server1\c$\Program Files\Ingres\ingresXH\ingres'
$s2 = '\\server2\c$\Program Files\Ingres\ingresXH\ingres'
$s3 = '\\server3\c$\Program Files\Ingres\ingresXH\ingres'
$dest = @($s1, $s2, $s3)
$ver = Read-Host -Prompt "Version Number?"
$newImage = $drive + 'path\to' + $ver + '\img_file.img'
$details = Get-ChildItem $newImage -ErrorAction Ignore |  Select-Object -Property Name, CreationTime, LastWriteTime 

# Verify new image exists
while ($var -ne 1) {  
    if (Test-Path -Path $newImage) {
    break
    }
    Write-Host "The .img file defined does not exist or is not available. Please ensure release number `nvalidity, or modify the file path to the release directory in this script to ensure intregrity" -ForegroundColor Red -BackgroundColor Black
    Write-Host -ForegroundColor Black -BackgroundColor Yellow "OPERATION CANCELLED"
    start-sleep 5
    exit
    }

#Verify Image Details
write-host -ForegroundColor Black -BackgroundColor Green $details

# Verify image is most recent
while ($true) {
    if(Get-Childitem $newImage  | Where {$_.LastWriteTime -ge (get-date).addDays(-3)}) {
    Break 
    }
    $cont = Read-Host -Prompt "Are you sure this is the file you'd like to promote to $env`? y/n"
    if ($cont -eq 'n') { 
    write-host -ForegroundColor Black -BackgroundColor Yellow "OPERATION CANCELLED"
    start-sleep 5
    exit
    } else {
     break
    }  
}

# Create temp directory
function Set-DeploymentEnvironment {
        mkdir 'U:\temp' -Force
        cp $newImage 'U:\temp' -Force -Recurse
        cd 'U:\temp'
        dir | Rename-Item -NewName {$_.Basename + '_' + $env + $_.Extension}
        cd $drive
     }
Set-DeploymentEnvironment;

# Deploy new image to appropriate environment
$dest | ForEach-Object { Copy-Item -Path 'U:\temp\*.img' -Destination (Join-Path $_ $destFileName) -Force -Recurse}

# Destroy temp dir
function Remove-TempDirectory {
    start-sleep 3
    del 'U:\temp' -Force -Recurse
    }
Remove-TempDirectory;

# Verify files were copied in correct format
write-host $dest
