param (
    [string]$Action,
    [string]$TargetUser
)

# Import the Active Directory module (if not already loaded)
Import-Module ActiveDirectory

# Define a function to change the password
function Change-ADPassword {
    param (
        [string]$Username,
        [string]$NewPassword
    )

    $securePassword = ConvertTo-SecureString -String $NewPassword -AsPlainText -Force
    Set-ADAccountPassword -Identity $Username -NewPassword $securePassword -Reset
    Write-Host "Password changed for user $Username."
}

# Define a function to reset the password
function Reset-ADPassword {
    param (
        [string]$Username
    )

    $newPassword = [System.Web.Security.Membership]::GeneratePassword(12, 3)
    $securePassword = ConvertTo-SecureString -String $newPassword -AsPlainText -Force
    Set-ADAccountPassword -Identity $Username -NewPassword $securePassword -Reset
    Write-Host "Password reset for user $Username. New password: $newPassword"
}

# Define a function to view password expiration
function View-ADPasswordExpiration {
    param (
        [string]$Username
    )

    $user = Get-ADUser -Identity $Username -Properties "PasswordLastSet", "PasswordNeverExpires", "Enabled"
    
    if ($user.Enabled -eq $false) {
        Write-Host "User $Username is disabled."
    } elseif ($user.PasswordNeverExpires -eq $true) {
        Write-Host "Password for user $Username never expires."
    } else {
        $passwordLastSet = $user.PasswordLastSet
        $maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
        $expirationDate = $passwordLastSet + $maxPasswordAge
        Write-Host "Password for user $Username expires on: $expirationDate"
    }
}

# Perform the specified action
if ($Action -eq "change") {
    Change-ADPassword -Username $TargetUser -NewPassword "NewPassword123"
} elseif ($Action -eq "reset") {
    Reset-ADPassword -Username $TargetUser
} elseif ($Action -eq "view") {
    View-ADPasswordExpiration -Username $TargetUser
} else {
    Write-Host "Invalid action. Valid actions: change, reset, view."
}
