$folder1 = "\\upgf.com\DFS-UPGF\ctx_users\NFED018\redir\appdata"
$folder2 = "\\upgf.com\DFS-UPGF\ctx_users\NFED018\redir\appdata.old"

$folder1Items = Get-ChildItem $folder1 -Recurse
$folder2Items = Get-ChildItem $folder2 -Recurse


Compare-Object -ReferenceObject $folder1Items -DifferenceObject $folder2Items -Property Name -IncludeEqual



$userid = $env:UserName
#(tai) Create Teams Add-In Directory
$usrRoamingFolder = "C:\Users\$userid\AppData\Roaming\Microsoft\AddIns\TeamsMeetingAddin"
$localCopy = "C:\Program Files (x86)\Microsoft\TeamsMeetingAddin\1.0.23061.1"
if (Test-Path $usrRoamingFolder\Microsoft.Teams.AddinLoader.dll){
        #c:\Windows\System32\regsvr32.exe $usrRoamingFolder\Microsoft.Teams.AddinLoader.dll
        continue
    } else {
        mkdir $usrRoamingFolder
        mkdir $usrRoamingFolder\1.0.23061.1
        Write-Host $usrRoamingFolder
        cp $localCopy\* $usrRoamingFolder\1.0.23061.1 -Force -Recurse
        c:\Windows\System32\regsvr32.exe $usrRoamingFolder\Microsoft.Teams.AddinLoader.dll
    }