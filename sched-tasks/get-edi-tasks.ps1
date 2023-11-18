Invoke-Command -ComputerName wpedia15 -ScriptBlock { 
    $check = Get-Module -ListAvailable | Where-Object {$_.Name -eq 'importexcel'}
    if(!($check))
    {
        Write-Host "Installing..."
        Install-Module importexcel;
    }
    else
    {
        Write-Host "Importing..."
        Import-Module importexcel;
    }
    $tasks = Get-ScheduledTask -TaskPath '\EDI\' | 
    Where-Object {$_.TaskName -notlike "*generic_custom_p001_weekly*" -and 
    $_.TaskName -notlike "*generic_custom_p001_weekly_epplus*" -and 
    $_.TaskName -notlike "*generic_custom_p014_monthly*" -and 
    $_.TaskName -notlike "*generic_custom_p014_monthly_epplus*" -and 
    $_.TaskName -notlike "*generic_epplus pdf*" -and 
    $_.TaskName -notlike "*generic pdf*" -and 
    $_.TaskName -notlike "*Generic-Noparms*" -and 
    $_.TaskName -notlike "*pdfinvoice*" -and 
    $_.TaskName -notlike "*cass*" -and 
    $_.TaskName -notlike "*POM*" -and
    $_.TaskName -notlike "*Generic-epplus_Noparms*" } | Select-Object -Property TaskName -ExpandProperty TaskName
    foreach ($task in $tasks){ Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath '\EDI\' }
    {
        Export-ScheduledTask -TaskName $task.TaskName -TaskPath '\EDI\' | Export-Excel "c:\task-backups\$task.TaskName.xlsx"
    }
}# | Out-File "C:\vscode\psscripts\out-files\tasks-to-remove.txt" # psprofile


Invoke-Command -ComputerName wpedia07 -ScriptBlock {Get-ScheduledTask | Where-Object {$_.TaskName -like "*faxclient*"} | Export-ScheduledTask -Verbose | out-file c:\faxclient.xml}