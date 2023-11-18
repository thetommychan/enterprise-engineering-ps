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

$newTextLine  | out-file -FilePath $outfile1 -Append 
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
}