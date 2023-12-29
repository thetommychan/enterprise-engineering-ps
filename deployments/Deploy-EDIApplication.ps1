<#
.SYNOPSIS
    The purpose of this script is to deploy new versions of the EDI applications to
    Prouction servers. The script Accepts 3 parameters from the user:
    1.  Source; The source is the server from which the deployment files are staged.
    If the source is different from wtedia15, the source has to be
    defined. If the source is wtedia15, the source does not need to be defined as this
    is the typical staging server. 
    2.  Destination; The Destination is the production server to which the staged files
    are being deployed. The Destination parameter is mandatory.
    3.  AppDir; The AppDir is the folder on the Source server that contains the staged
    deployment files.

.DESCRIPTION
    Run this script by calling it from the Share located at \\opnasi02\server\tom\scripts. 
    Define the Source (if different from WTEDIA15), define the Destination, and define the AppDir.
    Once run with these parameters, the script copies the staged files from the source to the 
    destination production server in the staging directory. Then, the script deploys those staged
    files to the working directory of the app on the production server and displays the working 
    directory to verify the changes were made.


.PARAMETER Source
    The server from which the files are staged for deployment. In this case, the files are staged in
    C:\Stage on one of three test servers: WTEDIA13/14/15
    If the source (as defined by the developer) is WTEDIA15, the Source does not need to be defined 
    as a parameter.

.PARAMETER Destination
    The production server to which the staged files are copied for deployment. For this app, the files 
    are staged in C:\Stage on one of 7 production servers: WPEDIA11/12/14/15/16/17/18. This parameter
    is mandatory. 
    If the destination server entered doesn't contain a P for production, it will confirm that's the 
    server you want to use. 
    If the servername doesn't match the nomenclature of the edi app servers it will once again ask 
    if the server name entered is the right server name.

.PARAMETER AppDir
    The application folder that contains the staged deployment files. This is also the same folder 
    on the production server that the staged files will be deployed to.

.EXAMPLE
    .\edi-deployment.ps1 -Source WTEDIA14 -AppDir "Generic" -Destination WPEDIA14
    This will copy the Deployment App Directory "Generic" from the WTEDIA14 staging directory to the staging directory on
    WPEDIA14, then it will deploy those files to the working directory using the .bat script in that folder. 

.EXAMPLE
    .\edi-deployment.ps1 -AppDir "997_MissingAcknowledgements" -Destination WPEDIA12
    This will copy the Deployment App Directory "997_MissingAcknowledgements" from the WTEDIA15 staging directory to the staging directory on
    WPEDIA12, then it will deploy those files to the working directory using the .bat script in that folder.
    

.NOTES
    Author: Tom Chandler
    Version: 1.0
    Date: 12/06/2023
#>


param(
    [CmdletBinding()]
    [Parameter(Mandatory = $false, Position = 0, HelpMessage="The Source will be the Server from which the staged files will be copied.")]
    [string]$Source,
    [Parameter(Mandatory = $true, Position = 1, HelpMessage="The Destination will be the Server to which the staged files will be copied and deployed.")]
    [string]$Destination,
    [Parameter(Mandatory = $true, Position = 2, HelpMessage="The AppDir is the directory of the app or app segment in the Stage folder.")]
    [string]$AppDir
)

##############################################
################ Logging #####################
##############################################
try 
{
    $logPath = "\\opnasi02\server\tom\scripts\logs\edi"
    $logDir = Get-Date -Format "yyyy.MMM"
    $deploymentLog = "deployment.$((Get-Date).ToString('yyyy.MM.dd'))"
    if (Test-Path $logPath\$logDir)
    {
        Start-Transcript -Path $logPath\$logDir\$deploymentLog.log -Append
    }
    elseif (!(Test-Path $logPath\$logDir))
    {
        New-Item -Path $logPath -ItemType Directory -Name $logDir
        Start-Transcript -Path $logPath\$logDir\$deploymentLog.log -Append
    }
##############################################
################ Logging #####################
##############################################

# Import Modules
Import-Module Microsoft.PowerShell.Utility

    <#  Determine Source if not specified or if specified as typical staging server. 
        The goal here is to only have to specify a source server if it's different 
        from wtedia15, or the typical staging server  #>
    if (-not $Source -or $Source -eq "wtedia15")
    {
        # Logic to determine the appropriate test server based on your conditions
        # For example, you could set the $Source to a different Source server if not specified, or use any other logic
        $Source = "wtedia15"
    }

    # Check to make sure server is production
    if ($Destination -notlike "WP*")
    {
        $prompt1 = Read-Host -Prompt "The destination specified is not a production server. Continue? (Y/N)"
        if ($prompt1 -eq 'y' -or $prompt -eq '')
        {
            Write-Host -ForegroundColor Green "Proceeding..."
        }
        elseif ($prompt1 -eq 'N')
        {
            Stop-Transcript;
            break;
        }
    }

    # Check to make sure server name matches EDI App Server nomenclature
    if ($Destination -notmatch ("W*EDIA1[1,2,4,5,6,7,8]$"))
    {
        Write-Host -ForegroundColor Black -BackgroundColor Yellow "Please Verify the servername again:"
        Write-Host -ForegroundColor Black -BackgroundColor Yellow "`n$Destination"
        $prompt2 = Read-Host -Prompt "`nContinue? (Y/N)"
        if ($prompt2 -eq 'Y' -or $prompt2 -eq '')
        {
            Write-Host -ForegroundColor Green "Deploying $AppDir to $Destination from $Source"
        }
        elseif ($prompt2 -eq 'N')
        {
            Stop-Transcript;
            break;
        }
    }

    # Function to stage deployment files to destination server
    function Copy-DeploymentFile
    {
        [CmdletBinding()]
        param(
            [string]$AppDir,
            [string]$Source,
            [string]$Destination
        )
        try 
        {
            Write-Host -ForegroundColor Green "Staging Deployment Files..."
                Invoke-Command -ComputerName wpadma01 -ScriptBlock {
                $DeploymentFolder1 = Get-ChildItem \\$using:Source\c$\stage\$using:AppDir\ | 
                Sort-Object -Property LastWriteTime -Descending | 
                Select-Object -First 1 | 
                Select-Object -Property Name -ExpandProperty Name
                $dirCheck = Get-ChildItem \\$using:Destination\c$\Stage\$using:AppDir\$DeploymentFolder1 -ErrorAction SilentlyContinue
                if (!($dirCheck))
                {
                    Write-Host -ForegroundColor Green "Creating $DeploymentFolder1 Folder on $Destination"
                    New-Item -Path \\$using:Destination\c$\Stage\$using:AppDir\ -ItemType Directory -Name $DeploymentFolder1
                }
                Copy-Item \\$using:Source\c$\stage\$using:AppDir\$DeploymentFolder1 \\$using:Destination\c$\Stage\$using:AppDir\ -Force -Recurse -Verbose -ErrorAction SilentlyContinue | Out-Null
            } -ConfigurationName tom
            if ($?)
            {
                Write-Host -ForegroundColor Green "$AppDir Staged Successfully"
            }
        }
        catch
        {
            $errorMessage = $Error[0].ToString()
            Write-Host "Error: $errorMessage"
            Stop-Transcript;
            break;
        }
    }

    # Function to perform the deployment from the stage directory to the working directory.
    function Set-EDIDeployment
    {
        [CmdletBinding()]
        param(
            [string]$AppDir,
            [string]$Source,
            [string]$Destination
        )

        try
        {
            Copy-DeploymentFile -AppDir $AppDir -Source $Source -Destination $Destination;
            Write-Host -ForegroundColor Green "Deploying $AppDir..."
            Invoke-Command -ComputerName $Destination -ScriptBlock {
                $DeploymentFolder2 = Get-ChildItem C:\stage\$using:AppDir\ | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
                $batFile = Get-ChildItem C:\stage\$using:AppDir\$DeploymentFolder2\*.bat | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 | Select-Object -Property Name -ExpandProperty Name
                Set-Location C:\Stage\$using:AppDir\$DeploymentFolder2
                Invoke-Expression -Command C:\stage\$using:AppDir\$DeploymentFolder2\$batFile
                Write-Host -ForegroundColor Green $batFile
            }
            if ($?)
            {  
                Write-Host -ForegroundColor Green "Deployment Completed Successfully"
                Write-Host -ForegroundColor Black -BackgroundColor Green "Please verify the C:\ctapps directory contains the correct files below:"
                Get-ChildItem \\$Destination\c$\ctapps\$AppDir\bin
            }   
        }
        catch
        {
            $errorMessage = $Error[0].ToString()
            Write-Host "Error: $errorMessage"
            Stop-Transcript;
            break;
        }
    }

    Set-EDIDeployment -AppDir $AppDir -Source $Source -Destination $Destination
}
finally
{
    Stop-Transcript
}
