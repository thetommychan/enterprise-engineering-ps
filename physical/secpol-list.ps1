$list = Get-AccountsWithUserRight SeServiceLogonRight -computer $serverName | Select-Object account
$secpol = $list.account
if ($secpol -notcontains "$serviceAccount")
{
    Invoke-Command -ComputerName $serverName -ScriptBlock {Add-LocalGroupMember -Group Administrators -Member NBCH100 -Verbose}
}