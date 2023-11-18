
param (
    [string]$runtimeuser="username parameter" )


function OutputText($newTextLine)
{
# http://social.technet.microsoft.com/wiki/contents/articles/13726.the-concept-of-input-output-streams-in-powershell.aspx
# you can redirect output of a stream but not of a cmdlet
<# example
$service = (Get-Service s*) 
 foreach ($_ in $service)
 {
 $name = $_.Name
 $status = $_.Status
 $richTextBox1.Text = $richTextBox1.Text + $name + "  "  +$status  + "`r"
}
#>
$richTextBox1.Text = $richTextBox1.text + $newTextLine
# The below allows the Textbox to autoscroll
$richTextBox1.SelectionStart = $richTextBox1.TextLength
$richTextBox1.ScrollToCaret()


#$outfile1 = "\\opnasi02\server\powershell\Shane\$username-delprof-$(get-date -f yyyMMdd-HHmmss).log"
$newTextLine  | out-file -FilePath $outfile1 -Append 
#Add-Content -Path $outfile1 -Value ($newTextLine)

}
#Generated Form Function

function GenerateForm {

#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion

#region Generated Form Objects
$MainForum = New-Object System.Windows.Forms.Form
$Delete = New-Object System.Windows.Forms.Button
$klear = New-Object System.Windows.Forms.Button
$Exitbtn = New-Object System.Windows.Forms.Button
#$kancel = New-Object System.Windows.Forms.Button
$TextBox= New-Object System.Windows.Forms.TextBox
$richTextBox1 = New-Object System.Windows.Forms.RichTextBox
$Label = New-Object System.Windows.Forms.Label
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState


#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------
#Provide Custom Code for events specified in PrimalForms.

#Correct the initial state of the form to prevent the .Net maximized form issue
$OnLoadForm_StateCorrection=
{
    $MainForum.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Form Design
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 400
$System_Drawing_Size.Width = 600
$MainForum.ClientSize = $System_Drawing_Size
$MainForum.DataBindings.DefaultDataSourceUpdateMode = 0
$MainForum.Name = "MainForum"
$MainForum.Text = "Delete Profile"

function stufftodo {
$username=$TextBox.Text
$richTextBox1.Clear()
 #$outfile1="c:\upgf\$username-delprof-$(get-date -f yyyMMdd-HHmmss).log" 
 $outfile1 = "\\opnasi02\helpdesk\delproflog\$username-delprof-$(get-date -f yyyMMdd-HHmmss).log"
 #out-file -Filepath $outfile1 -inputObject (get-date)
  OutputText "`r         $($runtimeuser.ToUpper())        is deleting profile for    $($username.ToUpper())" 
  OutputText "`r `r"
  OutputText "`r         Start Time:  $(get-date)" 
    OutputText "`r `r"
  Del-UPSProfile($username)
  }


$Delete.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 13
$System_Drawing_Point.Y = 72
$Delete.Location = $System_Drawing_Point
$Delete.Name = "Delete"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$Delete.Size = $System_Drawing_Size
$Delete.TabIndex = 0
$Delete.Text = "Delete"
$Delete.UseVisualStyleBackColor = $True
$Delete.add_Click({stufftodo})


$klear.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 150
$System_Drawing_Point.Y = 72
$klear.Location = $System_Drawing_Point
$klear.Name = "klear"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 125
$klear.Size = $System_Drawing_Size
$klear.TabIndex = 1
$klear.Text = "Clear Console"
$klear.UseVisualStyleBackColor = $True
$klear.add_Click({$richTextBox1.Clear()})


$Exitbtn.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 345 #500
$System_Drawing_Point.Y = 72
$Exitbtn.Location = $System_Drawing_Point
$Exitbtn.Name = "Exitbtn"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$Exitbtn.Size = $System_Drawing_Size
$Exitbtn.TabIndex = 0
$Exitbtn.Text = "Exit"
$Exitbtn.UseVisualStyleBackColor = $True
$Exitbtn.add_Click({$Mainforum.close(); return})
$Exitbtn.Enabled=$true

#$kancel.DataBindings.DefaultDataSourceUpdateMode = 0
#$System_Drawing_Point = New-Object System.Drawing.Point
#$System_Drawing_Point.X = 345
#$System_Drawing_Point.Y = 72
#$kancel.Location = $System_Drawing_Point
#$kancel.Name = "kancel"
#$System_Drawing_Size = New-Object System.Drawing.Size
#$System_Drawing_Size.Height = 23
#$System_Drawing_Size.Width = 75
#$kancel.Size = $System_Drawing_Size
#$kancel.TabIndex = 0
#$kancel.Text = "Cancel"
#$kancel.UseVisualStyleBackColor = $True
#$kancel.add_Click({return})
#$kancel.Enabled=$false



$TextBox.Location = New-Object System.Drawing.Size(12,40)
$textbox.Size = New-Object System.Drawing.size(100,20)
$MainForum.Controls.Add($TextBox)

$richTextBox1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 108
$richTextBox1.Location = $System_Drawing_Point
$richTextBox1.Name = "richTextBox1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 280
$System_Drawing_Size.Width = 574
$richTextBox1.Size = $System_Drawing_Size
$richTextBox1.TabIndex = 2



$label.Location = New-Object System.Drawing.Size(10,15) 
$label.Size = New-Object System.Drawing.Size(550,20) 
$label.Text = "Please enter user name in the space below and click Delete."

$mainforum.Controls.Add($label) 
$MainForum.Controls.Add($richTextBox1)
$MainForum.Controls.Add($Delete)
$MainForum.Controls.Add($klear)
$mainForum.Controls.Add($Exitbtn)
$mainForum.Controls.Add($kancel)

#endregion Form Design


#Save the initial state of the form
$InitialFormWindowState = $MainForum.WindowState
#Init the OnLoad event to correct the initial state of the form
$MainForum.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$MainForum.ShowDialog()| Out-Null

} 

function Del-UPSProfile

{
<#
.Synopsis
   Deletes Profile
.DESCRIPTION
    Script deltes Citrix Profile. renames AppData to AppData.old, Creates new folder Appdata\Microsoft\Outlook and copies .nk2 file there.
    It goes through all XenApp servers in the new farm and looks for profile folder and if it finds any deletes it.
    It uses Active Directory user's name in the form ABCDEFG without prefix (richmond\) or without suffix (@upgf.com)    
    It requires:
    1.NTFSSecurity module (avoid the latest version of it from the internet. Use one from \\opnasi02\Server\scripts\DeleteAppData_PS)
    2.XenApp snapin (or implicit remoting session to one of the collectors)

    Note : It will stop if it finds any connection in the new farm.

.EXAMPLE
   Delete-UPSProfile -name APC1354
.EXAMPLE
    Delete-UPSProfile ABC1DEF
#>
[CmdletBinding()]

Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $name
    )

$AllIsGood = $true
$Exitbtn.Enabled=$false
#$kancel.Enabled=$true

#check the user name and make sure user exists


    try
    {
        $who = Get-ADUser -Identity $name -Properties DisplayName
         
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        OutputText "User $name does not exist. Check spelling?`rYou have to use UPSFreight user name NOT US\ name`r"
        $allisgood = $false
    }

# Check for existing sessions in XA7
   If ($AllIsGood) {
        $who2 = $who.displayname
        OutputText "STEP1 1b: `rProcessing user $who2.`rChecking for existing sessions in XA7  `r"
            
            $connecttest13=test-connection wpctxi13 -quiet
            $connecttest14=test-connection wpctxi14 -quiet
            If ($connecttest13) {$controller="wpctxi13"}
            Else {If ($connecttest14) {$controller="wpctxi14"}
                Else {OutputText "There are no Delivery Controllers available to process this request"
                                    $Exitbtn.Enabled=$true
                                return  }}
            $nameupper=$name.ToUpper()
            $sesscount = get-brokersession -adminaddress $controller -brokeringusername RICHMOND\$nameupper
        $prop1a = $sesscount | select -ExpandProperty dnsname -Unique
        if ($sesscount.count -gt 0)
                {  #Write-Error "there are existing sessions. Please terminate them first"
                $a= "ERROR: There are existing sessions on $prop1a. Please terminate them first. Proccess cannot continue. `r"
           # Remove-PSSession -session $Xa7Session
                OutputText $a
                [boolean]$AllIsGood = $false
                }

        else {OutputText "There are no active sessions in the XenApp XA7 Farm `r`r"}
        }

#Step2 Now we go with real stuff unless there are existing sessions (Variable: $AllIsGood
if ($AllIsGood) 
            {[boolean]$AppdataIsGood = $true
            Outputtext "STEP 2: Deleting Appdata folder `r"
            $redir = "\\upgf.com\DFS-UPGF\ctx_users\$Name\REDIR"
            $checkforappdata = Test-Path "$redir\appdata"
            if(!$checkforappdata)
                {OutputText "WARNING: APPDATA folder at \\upgf.com\DFS-UPGF\users\$Name\REDIR does not exist.`rThat may not necessarily be a problem. `r`r"
                $AppdataIsGood = $false
                }
             }   
        
#Check for the ownership of appdata and take it if needed (unless there are existing sessions or appdata doesnt exist
if (($AllIsGood -eq $true) -and  ($AppdataIsGood -eq $true))
       {
                   
            $testOwner = Get-UPSOwner $name
            If ($testOwner.Owner -eq $null) {Take-Ownership $name}


    #2021-09-28 -- (WSH) -- Added section to make a backup of the MS Edge Bookmarks and Preferneces files       #  $redir="\\upgf.com\dfs-upgf\users\ntst002\redir"
    If(!(Test-Path "$redir\MSEdgeBookmarks_backup")) {
        If (Test-path "$redir\AppData\Microsoft\Edge\User Data\Default\Bookmarks") {
	        Copy-item -path "$redir\AppData\Microsoft\Edge\User Data\Default\Bookmarks" -destination "$redir\MSEdgeBookmarks_backup" -Force }  }
    If(!(Test-Path "$redir\MSEdgePreferences_backup")) {
        If (Test-path "$redir\AppData\Microsoft\Edge\User Data\Default\Preferences") {
	        Copy-item -path "$redir\AppData\Microsoft\Edge\User Data\Default\Preferences" -destination "$redir\MSEdgePreferences_backup" -Force }  }


            #test for pre-existing appdata.old and if exists, delete it
            if (Test-Path "$redir\appdata.old") {$nname = 'appdata.old'+((Get-date -f yyyyMMdd-HHmmss).tostring())
                                    Rename-Item "$redir\appdata.old" -NewName $nname -force
                                    OutputText "Existing appdata.old renamed to $nname `r" }
              Rename-Item "$redir\appdata" -NewName "appdata.old" -force
              OutputText "Existing appdata Folder renamed to appdata.old `r"
    

    # 2021-09-28 -- (WSH) -- Added section to restore the MS Edge Bookmarks and Preferences files
    If(Test-Path "$redir\MSEdgeBookmarks_backup") {
              If(!(Test-Path "$redir\appdata\microsoft\Edge\User Data\Default" )) {New-Item -ItemType directory -Path "$redir\appdata\microsoft\Edge\User Data\Default" }
              move-item -path "$redir\MSEdgeBookmarks_backup" -destination "$redir\AppData\Microsoft\Edge\User Data\Default\Bookmarks"  -Force }  
    If(Test-Path "$redir\MSEdgePreferences_backup") {
              If(!(Test-Path "$redir\appdata\microsoft\Edge\User Data\Default" )) {New-Item -ItemType directory -Path "$redir\appdata\microsoft\Edge\User Data\Default" }
	          move-item -path "$redir\MSEdgePreferences_backup" -destination "$redir\AppData\Microsoft\Edge\User Data\Default\Preferences"  -Force } 

        #Remove old appdata.old copies
        $myold = get-childitem "$redir\appdata*"  # $old.fullname
       ForEach ($myold1 in $myold) 
                 { 
                $mynow = get-date
                    If ($myold1.lastwritetime -le ($mynow).AddDays(-30) -and $myold -ne "appdata.old") {  
                    #write-host "$myold1.fullname" 
                    Remove-Item $myold1.fullname -recurse -force -ErrorAction SilentlyContinue}}  
                                        


        
        }    




 #Step3a Place Holder
 

#Step3b delete Citrix Profile unless there are existing sessions (variable $allisGood) -- Backup chrome and MSEdge Bookmark files FIRST
 $error.Clear()
 If ($AllIsGood)
{
    OutputText "Step 3: Deleting Citrix XA7 Profile `r"
    $fldrnames3b = Get-Childitem "\\upgf.com\dfs-upgf\xa7x_profiles\" -filter $name* -Directory    #   $fldr3b = "nfon157.v2"
    Foreach ($fldr3b in $fldrnames3b)
    {
        $b=Test-Path "\\upgf.com\dfs-upgf\xa7x_profiles\$fldr3b"  
        if ($b=$true)
        { 
            If (Test-path "\\opnasi02\ctx_profiles\xa7x_profiles\$fldr3b\UPM_Profile\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks")
            {
                Copy-item -path "\\opnasi02\ctx_profiles\xa7x_profiles\$fldr3b\UPM_Profile\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks" -destination "\\opnasi02\users\$UserFolder\Redir\MSEdgebookmarks" -Force | Out-Null;
            }
                else
            {
                OutputText "No Bookmarks present"
            }
          
            Remove-Item "\\upgf.com\dfs-upgf\xa7x_profiles\$fldr3b" -Recurse -Force  -ErrorAction SilentlyContinue 
            $b1=Test-Path "\\upgf.com\dfs-upgf\xa7x_profiles\$fldr3b"
            If ($b1=$true)
            {
                OutputText "Citrix Profile \\upgf.com\dfs-upgf\xa7x_profiles\$fldr3b deleted `r"
            }
                else
            {
                OutputText "Citrix Profile \\upgf.com\dfs-upgf\xa7x_profiles\$fldr3b was NOT deleted.  `r"
            }
        }
            else
        {
            OutputText "WARNING: Citrix XA7 Profile at \\upgf.com\dfs-upgf\xa7x_profiles\$fldr3b does not exist.`rThat may not necessarily be a problem.`r"
        }
    }
}

#Step4a go through Citrix servers and remove profile Folder if it exists (just in case)
#    If ($AllIsGood)
#        {
#            OutputText "`rSTEP 4a: Go through all XenApp XA6.5 servers and remove profile folder (if exists) `r" 
#            $i=0
#            $all = Get-XAServer -ZoneName VARMN -onlineonly | sort servername  # where servername -NotLike 'wpctxi*' |  sort servername   --  NOT SURE WHY NOT INCUDING DATA COLLECTORS SO COMMENTED OUT (WSH)
#            foreach ($xaserv in $all) 
#                {$i++
#                $serv = $xaserv.ServerName
#                [string]$servnumbr = $serv.Split('A')[1]
#               
#                OutputText "$serv, "
#                #OutputText "Checking \\$serv\C$\users\$username `r"
#                #Write-Progress -Activity 'Profile deletions' -Status 'PRogress:' -PercentComplete ($i/($all.count)*100)
#                            $testpath = Test-Path "\\$serv\C$\users\$username"
#                
#                            if ($testpath) 
#                                {OutputText "`rFound \\$serv\C$\users\$username ...Removing`r"
#
#                                    #handling deletion error for some reason TRy-Catch didn't work
#                                        $Error.Clear()
#                                        Remove-Item "\\$serv\C$\users\$username" -Recurse -Force -ErrorAction SilentlyContinue
#                                            if ($? -eq $false) {
#                                            $errormessage = $error[0].Exception.Message
#                                            OutputText "ERROR: $errormessage `r`r"
#                                            }
#                                }
#                }
#        }
#   
#   # OutputText "`rEND"


#Step4b go through Citrix servers and remove profile Folder if it exists (just in case)
    If ($AllIsGood)
        {
            OutputText "`rSTEP 4b: Go through all XenApp XA7 servers and remove profile folder (if exists) `r" 
            $i=0
$xa7svr = get-brokermachine -adminaddress $controller  -Filter {RegistrationState -eq 'Registered'} 
$xa7svr +=  get-brokercontroller  -adminaddress $controller
            foreach ($xaserv in $xa7svr) 
                {$i++
                $serv = $xaserv.dnsname
              #  [string]$servnumbr = $serv.Split('A')[1]   --  NOT BEING USED ANYWHERE SO COMMENTED OUT (WSH)
               
                OutputText "$serv, "
                #OutputText "Checking \\$serv\C$\users\$username `r"
                #Write-Progress -Activity 'Profile deletions' -Status 'PRogress:' -PercentComplete ($i/($all.count)*100)


                           $Localfldrs=Get-Childitem "\\$serv\C$\users\" -filter $name -Directory
                           Foreach ($Lfldr in $Roamfldrs)
                            {

                            $testpath = Test-Path "\\$serv\C$\users\$Lfldr"
                
                            if ($testpath) 
                                {OutputText "`rFound \\$serv\C$\users\$Lfldr ...Removing`r"

                                    #handling deletion error for some reason TRy-Catch didn't work
                                        $Error.Clear()
                                        Remove-Item "\\$serv\C$\users\$Lfldr" -Recurse -Force -ErrorAction SilentlyContinue
                                            if ($? -eq $false) {
                                            $errormessage = $error[0].Exception.Message
                                            OutputText "ERROR: $errormessage `r`r"
                                            } 
                                }
                } }
        }
   
    OutputText "`rEND"
    $Exitbtn.Enabled=$true
    #$kancel.Enabled=$false
      OutputText "`r         End Time: $(get-date) `r"

}
#endregion functions related to actual delete profile part



Add-PSSnapin citrix.broker.admin.v2 -ErrorAction SilentlyContinue
Import-Module active* -ErrorAction SilentlyContinue
#Call the Function

GenerateForm



