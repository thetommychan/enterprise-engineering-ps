
<#
.Synopsis
   PowerShell script to list/Change all Scheduled Tasks and Services and the User ID
.DESCRIPTION
  This Script will View or Change Passwords or "Change User and Password" for Scheduled Tasks and Services 
  and accounts for Local or Domain

  v2 = adding autologon for wptmwa23, wttwma23, wptmwa21, wttmwa21, wprtda11, wprtda12, wprtda13
  #>   cls
Remove-Variable -name  DomainFilter2 -ErrorAction SilentlyContinue 
Remove-Variable -name  DomainFilter_Combined -ErrorAction SilentlyContinue 
Remove-Variable -name  logpath -ErrorAction SilentlyContinue 
Remove-Variable -name  logfile -ErrorAction SilentlyContinue 
Remove-Variable -name  tofield -ErrorAction SilentlyContinue 

$VerbosePreference = "continue"

#     *****  WILL NOT CHANGE AUTOLOGON FOR ANYTHING BUT WTTMWA04 and WPTMWA04   *****

# ******* CHANGE ONLY THE BELOW 5 LINES IF NECCESSARY ********
# add app pool functionality
# add com object functionality
#  $DomainSearch = "OU=Appservers,OU=SysMgmt,DC=upgf,DC=com"   #  Change to fit your search criteria
    
    $OUnoincl = "*Midrange*"   #  OU to not include in password change.
  $DomainSearch = "OU=SysMgmt,DC=upgf,DC=com"   #  Change to fit your search criteria
   #$DomainFilter = "(Name -like 'SRVTM16*') -and Name -notlike 'w*ctx*' -and Name -notlike 'CITRXAL*'"  #  Change to fit your search criteria  " -like '*' " is default
        $DomainFilter = "(Name -like 'w*' -or Name -like 'r*') -and Name -notlike 'w*ctxa*' -and Name -notlike 'CITRXAL*'"  #  Change to fit your search criteria  " -like '*' " is default
        # $DomainFilter = "Name -like 'w*ctxw*' -or Name -like 'w*ctxi*' "  #  Use for Citrix Servers
       #  $DomainFilter = "Name -like 'wpavra*'  "  #  Use for AVR Servers
 $DomainFilter2 = " -and  OperatingSystem -like '*Server*'  -and Name -notlike 'rccof01*'"  #  Change only if you want something other than Windows Servers
 $DomainFilter_Combined = $DomainFilter + $DomainFilter2  
 # $tofield = 'shuskey@ups.com'
 $tofield = 'serversupport@tforcefreight.com'
 # $tofield = @('shuskey@ups.com','anwarcarter@ups.com','mwilliams13@ups.com','woodytaylor@ups.com','jacklyons@ups.com','soberoi@ups.com')      
# *************************************************************
#     (Get-ADComputer -filter $DomainFilter_Combined -searchbase "$DomainSearch" | where {$_.DistinguishedName -notlike $OUnoincl} | sort-object -property name).Name


$scriptname = $MyInvocation.MyCommand.Path
  $logpath = "\\opnasi02\server\documents\Password_Project\Scripts\Logs\"
 $logfile = "$(get-date -f yyyyMMdd-HHmmss)_PasswordChange.txt"

 write-output "$(get-date -f yyyy/MM/dd-HH:mm:ss)"| out-file $logpath$logfile  -Append -Force
 write-output "Script Name: $scriptname " | out-file $logpath$logfile  -Append -Force

 $CurrentUserid = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name 
 write-output "User running script: $CurrentUserid " | out-file $logpath$logfile  -Append -Force

 #start-transcript -path $logpath$logfile -append
 #stop-transcript | out-null

 Remove-Variable -name  Changeme -ErrorAction SilentlyContinue P
Remove-Variable -name  usertolookfor1 -ErrorAction SilentlyContinue 
Remove-Variable -name  usertolookfor -ErrorAction SilentlyContinue 
Remove-Variable -name  newusertolookfor -ErrorAction SilentlyContinue 
Remove-Variable -name  newusertolookfor1 -ErrorAction SilentlyContinue 
Remove-Variable -name  domainQ -ErrorAction SilentlyContinue 
Remove-Variable -name  domainCD -ErrorAction SilentlyContinue 
Remove-Variable -name  UsercheckCur -ErrorAction SilentlyContinue 
Remove-Variable -name  domainND -ErrorAction SilentlyContinue 
Remove-Variable -name  domainNQ -ErrorAction SilentlyContinue 
Remove-Variable -name  newpassword -ErrorAction SilentlyContinue 
Remove-Variable -name  newpassword2 -ErrorAction SilentlyContinue 
Remove-Variable -name  newpassword9 -ErrorAction SilentlyContinue 
Remove-Variable -name  plain -ErrorAction SilentlyContinue 
Remove-Variable -name  newpassword8 -ErrorAction SilentlyContinue 
Remove-Variable -name  plain2 -ErrorAction SilentlyContinue 
Remove-Variable -name  ct -ErrorAction SilentlyContinue 
Remove-Variable -name  pc -ErrorAction SilentlyContinue 
Remove-Variable -name  isValid -ErrorAction SilentlyContinue 
Remove-Variable -name  yesnopass -ErrorAction SilentlyContinue 
Remove-Variable -name  verboasePreference -ErrorAction SilentlyContinue 
Remove-Variable -name  list -ErrorAction SilentlyContinue 
Remove-Variable -name  logfilepath -ErrorAction SilentlyContinue 
Remove-Variable -name  erractionpreference -ErrorAction SilentlyContinue 
Remove-Variable -name  computername -ErrorAction SilentlyContinue 
Remove-Variable -name  useraccount -ErrorAction SilentlyContinue 
Remove-Variable -name  ct1 -ErrorAction SilentlyContinue 
Remove-Variable -name  pc1 -ErrorAction SilentlyContinue 
Remove-Variable -name  isvalid1 -ErrorAction SilentlyContinue 
Remove-Variable -name  path -ErrorAction SilentlyContinue 
Remove-Variable -name  tasks -ErrorAction SilentlyContinue 
Remove-Variable -name  item -ErrorAction SilentlyContinue 
Remove-Variable -name  absolutepath -ErrorAction SilentlyContinue 
Remove-Variable -name  check -ErrorAction SilentlyContinue 
Remove-Variable -name  fldr1 -ErrorAction SilentlyContinue 
Remove-Variable -name  fldr1 -ErrorAction SilentlyContinue 
Remove-Variable -name  tsk -ErrorAction SilentlyContinue 
Remove-Variable -name  services -ErrorAction SilentlyContinue 
Remove-Variable -name  service -ErrorAction SilentlyContinue 
Remove-Variable -name  firstrun -ErrorAction SilentlyContinue 
Remove-Variable -name  logcontent -ErrorAction SilentlyContinue 
Remove-Variable -name  logc -ErrorAction SilentlyContinue 
Remove-Variable -name  MessageBody -ErrorAction SilentlyContinue 

$counter=0

function ChangeWhat  {
    $Changeme = Read-Host 'Are you changing (P)assword or (B)oth User and Password or just (V)iewing? '
    write-output "P=Password Change, B=Both Password and User, V=View Only:  $Changeme " | out-file $logpath$logfile  -Append -Force 
    $Script:Changeme = $Changeme.Trim()
           If (!($Changeme -eq "P" -or $Changeme -eq "B" -or $Changeme -eq "V")) {
           Write-Host "Please choose either P or B or V. "
           sleep 2
           ChangeWhat     }
                      }



function askusername {
   $usertolookfor1 = Read-Host 'What is the user id you want to find? '
   write-output  "User to look for:  $usertolookfor1 " | out-file $logpath$logfile  -Append -Force
   $script:usertolookfor=$usertolookfor1.split('\')[-1]
                     }

function asknewusername {
   If ($Changeme -eq "B") { $newusertolookfor1 = Read-Host 'What is the NEW user id? '    
   write-output "New User:  $newusertolookfor1 " | out-file $logpath$logfile  -Append -Force
   $script:newusertolookfor=$newusertolookfor1.split('\')[-1]
                            }
                         }            
                         
   function Lookupcurrentdomain    
   { 
   $defaultdomCD = 'Richmond'
    $domainCD = Read-Host 'Is this a (D)omain account or a (L)ocal account? ' 
    write-output "D=Domain, L=Local:  $domainCD " | out-file $logpath$logfile  -Append -Force
        If ($domainCD -eq "L") {$script:domainCD = "LOCAL"}
        ElseIf ($domainCD -eq "D") {$script:domainCD = "DOMAIN" 
                      $domainQ = Read-Host "What is the name of the Domain [$defaultdomCD]? "
                      $domainQ = $domainQ.trim()
                       IF ($domainQ -eq '') {$script:domainQ = $defaultdomCD} 
                       else {$script:domainQ = $domainQ}
                       write-output "Current Domain Name:  $script:domainQ "  | out-file $logpath$logfile  -Append -Force
                       $UsercheckCur = Get-ADUser -Filter {sAMAccountNAme -eq $usertolookfor}   
                       If ($UsercheckCur -eq $Null) {"$usertolookfor does not exist in $domainQ....Please try again "
                                sleep 2
                                askusername
                                lookupcurrentdomain     }
                                         }
        ElseIf ($domainCD -ne "D" -or $domainCD -ne "L") {
                                    write-host -ForegroundColor red "Invalid Selection..Choose either (D)omain or (L)ocal" 
                                    sleep 2
                                    Lookupdomain      }
    }
   
    Function Lookupnewdomain    
    {
    $defaultdomND = 'Richmond'
       If ($Changeme -eq "B") { $domainND = Read-Host 'Is the new account a (D)omain or (L)ocal account? '   
       write-output "D=New Domain, L=New Local:  $domainND " | out-file $logpath$logfile  -Append -Force
        If ($domainND -eq "L") {$Script:domainND = "LOCAL"}
        ElseIf ($domainND -eq "D") { $Script:domainND = "DOMAIN"
                         $domainNQ = Read-Host "What is the name of the new Domain [$defaultdomND]? "
                         $domainNQ = $domainNQ.trim()
                         If ($domainNQ -eq '') {$Script:domainNQ = $defaultdomND} else {$Script:domainNQ = $domainQ}   
                         write-output "New Domain Name:  $script:domainNQ " | out-file $logpath$logfile  -Append -Force
                         $UsercheckNew = Get-ADUser -Filter {sAMAccountNAme -eq $newusertolookfor}
                         If ($UsercheckNew -eq $Null) {"$newusertolookfor does not exist in $domainND....Please try again"
                                sleep 2
                                asknewusername
                                lookupnewuser        }
                                    }
        ElseIf ((!($domainND -eq "D")) -or (!($domainND -eq "L"))) {
                                    write-host -ForegroundColor red "Invalid Selection..Choose either (D)omain or (L)ocal"
                                    sleep 2
                                    Lookupnewdomain}
                        }
    }

                    

function passwords {


    If (!($Changeme -eq "V"))   {
    
   $newpassword =  Read-Host "What is the new password? " -AsSecureString
   $newpassword2 =  Read-Host "Type in password again? " -AsSecureString
   #$script:newpassword = $newpassword.Trim()
   #$Script:newpassword2 = $newpassword2.Trim()

   $newpassword9 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newpassword)
        $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($newpassword9)
           $Script:plain = $plain 
   $newpassword8 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newpassword2)
        $plain2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($newpassword8)
            $Script:plain2 = $plain2

            
         IF (!($plain -eq $plain2)) {
                write-host " Passwords do not match, try again "
                sleep 2
                passwords                    }
                                 }
                  

}

Function accountpasschg {
                   #write-host "firstrun - $firstrun" 
    If ($changeme -eq "P" -and (!($firstrun -eq "n")) )
        { $yesnopass = Read-Host "Do you also want to change the password on the server for $usertolookfor (y/n)? " 
        write-output "Change Current User Password on Server?:  $yesnopass " | out-file $logpath$logfile  -Append -Force
        $script:firstrun="n"
      # write-host "firstrun1  - $firstrun" 
        }
    ElseIf ($changeme -eq "B" -and (!($firstrun -eq "n")) )
        {  $yesnopass = Read-Host "Do you also want to change the password on the server for $newusertolookfor (y/n)? " 
        write-output "Change New User Password on Server?:  $yesnopass " | out-file $logpath$logfile  -Append -Force
        $script:firstrun="n"
        }


                                $script:yesnopass = $yesnopass.Trim()
                         #   If ((!($yesnopass -eq "y")) -and (!($yessnopass -eq "n")))
                             If ($yesnopass -notin ("y","n"))
                                { 
                                Write-host "Please choose Y or N: " 
                                sleep 2
                                accountpasschg
                                }
                           # Else {write-host "works"
                              #   }   
                                 
                        }


Function chglocalpass {

#write-host "$yesnopass"
                                        If ($yesnopass -eq "y"){
                                        ## invoke-command -Computer $computername -Scriptblock {Param($computername, $usertolookfor,$plain)
                                         $userchange = [adsi]"WinNT://$computername/$usertolookfor,user"
                                         $userchange.SetPassword($plain)
                                            $userchange.SetInfo()  ##} -ArgumentList $computername, $usertolookfor, $plain
                                       #  invoke-command -Computer $computername -Scriptblock 
                                       #  $userchange = [adsi]"WinNT://$computername/$usertolookfor,user"
                                       #  $userchange.SetPassword($plain)
                                       #     $userchange.SetInfo()  
                                            #write-host "$computername 5"
                                                               $computerarray= 'wttmwa04','wptmwa04'
                                                               $computerarray2= 'wpavra10','wpavra11'
                                                               $computerarray3= 'wptmwa23'
                                                               $computerarray4= 'wttmwa23'
                                                               $computerarray5= 'wptmwa21','wttmwa21'
                                                               $computerarray6= 'wprtda11','wprtda12','wprtda13,wtrtda11,dt123860,dt123867,dt126738'
                                                               If(($computerarray -match $computername -and $usertolookfor -match "administrator")  `
                                                               -or ($computerarray2 -match $computername  -and $usertolookfor -match "avruser1")    `
                                                               -or ($computerarray3 -match $computername -and $usertolookfor -match "nbch111")  `
                                                               -or ($computerarray4 -match $computername -and $usertolookfor -match "nbch110")  `
                                                               -or ($computerarray5 -match $computername -and $usertolookfor -match "otcsvc01")  `
                                                               -or ($computerarray6 -match $computername -and $usertolookfor -match "nopn053"))  {
                                                    #If ($computername -ieq "wttmwa04" -or $computername -ieq "wptmwa04") {
                                                            #write-verbose -Message "$computerarray2 - second - $computername"
                                                             invoke-command -Computer $computername -ScriptBlock {
                                                             Param($plain, $usertolookfor, $computername)
                                                             # & "c:\upgf\autologon.exe -accepteula"  $usertolookfor $computername $plain   | Tee-Object -Variable CmdOutPut | Out-Null
                                                          #  $CmdOutPut = & "netdom.exe" $params
                                                            #$CmdOutPut = & "c:\upgf\autologon.exe -accepteula"  $usertolookfor $computername $plain " 2>&1"
                                                          #$CmdOutPut="Shane"
                                                            #  write-verbose -Message "$CmdOutPut" -Verbose
                                                             # Write-Output  "$CmdOutPut"
                                                            c:\upgf\autologon.exe -accepteula $usertolookfor $computername $plain
                                                             write-verbose -Message "$computername - Autologon changed for $usertolookfor" -verbose
                                                             write-output "$computername - Autologon changed for $usertolookfor "  #| out-file $logpath$logfile  -Append -Force
                                                                                 }  -ArgumentList $plain, $usertolookfor, $computername | Out-File -Append $logpath$logfile 

                                                                 }
                                                                }
                      }

Function chglocalnewpass {


                                        If ($yesnopass -eq "y"){
                                        ## invoke-command -Computer $computername -Scriptblock {Param($computername, $newusertolookfor,$plain)
                                         $userchange = [adsi]"WinNT://$computername/$newusertolookfor,user"
                                         $userchange.SetPassword($plain)
                                            $userchange.SetInfo()  ##} -ArgumentList $computername, $newusertolookfor, $plain
                                        # invoke-command -Computer $computername -Scriptblock 
                                        # $userchange = [adsi]"WinNT://$computername/$newusertolookfor,user"
                                        # $userchange.SetPassword($plain)
                                         #   $userchange.SetInfo()  
                                          #  write-host $computername
                                                               $computerarray= 'wttmwa04','wptmwa04'
                                                               $computerarray2= 'wpavra10','wpavra11'
                                                               $computerarray3= 'wptmwa23'
                                                               $computerarray4= 'wttmwa23'
                                                               $computerarray5= 'wptmwa21','wttmwa21'
                                                               $computerarray6= 'wprtda11','wprtda12','wprtda13'
                                                               If(($computerarray -match $computername -and $newusertolookfor -match "administrator")  `
                                                               -or ($computerarray2 -match $computername  -and $newusertolookfor -match "avruser1")    `
                                                               -or ($computerarray3 -match $computername -and $newusertolookfor -match "nbch111")  `
                                                               -or ($computerarray4 -match $computername -and $newusertolookfor -match "nbch110")  `
                                                               -or ($computerarray5 -match $computername -and $newusertolookfor -match "otcsvc01")  `
                                                               -or ($computerarray6 -match $computername -and $newusertolookfor -match "nopn053"))  {
                                                              
                                                             #If ($computername -ieq "wttmwa04" -or $computername -ieq "wptmwa04") {
                                                             invoke-command -Computer $computername -ScriptBlock {
                                                             Param($plain, $newusertolookfor, $computername)
                                                            c:\upgf\autologon.exe -accepteula $newusertolookfor $computername $plain
                                                             write-verbose -Message "$computername - Autologon changed for $newusertolookfor" -verbose
                                                           #  write-output "$computername-Autologon changed for $newusertolookfor" -verbose | out-file $logpath$logfile  -Append -Force
                                                           write-output "$computername - Autologon changed for $newusertolookfor" # | add-content $logpath$logfile -Passthru
                                                                                 }  -ArgumentList $plain, $newusertolookfor, $computername | Out-File -Append $logpath$logfile 
                                                                 }
                                                                }
                      }

function Get-SWLocalPasswordLastSet_Cur {
   # [CmdletBinding()]
    
    Try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
        $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $ComputerName)
        $User = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($PrincipalContext, $Usertolookfor)
        $User.LastPasswordSet
    }
    Catch {
        Write-Warning -Message "$($_.Exception.Message)"
    }
}

function Get-SWLocalPasswordLastSet_New {
    #[CmdletBinding()]
    
    Try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement 
        $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $ComputerName)
        $User = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($PrincipalContext, $newusertolookfor)
        $User.LastPasswordSet
         }
    Catch {
        Write-Warning -Message "$($_.Exception.Message)"
           }
                                        }

Function chgdomainpass {


                                        If ($yesnopass -eq "y"){
                                            set-adaccountpassword -identity $usertolookfor -server "$domainQ" -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$plain" -Force) -ErrorVariable dompwerr
                                            If ($dompwerr) {
                                                Out-file $logpath$logfile -inputObject $dompwerr
                                                            }
                                        $pwchgverify = (get-aduser ntst002 -server "$domainQ" -properties * | select PasswordLastSet | ft -hidetableheaders |out-string ).trim()
                                        write-output "Password for $usertolookfor was last set -  $pwchgverify" | add-content $logpath$logfile -Passthru

                                #Changing Domain Account Password Expiration Date is currently exists to add 1 year to current run date
                                    $addyear=((get-date).AddYears(1))
                                    IF ((get-aduser $usertolookfor -properties accountexpires).accountexpires -ne 0) {
                                    Set-ADAccountExpiration -Identity $usertolookfor -DateTime $addyear
                                    $AccountExpuser=[datetime]::FromFileTime((get-aduser $usertolookfor -properties accountexpires).accountexpires)
                                    write-output "Account Expiration Date  for $usertolookfor is now set for  -  $AccountExpuser" | add-content $logpath$logfile -Passthru
                                    }
                                                                }
                      }





Function chgdomainnewpass {


                                        If ($yesnopass -eq "y"){
                                            set-adaccountpassword -identity $newusertolookfor -server "$domainNQ" -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$plain" -Force) -ErrorVariable newdompwerr
                                                If ($newdompwerr) {
                                                Out-File $logpath$logfile -inputobject $newdompwerr
                                                                  }
                                        $pwchgverify = (get-aduser ntst002 -server "$domainNQ" -properties * | select PasswordLastSet | ft -hidetableheaders |out-string ).trim()
                                        write-output "Password for $newusertolookfor was last set -  $pwchgverify" | add-content $logpath$logfile -Passthru

                                        
                                #Changing Domain Account Password Expiration Date is currently exists to add 1 year to current run date
                                    $addyear=((get-date).AddYears(1))
                                    IF ((get-aduser $usertolookfor -properties accountexpires).accountexpires -ne 0) {
                                    Set-ADAccountExpiration -Identity $newusertolookfor -DateTime $addyear
                                    $AccountExpnewuser=[datetime]::FromFileTime((get-aduser $newusertolookfor -properties accountexpires).accountexpires)
                                    write-output "Account Expiration Date  for $newusertolookfor is now set for  -  $AccountExpnewuser" | add-content $logpath$logfile -Passthru
                                    }
                                                               }
                      }


             Function accountdompasschg {
                   #write-host "firstrun - $firstrun" 
    If ($changeme -eq "P" -and (!($firstrun -eq "n")) )
        { $yesnopass = Read-Host "Do you also want to change the password on the domain, $domainQ, for $usertolookfor (y/n)? " 
        write-output "Change Current User Password on Domain, $domainQ ?:  $yesnopass" | out-file $logpath$logfile  -Append -Force
        $script:firstrun="n"
      # write-host "firstrun1  - $firstrun" 
        }
    ElseIf ($changeme -eq "B" -and (!($firstrun -eq "n")) )
        {  $yesnopass = Read-Host "Do you also want to change the password on the domain, $domainNQ, for $newusertolookfor (y/n)? " 
        write-output "Change New User Password on Doamin, $domainNQ ?:  $yesnopass" | out-file $logpath$logfile  -Append -Force
        $script:firstrun="n"
        }


                                $script:yesnopass = $yesnopass.Trim()
                         #   If ((!($yesnopass -eq "y")) -and (!($yessnopass -eq "n")))
                             If ($yesnopass -notin ("y","n"))
                                { 
                                Write-host "Please choose Y or N: " 
                                sleep 2
                                accountpasschg
                                }
                           # Else {write-host "works"
                              #   }   
                                 
                        }       



Clear-Host
ChangeWhat
askusername
Lookupcurrentdomain
asknewusername
Lookupnewdomain
passwords    ##  Get-ADComputer -filter 'Name -like "wpedia*"' -searchbase  OU=Appservers,OU=SysMgmt,DC=upgf,DC=com
   
     
Import-Module ActiveDirectory -Verbose:$false
$VerbosePreference = "continue"

    If ($Changeme -eq "P") {$useraccount = $domain + $usertolookfor}
    If ($Changeme -eq "B") {$useraccount =  $domain2 + $newusertolookfor}
                 
  
             IF (($domainND -eq "DOMAIN" -or $domainCD -eq "DOMAIN") -and ($Changeme -eq "P")) {
                                     #write-host "$yesnopass $computername"
                                     accountdompasschg
                                     chgdomainpass
                                      }
           IF (($domainND -eq "DOMAIN" -or $domainCD -eq "DOMAIN") -and ($Changeme -eq "B")) {
                                     #write-host "$yesnopass $computername"
                                     accountdompasschg
                                     chgdomainnewpass
                                      }




# $list =  (Get-ADComputer -filter $DomainFilter_Combined -searchbase "$DomainSearch" | where {$_.DistinguishedName -notlike $OUnoincl -and $_.description -notlike '*cluster*'} | sort-object -property name).Name   # Replace -filter * section with  -filter 'Name -like "wpedia*"'      

$list =  (Get-ADObject -filter $DomainFilter_Combined -searchbase "$DomainSearch" -properties *  | where {$_.DistinguishedName -notlike $OUnoincl -and $_.description -notlike '*cluster*'} | sort-object -property name).Name   # Replace -filter * section with  -filter 'Name -like "wpedia*"'      

$list_cluster =  (Get-ADObject -filter $DomainFilter_Combined -searchbase "$DomainSearch" -properties *  | where {$_.DistinguishedName -notlike $OUnoincl -and $_.description -like '*cluster*'} | sort-object -property name).Name   # Replace -filter * section with  -filter 'Name -like "wpedia*"'      


Write-verbose -Message "Trying to query $($list.count) servers found in AD in $DomainSearch - Filter= $DomainFilter_Combined "
write-output "Trying to query $($list.count) servers found in AD in $DomainSearch - Filter= $DomainFilter_Combined" | out-file $logpath$logfile  -Append -Force
write-verbose -Message "  "
write-output "  " | out-file $logpath$logfile  -Append -Force
$ErrorActionPreference = "SilentlyContinue"
#$usertolookfor = "administrator"  #  ask user for user name if /Name is used
#$newpassword = "1027d"   #  ask user for the new password if /Change is used
#$domainQ = "local"     #  ask user for word "Local" or the actual Domain Name if /Change is used

#start-sleep -s 5000  




$dtes=get-date

write-output "Started - $dtes"
write-output "Started - $dtes " | out-file $logpath$logfile  -Append -Force




foreach ($computername in $list)
{  If (test-connection $computername -count 1 -erroraction silentlycontinue) {

           IF (($domainND -eq "LOCAL" -or $domainCD -eq "LOCAL") -and ($Changeme -eq "P")) {
                                     #write-host "$yesnopass $computername"
                                     accountpasschg
                                     chglocalpass
                                      }
           IF (($domainND -eq "LOCAL" -or $domainCD -eq "LOCAL") -and ($Changeme -eq "B")) {
                                     #write-host "$yesnopass $computername"
                                     accountpasschg
                                     chglocalnewpass
                                      }



If ($domainCD -eq "LOCAL")
    { $domain = $computername + "\" }
    Else {$domain = $domainQ + "\" }
   
   If ($domainND -eq "LOCAL")
    { $domain2 =   $computername + "\" }
    Else {$domain2 = $domainNQ + "\" }

    #write-verbose -Message "$domainCD - $domain"


$counter = $counter + 1
write-host "$computername - $counter"

            #  validate the credentials entered
            	        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    IF (($domainCD -eq "DOMAIN") -and ($Changeme -eq "P"))
                {


     $accountlock = Get-ADUser $usertolookfor -Properties Lockedout | Select-Object Lockedout | out-string
     If ($accountlock -like "*True*") {
     unlock-adaccount $usertolookfor}


              $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
$pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ct,$DomainQ
$Isvalid = $pc.ValidateCredentials($usertolookfor, $plain)
                        If ($Isvalid -like "*False*")
                            { write-host "Domain User and Password combo is not valid or account is locked out.  Please try again"
                            sleep 2
                            passwords  }
                         #Else {write-host "Domain Credentials are valid on $DomainQ"
                         #sleep 2  }
                 } 
         elseif    (($domainCD -eq "LOCAL") -and ($Changeme -eq "P"))
       #Validate Local account
                       {
              $ct1 = "machine"
$pc1 = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ct1,$computername
$Isvalid1 = $pc1.ValidateCredentials($usertolookfor, $plain)

                        If ($Isvalid1 -like "*False*")
                            { write-host "Local User and Password on $computername is not correct or account is locked out.  Please try password again"
                            sleep 2
                            passwords  }
                         #Else {write-host "Local Credentials are valid on $computername"    
                        # sleep 2  }
                        }
           

# Begin Scheduled Tasks

    $path = "\\" + $computername + "\c$\Windows\System32\Tasks"
    $tasks =   Get-ChildItem -Path $path -File   -Recurse | select FullName, name, directory

    # if ($tasks)
   # {
        #Write-Verbose -Message "I found $($tasks.count) tasks for $computername"
    #}

    foreach ($item in $tasks)
    {
        $AbsolutePath = $item.FullName
        $task = [xml] (Get-Content $AbsolutePath)
        If ($task.Task.Principals.Principal.UserId)
            {[STRING]$check = $task.Task.Principals.Principal.UserId
            [STRING]$checklogin = $task.Task.Principals.Principal.LogonType}
         Else {[STRING]$check = $task.Task.Principals.Principal.GroupId
         [STRING]$checklogin = $task.Task.Principals.Principal.LogonType}
       
        #write-verbose -Message "$AbsolutePath"
                        #write-verbose -Message "$($task.Task.Principals.Principal.UserId)"
      If ($checklogin='Password') 
      {
        if (($task.Task.Principals.Principal.UserId) -like "*$usertolookfor*" -or ($task.Task.Principals.Principal.GroupId) -like "*$usertolookfor*")
        {
     #     Write-Verbose -Message "Writing the log file with values for $computername"           
          #Add-content -path $logfilepath -Value "$computername,$($item.Fullname),$check"
    #      write-verbose -message "$computername - $($item.Fullname) - $check"

   
            $fldr1="$($item.directory)"
            $fldr=$fldr1.split('$')[-1]
            $tsk = $fldr.replace("\Windows\System32\Tasks","") + "\" + $($item.name)
            $tsk - $tsk.Trim()
          #  $tsk2 = """$tsk"""
           # write-host $tsk2
            
              # Code to change the password
            IF  ($Changeme -eq "P") 
           {
                         write-verbose -Message "Server = $computername - Scheduled Task Name = $tsk - $check "
                          write-output "Server = $computername - Scheduled Task Name = $tsk - $check ." | out-file $logpath$logfile  -Append -NoClobber -Force
     $accountlock = Get-ADUser $usertolookfor -Properties Lockedout | Select-Object Lockedout | out-string
     If (($accountlock -like "*True*") -and ($domainND -eq "DOMAIN" -or $domainCD -eq "DOMAIN")) {
                        unlock-adaccount $usertolookfor}

                       # invoke-command -Computer $computername -ScriptBlock {
                       #      Param($computername,$useraccount,$plain,$tsk)
                             schtasks /Change /S $computername /RU $usertolookfor /RP "$plain" /TN "$tsk"  | add-content $logpath$logfile -Passthru
                            #write-host 
                             #write-host "Password was NOT changed"
                       #      }  -ArgumentList $computername, $useraccount, $plain, $tsk
                            write-output "  "  | add-content $logpath$logfile -Passthru
           }
            
           ElseIf ($Changeme -eq "B") { 
                        write-verbose -Message "Server = $computername - Scheduled task Name = $tsk - $check "
                        write-output "Server = $computername - Scheduled task Name = $tsk - $check ." | out-file $logpath$logfile  -Append -NoClobber -Force
                    
      $accountlock = Get-ADUser $newusertolookfor -Properties Lockedout | Select-Object Lockedout | out-string
     If (($accountlock -like "*True*") -and ($domainND -eq "DOMAIN" -or $domainCD -eq "DOMAIN")) {
                        unlock-adaccount $newusertolookfor}

                       # invoke-command -Computer $computername -ScriptBlock {
                         #    Param($computername,$useraccount,$plain,$tsk)
                             schtasks /Change /S $computername /RU "$useraccount" /RP "$plain" /TN "$tsk" | add-content $logpath$logfile -Passthru
                           #  write-verbose -Message "User and Password were NOT changed"
                           #  }  -ArgumentList $computername, $useraccount, $plain, $tsk
                                write-output "  "  | add-content $logpath$logfile -Passthru
                                                                       }

         Else {write-verbose -Message "Server = $computername - Scheduled Task Name = $tsk - $check"
        write-output "Server = $computername - Scheduled Task Name = $tsk - $check ."| out-file $logpath$logfile  -Append -NoClobber -Force }

                        
        }
      } 
    }
#End Scheduled Tasks


#write-verbose -Message "    "    #  putting a blank line between Tasks and Services


#Begin Services

        $services = Get-WmiObject win32_service -filter "(StartName Like '%$usertolookfor' or Startname like '%$usertolookfor@upgf.com')" -ComputerName $computername -ErrorAction SilentlyContinue 


        if ($services)
    {
       # Write-Verbose -Message "I found $($services.count) services for $computername"
    }

    foreach ($service in $services)
    {
         #write-verbose -Message " $($service.name),$($service.displayname),$($service.startname)"
         write-verbose -Message "Server = $computername -  Service Name = $($service.displayname) - $($service.startname)"
       write-output "Server = $computername -  Service Name = $($service.displayname) - $($service.startname) ." | out-file $logpath$logfile  -Append -NoClobber -Force

            # Code to change password
           IF  ($Changeme -eq "B")
           {      
           write-verbose -Message "Changing user and password now for Service to $useraccount"
         write-output "Changing user and password now for Service to $useraccount ." | out-file $logpath$logfile  -Append -NoClobber -Force
            $Service.StopService()
            $service.Change($Null,$Null,$Null,$Null,$Null,$Null,$useraccount,$plain,$Null,$Null,$Null) | out-null
            $Service.StartService()
            
           }

           If ($Changeme -eq "P")
           {
           write-verbose -Message "Changing password now for Service"
           write-output "Changing password now for Service " | out-file $logpath$logfile  -Append -NoClobber -Force
           $Service.StopService()
            $service.Change($Null,$Null,$Null,$Null,$Null,$Null,$Null,$plain,$Null,$Null,$Null) | out-null
            $Service.StartService()
            }
     }
#End Services

# Starting to Look at IIS App Pools
  $pool=invoke-command -computername $computername -ArgumentList $usertolookfor -scriptblock {param($usertolookfor) ; import-module webadministration ;  dir IIS:\AppPools | ForEach {get-itemproperty IIS:\AppPools\$($_.name) -name processmodel  | where {$_.identitytype -like "*SpecificUser*" -and $_.username.trim() -like "*$usertolookfor*"}}  }   #  $computername = "srvtm16"
            ForEach  ($p1 in $pool) {
                            $poolname = $p1.pschildname
                            $pooluser = $p1.username
                               write-verbose -Message "Server = $computername - IIS App Pool =  $($poolname) - $($pooluser)"
                               write-output "Server = $computername - IIS App Pool =  $($poolname) - $($pooluser) ." | out-file $logpath$logfile  -Append -NoClobber -Force

                                 If ($Changeme -eq "B") {
                                         invoke-command -computername $computername -ArgumentList $useraccount, $plain, $poolname -scriptblock {param($useraccount, $plain, $poolname) ; import-module webadministration ;  Set-ItemProperty IIS:\AppPools\$($poolname) -name processModel -value @{userName=$useraccount ;password=$plain ;identitytype=3} ; restart-WebAppPool -Name $poolname } 
                                          write-verbose -Message "Changing user and password now for IIS App Pool, $($poolname), to $useraccount"
                                          write-output "Changing user and password now for IIS App Pool, $($poolname), to $useraccount ." | out-file $logpath$logfile  -Append -NoClobber -Force} 

                                 If ($Changeme -eq "P") {  
                                        invoke-command -computername $computername -ArgumentList $poolname, $pooluser, $plain -scriptblock {param($poolname, $pooluser, $plain) ; import-module webadministration ;Set-ItemProperty IIS:\AppPools\$poolname -name processModel -value @{userName=$pooluser;password="$plain";identitytype=3} ; restart-WebAppPool -Name $poolname } 
                                         write-verbose -Message "Changing password now for IIS App Pool, $($poolname)"
                                         write-output "Changing password now for IIS App Pool, $($poolname) ." | out-file $logpath$logfile  -Append -NoClobber -Force} 
                                   } 


     #   Ending Main IF Statement for Finding Computer Names
  } Else {
                 $counter = $counter + 1 
                write-host "$computername - OFFLINE - $counter"
                } 

}

write-output " " | out-file $logpath$logfile  -Append -NoClobber -Force
$dtee=get-date
write-output "Ended - $dtee"
write-output "    "
write-output "    "| out-file $logpath$logfile  -Append -NoClobber -Force
write-output "Ended - $dtee " | out-file $logpath$logfile  -Append -NoClobber -Force
write-output "  These 'Cluster Resources' are being excluded from the script - $list_cluster"
write-output "  These 'Cluster Resources' are being excluded from the script - $list_cluster"  | out-file $logpath$logfile  -Append -NoClobber -Force
write-output "    "
write-output "    "| out-file $logpath$logfile  -Append -NoClobber -Force
write-output "****  Check Log file at $logpath$logfile  ****"
write-output "****  Check Log file at $logpath$logfile  ****" | out-file $logpath$logfile  -Append -NoClobber -Force

#  Below adds a carriage return and linefeed to end of each row and then emails out.
$logcontent = get-content -path $logpath$logfile -raw
$MessageBody = $logcontent | out-string

###foreach ($logc in $logcontent)  $MessageBody = "test"
###{
###$MessageBody = $MessageBody + $logc + "`r`n"
###}



 send-mailmessage -From "Server-PWChange@tforcefreight.com" -To $tofield -Subject "Password Change Script in ""$Changeme"" mode"  -Body $MessageBody -smtpserver mta.upgf.com 
#send-mailmessage -From "JacksTeam@ups.com" -To "shuskey@ups.com","mwilliams13@ups.com","jacklyons@ups.com","anwarcarter@ups.com","woodytaylor@ups.com","kellyrichardson@ups.com" -Subject "Password Change Script in ""$Changeme"" mode" -Body $MessageBody  -smtpserver imt1.upgf.com 
# If Email comes out with no line breaks, then in Outlook - File / Options / Mail / Message format:  Uncheck - "Remove extra line breaks in plain test messages"

#  Computers in the domain that have autologin
#  wttmwa04 - administrator
#  wptmwa04 - administrator
#  wptmwa21 - otcsvc01
#  wttmwa21 - otcsvc01
#  wptmwa23 - nbch111
#  wttmwa23 - nbch110
#  wprtda11 - 
#  wprtda12
#  wprtda13
#  wpavra10
#  wpavra11

# DMZ
#  wprsnw11 - administrator
#  wprsnw11 - srvrteam
  
# To relax powershell security on remote machines, run the following at the command prompt on remote machine.
#    winrm quickconfig -quiet    or     winrm qc -q    (same command)

# This FindChangeTasksServices#.ps1 file should be run on wpsusa02






