<#
.SYNOPSIS
    Startup script for PSNetwork Administrator
.DESCRIPTION
    This script imports the PSNetworkAdministrator module and starts the main interface
.EXAMPLE
    .\Start-PSNetworkAdministrator.ps1
    Launches the PSNetwork Administrator tool
.NOTES
    Created by: PSNetworkAdministrator Team
    Date: July 4, 2025
#>

# Import the module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "PSNetworkAdministrator"
Import-Module -Name $modulePath -Force

# Start the application and capture the return value
$result = Invoke-PSNetworkAdmin

# Return the status object if it's not the special quit value
# This preserves the original functionality for scripts that might use this script
if ($result -ne 'Quit' -and $result -is [PSCustomObject]) {
    return $result
}
