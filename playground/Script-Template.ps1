<#
.SYNOPSIS
    Brief description of the script.

.DESCRIPTION
    Detailed description of the script and its purpose.

.PARAMETER Parameter1
    Description of the first parameter.

.PARAMETER Parameter2
    Description of the second parameter.

.PARAMETER Parameter3
    Description of the third parameter.

.EXAMPLE
    .\YourScript.ps1 -Parameter1 Value1 -Parameter2 Value2
    Description of what this example does.

.EXAMPLE
    .\YourScript.ps1 -Parameter1 Value1 -Parameter3 Value3
    Another example with different parameters.

.NOTES
    Author: Your Name
    Version: 1.0
    Date: Date created or last modified.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0, HelpMessage="Description of Parameter1")]
    [string]$Parameter1,

    [Parameter(Position=1, HelpMessage="Description of Parameter2")]
    [int]$Parameter2 = 42,

    [Parameter(Position=2, HelpMessage="Description of Parameter3")]
    [switch]$Parameter3
)

# Begin the script logic
Write-Host "Parameter1: $Parameter1"
Write-Host "Parameter2: $Parameter2"
Write-Host "Parameter3: $Parameter3"

# Rest of your script logic goes here