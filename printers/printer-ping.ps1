# Import the ImportExcel module
Import-Module ImportExcel

# Step 1: Import data from Excel
$printerData = Import-Excel -Path "C:\vscode\printer-xmls\wpprti02.xlsx"

# Step 2 and 3: Ping each printer and add IP address to the data
$printerData | ForEach-Object {
    $printerName = $_.'Printer Name'
    $pingResult = Test-Connection -ComputerName $printerName -Count 1 -ErrorAction SilentlyContinue
    Write-Host -ForegroundColor Blac -BackgroundColor White "Pigning $printerName..."
    $_ | Add-Member -MemberType NoteProperty -Name 'IP Address' -Value $pingResult.IPV4Address.IPAddressToString
}

# Step 4: Export modified data to a new Excel file
$printerData | Export-Excel -Path "C:\vscode\printer-xmls\printer_data_with_ip.xlsx" -NoHeader -AutoSize -WorksheetName "Sheet1"

Write-Host "IP addresses added and data exported to printer_data_with_ip.xlsx"
