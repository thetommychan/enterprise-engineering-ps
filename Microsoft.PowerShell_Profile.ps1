$update = "PackageManagement","PowerShellGet","Git"
foreach($checkmodule in $update){
  #getting version of installed module
  $version = (Get-Module -ListAvailable $checkmodule) | Sort-Object Version -Descending  | Select-Object Version -First 1
  #converting version to string
  $stringver = $version | Select-Object @{n='ModuleVersion'; e={$_.Version -as [string]}}
  $a = $stringver | Select-Object Moduleversion -ExpandProperty Moduleversion
  #getting latest module version from ps gallery 
  $psgalleryversion = Find-Module -Name $checkmodule | Sort-Object Version -Descending | Select-Object Version -First 1
  #converting version to string
  $onlinever = $psgalleryversion | select @{n='OnlineVersion'; e={$_.Version -as [string]}}
  $b = $onlinever | Select-Object OnlineVersion -ExpandProperty OnlineVersion
 
  if ([version]"$a" -ge [version]"$b") {
    Write-Host "Module: $checkmodule"
    Write-Host "Installed $a is equal or greater than $b"
  }
  else {
    Write-Host "Module: $checkmodule"
        Write-Host "Installed Module:$a is lower version than $b"
        #ask for update  
        do { $askyesno = (Read-Host "Do you want to update Module $checkmodule (Y/N)").ToLower() } while ($askyesno -notin @('y','n'))
              if ($askyesno -eq 'y') {
                  Write-Host "Selected YES Updating module $checkmodule"
                  Update-Module -Name $checkmodule -Verbose -Force
                  
                  } else {
                  Write-Host "Selected NO , no updates to Module $checkmodule were done"
                  }
  }
 
}