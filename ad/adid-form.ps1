Add-Type -AssemblyName System.Windows.Forms
function Generate-RandomADID
{
    $First = (-join ((65..90) + (97..122) | Get-Random -Count 3 | % {[char]$_})).toUpper()
    $Num = Random(10)
    $Second = (-join ((65..90) + (97..122) | Get-Random -Count 3 | % {[char]$_})).toUpper()   
    $Username = $First+$Num+$Second
    #Check if exist in AD
    if (Get-ADUser -F {SamAccountName -eq $Username})
    {
        Generate-RandomADID
    }
    else
    {
        $Username
    }
}

# Define the form
$form = New-Object Windows.Forms.Form
$form.Text = "ADID Generator"
$form.Size = New-Object Drawing.Size @(300,150)
$form.StartPosition = "CenterScreen"

# Create label to display the generated ID
$label = New-Object Windows.Forms.Label
$label.Text = "Generated ADID:"
$label.Location = New-Object Drawing.Point @(20, 10)
$form.Controls.Add($label)

# Create textbox to display the generated ID
$textbox = New-Object Windows.Forms.TextBox
$textbox.Location = New-Object Drawing.Point @(20, 35)
$textbox.Size = New-Object Drawing.Size @(200, 40)
$form.Controls.Add($textbox)

# Create button to generate random ADID
$buttonGenerate = New-Object Windows.Forms.Button
$buttonGenerate.Text = "New ADID"
$buttonGenerate.Location = New-Object Drawing.Point @(20, 70)
$buttonGenerate.Add_Click({
    $generatedID = Generate-RandomADID
    $textbox.Text = $generatedID
})
$form.Controls.Add($buttonGenerate)

# Create button to close the form
$buttonClose = New-Object Windows.Forms.Button
$buttonClose.Text = "Close"
$buttonClose.Location = New-Object Drawing.Point @(150, 70)
$buttonClose.Add_Click({
    $form.Close()
})
$form.Controls.Add($buttonClose)

# Show the form
$form.ShowDialog()