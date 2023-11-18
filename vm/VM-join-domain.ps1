function Join-Domain
{
# Set the new computer name
$NewName = Read-Host -Prompt "Enter the new server name"

# Validate the new computer name (customize this validation as needed)
if ($NewName -match "^[a-zA-Z0-9-]+$") {
    # Get interface index
    $interfaceIndex = (Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet1"}).InterfaceIndex

    # Set the domain name
    $DomainName = "upgf.com"

    # Prompt for domain credentials
    $Credential = Get-Credential

    try {
        $NewName = Read-Host -Prompt "Enter the new server name"

        # Change the computer name
        Write-Host "User "
        Rename-Computer -NewName $NewName -LocalCredential (Get-Credential) -Force
        
        # Join the domain and set DNS suffix
        Add-Computer -DomainName $DomainName -Credential $Credential

        # Success message
        Write-Host -ForegroundColor Black -BackgroundColor Green "Server renamed and joined to the domain with DNS Suffix $DomainName. Resarting..."

        # Restart the server
        Restart-Computer -Force
    } catch {
        # Error message
        Write-Host "An error occurred: $_"
    }
} else {
    Write-Host "Invalid computer name. Please provide a valid name."
}
}