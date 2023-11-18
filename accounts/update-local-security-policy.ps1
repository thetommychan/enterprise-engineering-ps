# Add ID to local admin group on remote server

function Add-LocalAdminRemote
{
    param(
        [Parameter(Position=0,mandatory=$true)]
        [string]$ServerName,
        [Parameter(Position=1,mandatory=$true)]
        [string]$Name
    )

    Invoke-Command -ComputerName $ServerName -ScriptBlock {Add-LocalGroupMember -Group Administrators -Member $using:Name -Verbose}
}