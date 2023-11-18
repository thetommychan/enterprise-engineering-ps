    <#-------
    Functions
    -------#>


# Check password for consistency
function PasswordCheck 
{
    $NewPassword1 = read-host -Prompt "Enter the new password" -AsSecureString
    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($NewPassword1)
    $result1 = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)

    $verifiedPassword = read-host -Prompt "Enter the new password again" -AsSecureString
    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($verifiedPassword)
    $result2 = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)

    IF ($result1 -ne $result2) 
    {
        Write-Host "Passwords do not match, try again"
        Start-Sleep 2
        PasswordCheck
    }
}

# Change UPS Password
function Change-ADPasswordUPS
{
param
(
    [parameter(Mandatory=$true)]
    [string]$Username
)
    # Variables
    $credential = Get-Credential
    $expireDateUPS = Invoke-Command -ComputerName wpadma01 -ScriptBlock {Get-ADUser -Identity $using:Username -Credential $using:credential -Server usdc01 -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}}
    $expirationUPS = $expireDateUPS | Select-Object -Property ExpiryDate -ExpandProperty ExpiryDate

    # Warnings
    Write-Host -ForegroundColor Black -BackgroundColor Red "WARNING: You are attempting to change the UPS Active Driectory Password for $username. `nPlease ensure this user is aware of the change and the intended account is correct."
    $change = read-host -Prompt "This User's UPS Password expires on $expirationUPS. Would you like to change it now? y/n"

    # exit startegy...
    if ($Username -eq "exit")
    {
        "Returning to menu..."
        continue
        Show-MainMenu
    }
    if ($change -eq 'n')
    {
    Write-Host -ForegroundColor Black -BackgroundColor White "UPS Password was not changed and expires on $expirationUPS.";
    start-sleep -seconds 2;
    Show-MainMenu
    }
    elseif ($change -eq 'y' -or '')
    {
        $known = Read-Host -Prompt "Is the current password for this account known? y/n"
        if ($known -eq 'y' -or '')
        {
            $OldPassword = read-host -Prompt "Enter the old password" -AsSecureString
            $NewPassword2 = read-host -Prompt "Enter the new password. Copy and paste to avoid errors." -AsSecureString
            try
            {
                Invoke-Command -ComputerName wpadma01 -ScriptBlock {Set-ADAccountPassword -Identity $using:Username -Credential $using:credential -Server usdc01 -OldPassword $using:OldPassword -NewPassword $using:newPassword2 -ErrorAction SilentlyContinue}
                if (!($?))
                {
                    Write-Host -ForegroundColor Black -BackgroundColor Green "Password changed successfully and expires on $expirationUPS." 
                    start-sleep -seconds 2;
                    Show-MainMenu
                }
            }
            catch 
            {
                Write-Host "An error occurred: $($_.Exception.Message)"
                Write-Host -ForegroundColor Black -BackgroundColor Red "Password was not changed and expires on $expirationUPS. Returning to Main Menu..."
                Show-MainMenu
            }
        } 
        elseif ($known -eq 'n') 
        {
            $askIf = read-host -prompt "This will reset the password and generate a random password for this user. Are you sure? y/n"
            if ($askIf -eq 'y' -or '')
            {
                Reset-ADPassword -Username $Username
                $goAgain = Read-Host -Prompt "Would you like to update another Active Directory password?"
                if ($goAgain -eq 'y' -or '')
                {
                    Change-ADPasswordUPS
                }
            }
            elseif ($askIf -eq 'n')
            {
                "Returning to menu..."
                Show-MainMenu
            }
            
        }
    }
}

# Change Active Directory Password
function Change-ADPassword
{
param
(
    [parameter(Mandatory=$true)]
    [string]$Username
)
    # Variables
    $expireDateElse = Get-ADUser -Identity $Username -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
    $expirationElse = $expireDateElse | Select-Object -Property ExpiryDate -ExpandProperty ExpiryDate

    # Warnings
    Write-Host -ForegroundColor Black -BackgroundColor Red "WARNING: You are attempting to change the Active Directory Password for $username. `nPlease ensure this user is aware of the change and the intended account is correct."
    $change = read-host -Prompt "This Active Directory Password expires on $expirationElse. Would you like to change it now? y/n"

    # exit startegy...
    if ($Username -eq "exit")
    {
        "Returning to menu..."
        continue
        Show-MainMenu
    }
    if ($change -eq 'n')
    {
    Write-Host -ForegroundColor Black -BackgroundColor White "TFF Password was not changed and expires on $expirationElse."
    Show-MainMenu
    }
    elseif ($change -eq 'y' -or '')
    {
        $known = Read-Host -Prompt "Is the current password for this account known? y/n"
        if ($known -eq 'y' -or '')
        {
            $OldPassword = read-host -Prompt "Enter the old password" -AsSecureString
            PasswordCheck
            try
            {
                Set-ADAccountPassword -Identity $Username -OldPassword $OldPassword -NewPassword $verifiedPassword -ErrorAction SilentlyContinue
                if (!($?))
                {
                    Write-Host -ForegroundColor Black -BackgroundColor Green "Password changed successfully and expires on $expirationElse." 
                    
                }
            }
            catch 
            {
                Write-Host "An error occurred: $($_.Exception.Message)"
                Write-Host -ForegroundColor Black -BackgroundColor Red "Password was not changed and expires on $expirationElse. Returning to Main Menu..."
                Show-MainMenu
            }
        } 
        elseif ($known -eq 'n') 
        {
            $askIf = read-host -prompt "This will reset the password and generate a random password for this user. Are you sure? y/n"
            if ($askIf -eq 'y' -or '')
            {
                Reset-ADPassword -Username $Username
                $goAgain = Read-Host -Prompt "Would you like to reset a password again?"
                if ($goAgain -eq 'y' -or '')
                {
                    Change-ADPassword
                }
            }
            elseif ($askIf -eq 'n')
            {
                "Returning to menu..."
                Show-MainMenu
            }
            
        }
    }
}

function Reset-ADPassword
{

    param
    (
        [string]$Username
    )

    $newPassword = [System.Web.Security.Membership]::GeneratePassword(12, 3)
    $securePassword = ConvertTo-SecureString -String $newPassword -AsPlainText -Force
    Set-ADAccountPassword -Identity $Username -NewPassword $securePassword -Reset -Verbose
    Write-Host -ForegroundColor Black -BackgroundColor Green "The new password for $accountName is: $newPassword"
}

# View password expiration date
function View-ADPasswordExpirationUPS 
{
param 
(
    [parameter(Mandatory=$true)]
    [string]$Username
)

if ($Username -eq "q")
    {
        "Returning to menu..."
        Show-MainMenu
    }
    # Variables
    $credential = Get-Credential
    $expireDateUPS = Invoke-Command -ComputerName wpadma01 -ScriptBlock {Get-ADUser -Identity $using:Username -Credential $using:credential -Server usdc01 -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}}
    $expirationUPS = $expireDateUPS | Select-Object -Property ExpiryDate -ExpandProperty ExpiryDate
    $user = Get-ADUser -Identity $Username -Properties "PasswordLastSet", "PasswordNeverExpires", "Enabled"
    
    if ($user.Enabled -eq $false) 
    {
        Write-Host -ForegroundColor Black -BackgroundColor White "User $Username is disabled."
        Write-Host -ForegroundColor Black -BackgroundColor White "Returning to menu..."
        Show-MainMenu
    } 
    elseif ($user.PasswordNeverExpires -eq $true) 
    {
        Write-Host -ForegroundColor Black -BackgroundColor White "Password for user $Username never expires."
        Write-Host -ForegroundColor Black -BackgroundColor White "Returning to menu..."
        Show-MainMenu
    } 
    else 
    { 
        Write-Host -ForegroundColor Black -BackgroundColor White "Password for user $Username expires on: $expirationUPS"
        Write-Host -ForegroundColor Black -BackgroundColor White "Returning to menu..."
        Show-MainMenu
    }
}

function View-ADPasswordExpiration 
{
param 
(
    [parameter(Mandatory=$true)]
    [string]$Username
)

if ($Username -eq "q")
    {
        "Returning to menu..."
        Show-MainMenu
    }
    # Variables
    $expires = Get-ADUser -Identity $Username -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "Displayname",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
    $expiring = $expires | Select-Object -Property ExpirtyDate -ExpandProperty ExpiryDate
    $user = Get-ADUser -Identity $Username -Properties "PasswordLastSet", "PasswordNeverExpires", "Enabled"
    
    if ($user.Enabled -eq $false) 
    {
        Write-Host -ForegroundColor Black -BackgroundColor White "User $Username is disabled."
        Write-Host -ForegroundColor Black -BackgroundColor White "Returning to menu..."
        Show-MainMenu
    } 
    elseif ($user.PasswordNeverExpires -eq $true) 
    {
        Write-Host -ForegroundColor Black -BackgroundColor White "Password for user $Username never expires."
        Write-Host -ForegroundColor Black -BackgroundColor White "Returning to menu..."
        Show-MainMenu
    } 
    else 
    { 
        Write-Host -ForegroundColor Black -BackgroundColor White "Password for user $Username expires on: $expiring"
        Write-Host -ForegroundColor Black -BackgroundColor White "Returning to menu..."
        Show-MainMenu
    }
}

# Check the expiration, change, reset and generate new random (if unknown) passwords for your own, or someone else's AD Account
Import-Module ActiveDirectory -ErrorAction Inquire
# Perform specified actions
#-------------------------#

# Display options to run
function Show-MainMenu
{
$homeMenuOptions = @"
Home Menu:
$masterPrompt
1. Change UPS Password
2. Change Active Directory Password
3. View UPS Account Password Expiration
4. View AD Account Password Expiration
5. Exit
"@
Write-Host $homeMenuOptions
$choice = Read-Host "Enter the number of the function you need to perform"

switch ($choice) {
    "1" {
        # Code for Option 1
        Change-ADPasswordUPS
    }
    "2" {
        # Code for Option 2
        Change-ADPassword
    }
    "3" {
        # Code for Option 3
        View-ADPasswordExpirationUPS
    }
    "4" {
        # Exit
        View-ADPasswordExpiration
    }
    "5" {
        # Exit
        break
    }
    default {
        Write-Host "Invalid choice. Please select a valid option."
    }
} 
} Show-MainMenu
