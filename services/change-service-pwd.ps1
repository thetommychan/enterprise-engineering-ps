function Test-ServiceAccounts 
{
    param(
        [string]$Server,
        [string]$serviceName
    )
    
    $serviceFetch = Invoke-Command -ComputerName $Server -ScriptBlock {
        param(
            $serviceName
        )
        
        $services = Get-WmiObject Win32_Service | Where-Object { $_.Name -like $serviceName } | Select-Object -Property Name -ExpandProperty Name
        return $services
    } -ArgumentList $serviceName

    return $serviceFetch
}

$serverName = $Server
$serviceName = $serviceName

$validServices = Test-ServiceAccounts -Server $serverName -serviceName $serviceName

if ($validServices -ne $null -and $validServices.Count -gt 0)
{
    Write-Host -ForegroundColor Black -BackgroundColor Green "Valid service(s):"
    
    foreach ($service in $validServices)
    {
        Write-Host $service
    }
}
else
{
    Write-Host -ForegroundColor Black -BackgroundColor Red "No valid services found."
}



function Update-ServiceAccounts {
    param (
        [parameter(Mandatory=$true)]
        [string]$Server,
        [SecureString]$Password,
        [switch]$ViewOnly
    )

$Server = Read-Host -Prompt "Enter the server name"

# Prompt for password without whitespaces or leading spaces
$passwordInput = Read-Host -Prompt "Paste the password, no whitespaces or leading spaces" -AsSecureString

# Conditions for Service accounts and Service Names if multiple being changed
<#
$services = Get-WmiObject -ComputerName $server Win32_Service | Where-Object { $_.Name -match ($serviceConditions.Keys -join '|') }
$serviceConditions = @{
    "" = "RICHMOND\"
}
#>


# Change logon info for service accounts and provide status updates
foreach ($service in $services) {
    $serviceName = $service.Name
    $startName = $service.StartName

    Write-Host "Updating service '$serviceName' with start name '$startName'"

    if ($service.State -ne 'Running') {
        Write-Host "Service is not running. Changing service account and password."
        $condition = ($serviceConditions.GetEnumerator() | Where-Object { $serviceName -match $_.Key }).Value
        $service.Change($null, $null, $null, $null, $null, $null, $condition, $passwordInput, $null, $null)
    } else {
        Write-Host "Service is running. Stopping, changing service account and password, then starting."
        $service.StopService()
        $condition = ($serviceConditions.GetEnumerator() | Where-Object { $serviceName -match $_.Key }).Value
        $service.Change($null, $null, $null, $null, $null, $null, $condition, $passwordInput, $null, $null)
        $service.StartService()
    }

    Write-Host "Service '$serviceName' updated."
}


    $services = Get-WmiObject -ComputerName $server Win32_Service | Where-Object { $_.Name -match ($serviceConditions.Keys -join '|') }

    foreach ($service in $services) {
        $serviceName = $service.Name
        $startName = $service.StartName

        Write-Host "Service Name: $serviceName"
        Write-Host "Start Name: $startName"

        if ($ViewOnly) {
            continue
        }

    }
} Update-ServiceAccounts -Server 


#Invoke-Command -ComputerName wppnd -ScriptBlock {Get-Service | Where-Object {$_.Name -Like "*EDGEtoPND*"} | Restart-Service}


# TESTING

$serviceNames = @(
"UPGF ECD Getpros Periodic Service_Blue",
"UPGF PRD 20 Instances of Bg DIAD Master P009",
"UPGF PRD A_Range_ECD_A010",
"UPGF PRD BG_DIAD_A_P009",
"UPGF PRD BG_DIAD_BETA_P009",
"UPGF PRD BG_DIAD_B_P009",
"UPGF PRD BG_DIAD_C_P009",
"UPGF PRD BG_DIAD_D_P009",
"UPGF PRD BG_DIAD_E_P009",
"UPGF PRD BG_DIAD_F_P009",
"UPGF PRD BG_DIAD_G_P009",
"UPGF PRD BG_DIAD_H_P009",
"UPGF PRD BG_DIAD_I_P009",
"UPGF PRD BG_DIAD_J_P009",
"UPGF PRD BG_DIAD_K_P009",
"UPGF PRD BG_DIAD_L_P009",
"UPGF PRD BG_DIAD_M_P009",
"UPGF PRD BG_DIAD_N_P009",
"UPGF PRD BG_DIAD_O_P009",
"UPGF PRD BG_DIAD_P_P009",
"UPGF PRD BG_DIAD_Q_P009",
"UPGF PRD BG_DIAD_R_P009",
"UPGF PRD BG_DIAD_S_P009",
"UPGF PRD BG_DIAD_T_P009",
"UPGF PRD BG_DIAD_U_P009",
"UPGF PRD BG_DIAD_V_P009",
"UPGF PRD BG_EDGEtoPND",
"UPGF PRD BG_Host_A_P009",
"UPGF PRD BG_HOST_BETA_P009",
"UPGF PRD BG_Host_B_P009",
"UPGF PRD BG_Host_C_P009",
"UPGF PRD BG_Host_D_P009",
"UPGF PRD BG_HOST_ECD_P009",
"UPGF PRD BG_HOST_ECD_P010B",
"UPGF PRD BG_Host_E_P009".
"UPGF PRD BG_Host_F_P009",
"UPGF PRD BG_Host_G_P009",
"UPGF PRD BG_Host_H_P009",
"UPGF PRD BG_Host_I_P009",
"UPGF PRD BG_Host_J_P009",
"UPGF PRD BG_Host_K_P009",
"UPGF PRD BG_Host_L_P009",
"UPGF PRD BG_Host_M_P009",
"UPGF PRD BG_Host_N_P009",
"UPGF PRD BG_Host_O_P009",
"UPGF PRD BG_Host_P_P009",
"UPGF PRD BG_Host_Q_P009",
"UPGF PRD BG_Host_R_P009",
"UPGF PRD BG_Host_S_P009",
"UPGF PRD BG_Host_T_P009",
"UPGF PRD BG_Host_U_P009",
"UPGF PRD BG_PNDtoEDGE",
"UPGF PRD BG_Purge_P009",
"UPGF PRD B_Range_ECD_A010",
"UPGF PRD DynRoute Master P009",
"UPGF PROD BG_DIAD6B_P009",
"UPGF PROD BG_DIAD6C_P009",
"UPGF PROD BG_DIAD6D_P009",
"UPGF PROD BG_DIAD6E_P009",
"UPGF PROD BG_DIAD6_Beta_P009",
"UPGF PROD BG_DIAD6_Master_P009",
"UPGF Prod CustImp P009",
"UPGF Prod DispGeo",
"UPGF_Router"
)