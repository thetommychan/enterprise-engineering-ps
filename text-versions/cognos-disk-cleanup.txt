# Delete folders taking up space in Cognos App Servers

# Gather count of total folders to be deleted
$aicp = gci -Path D:\cognos_data\AICP\Cubes\ -Directory -Exclude -File | Measure-Object
$depotmaint = gci -Path D:\cognos_data\Depot_Maint\Cubes\ -Directory -Exclude -File | Measure-Object
$depotsupp = gci -Path D:\cognos_data\Depot_Supply\Cubes\ -Directory -Exclude -File | Measure-Object
$eal = gci -Path D:\cognos_data\EAL\Cubes\ -Directory -Exclude -File | Measure-Object
$fltops = gci -Path D:\cognos_data\FltOps\Cubes\ -Directory -Exclude -File | Measure-Object
$proc = gci -Path D:\cognos_data\Procurement\Cubes\ -Directory -Exclude -File | Measure-Object
$rcm = gci -Path D:\cognos_data\RCM\Cubes\ -Directory -Exclude -File | Measure-Object
$wtc = gci -Path D:\cognos_data\Wtc_770\Cubes\ -Directory -Exclude -File | Measure-Object

# Assign Variables to folders (workaround to be able to modify the actual ps objects without measurements)
$aicp1 = gci -Path D:\cognos_data\AICP\Cubes\ -Directory -Exclude -File
$depotmaint1 = gci -Path D:\cognos_data\Depot_Maint\Cubes\ -Directory -Exclude -File
$depotsupp1 = gci -Path D:\cognos_data\Depot_Supply\Cubes\ -Directory -Exclude -File
$eal1 = gci -Path D:\cognos_data\EAL\Cubes\ -Directory -Exclude -File
$fltops1 = gci -Path D:\cognos_data\FltOps\Cubes\ -Directory -Exclude -File
$proc1 = gci -Path D:\cognos_data\Procurement\Cubes\ -Directory -Exclude -File
$rcm1 = gci -Path D:\cognos_data\RCM\Cubes\ -Directory -Exclude -File
$wtc1 = gci -Path D:\cognos_data\Wtc_770\Cubes\ -Directory -Exclude -File
$folders = $aicp, $depotmaint, $depotsupp, $eal, $fltops, $proc, $rcm, $wtc
$folders1 = $aicp1, $depotmaint1, $depotsupp1, $eal1, $fltops1, $proc1, $rcm1, $wtc1
$totals = $folders | Measure-Object -Sum -Property Count | Select-Object -expand Sum

#Prompt host to confirm total number of folders to be deleted
$confirm = Read-Host "Are you sure you would like to permanently delete $totals folders? y/n"
    if ($confirm -eq 'y') {
        Write-Host "Deleting $totals folders..."
        $folders1 | del -Force -Recurse
        Write-Host "Done!"
    } else {
        Write-Host "Cancelled..."
    }

