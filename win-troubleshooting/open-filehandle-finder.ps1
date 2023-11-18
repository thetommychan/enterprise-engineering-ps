# Specify the directory path you want to search
$directoryPath = read-host -prompt "Enter the directory name"

# Get a list of processes that have files open in the specified directory
$processesWithOpenHandles = Get-Process | ForEach-Object {
    $process = $_
    $openHandles = $process | Get-FileHandle | Where-Object { $_.FileName -like "$directoryPath\*" }
    if ($openHandles) {
        [PSCustomObject]@{
            ProcessName = $process.ProcessName
            Handles = $openHandles
        }
    }
}

# Display the processes with open file handles in the specified directory
$processesWithOpenHandles | Format-Table -AutoSize
