# Specify the computer name you want to search for
$computerName = Read-Host -Prompt "Enter the server/computer name"

# Search Active Directory for the computer
$computer = Get-ADComputer -Filter {Name -eq $computerName}

# Check if the computer was found
if ($null -ne $computer) {
    Write-Host "Computer found in Active Directory:"
    $computer | Format-Table -Property Name, DistinguishedName -AutoSize
} else {
    Write-Host "Computer not found in Active Directory."
}