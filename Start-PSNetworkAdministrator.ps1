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

# Start the application
Invoke-PSNetworkAdmin

# Keep the console open if launched directly
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "`nPress any key to exit..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
