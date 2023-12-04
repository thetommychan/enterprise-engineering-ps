# Installed Module AzureAD
# Installed Module MSOnline
# Login
Connect-AzureAD

# Import Users
$users = Import-Excel -Path "C:\AzureExports\AzureADUsers.xlsx"
foreach ($user in $users) {
    # Creating "new Users" into test tenant
    New-AzureADUser -UserPrincipalName $user.UserPrincipalName -DisplayName $user.DisplayName -MailNickName $user.MailNickName -AccountEnabled $true
}

# Import Groups
$groups = Import-Excel C:\AzureExports\AzureADGroups.xlsx
foreach ($group in $groups) {
    New-AzureADGroup -DisplayName $group.DisplayName -MailNickName $group.MailNickName -MailEnabled $group.MailEnabled -SecurityEnabled $group.SecurityEnabled -Description $group.Description
}

# Import CA Policies

$policies = Get-Content "C:\AzureExports\ConditionalAccessPolicies.json" | ConvertFrom-Json
foreach ($policy in $policies) {
    #Map conditions, controls, and other settings from the source policy
    New-AzureADMSConditionalAccessPolicy -DisplayName $policy.DisplayName # ... other parameters
}
