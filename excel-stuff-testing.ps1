# # Load the Excel data
# $data = Import-Excel -Path 'C:\Users\QQQ9XMB\OneDrive - TForce Freight\Documents\Production NBCH100 Cutover\testing.xlsx' -WorksheetName "Sheet1"

# # Loop through each row and update the columns
# foreach ($row in $data) {
#     $row.Server = $row.ColumnA -replace ' Server = '
#     $row.Service = $row.ColumnB -replace ' Service Name = '
#     $row.Logon = $row.ColumnC -replace ' .'
# }

# $data | Export-Excel -Path 'C:\Users\QQQ9XMB\OneDrive - TForce Freight\Documents\Production NBCH100 Cutover\testing.xlsx' -WorksheetName 'Sheet2' -AutoSize -Show


# Load the Excel data
$data = Import-Excel -Path 'C:\Users\QQQ9XMB\OneDrive - TForce Freight\Documents\Production NBCH100 Cutover\testing.xlsx' -WorksheetName "Sheet1"

# Loop through each row and update the columns
$updatedData = $data | Select-Object -Property @{
    Name = 'Server'
    Expression = { $_.ColumnA -replace 'Server = ' }
}, @{
    Name = 'Service'
    Expression = { $_.ColumnB -replace 'Service Name = ' }
}, @{
    Name = 'Logon'
    Expression = { $_.ColumnC -replace ' \.' }
}

# Save the updated data back to the Excel file (if needed)
$updatedData | Export-Excel -Path 'C:\Users\QQQ9XMB\OneDrive - TForce Freight\Documents\Production NBCH100 Cutover\testing.xlsx' -WorksheetName 'Sheet2' -AutoSize -Show
