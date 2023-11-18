function Get-VLANs {

        param (
            [string]$ServerName
        )
    
    
    $vMachines = Get-Cluster 'Test-Inside' | Get-VM | Get-NetworkAdapter | Select-Object Parent,NetworkName, @{name='VlanID';e={(get-virutalportgroup -Name $_.NetworkName | select -First 1).vlanid}} -ExpandProperty Parent, NetworkName
    $vIPs = Get-Cluster 'Test-Inside' | Get-VM | Select Name,VMHost, @{N="IPAddress";E={@($_.guest.IPAddress -join '|')}}

} Get-Cluster 'Test-Inside' | Get-VM | Select Name,VMHost, @{N="IPAddress";E={@($_.guest.IPAddress -join '|')}} | Export-Excel C:\vscode\vSphere\VLANs\vm_ip_export.xlsx