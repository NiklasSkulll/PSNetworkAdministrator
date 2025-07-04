# Invoke-PSNetworkAdmin.ps1
# Main entry point script for PSNetworkAdministrator

<#
.SYNOPSIS
    Provides a text-based menu interface for Windows network administration.

.DESCRIPTION
    This is the main entry point for the PSNetworkAdministrator module.
    It presents a unified menu-driven interface that allows administrators to
    perform common network administration tasks without using GUI tools.
    
    The menu includes options for user management, computer management,
    group management, network diagnostics, DNS management, DHCP information,
    domain controller info, security auditing, system health checks, and domain switching.

.PARAMETER Domain
    Specifies the Active Directory domain to connect to.
    If not specified, the current domain will be used.

.PARAMETER Credential
    PSCredential object for domain access.
    If not specified, the current user's credentials will be used.

.PARAMETER LogPath
    Path where log files should be stored.
    Defaults to the Logs directory in the module path.

.EXAMPLE
    Invoke-PSNetworkAdmin
    # Starts the menu interface using the current domain and credentials

.EXAMPLE
    Invoke-PSNetworkAdmin -Domain "contoso.com" -Credential $adminCred
    # Connects to the specified domain with the provided credentials

.NOTES
    Requires the Active Directory module and elevated privileges for most operations.
    Tested on PowerShell 5.1 and 7.2.
    For full functionality, run on a domain-joined machine with RSAT tools installed.

.LINK
    https://github.com/NiklasSkulll/PSNetworkAdministrator
#>
function Invoke-PSNetworkAdmin {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Domain,
        
        [Parameter(Position = 1)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Position = 2)]
        [string]$LogPath
    )

    # Clear the terminal for a clean interface
    Clear-Host
    
    # Display ASCII header
    Write-Host @'
     ____  ____  _   _      _                      _    
    |  _ \/ ___|| \ | | ___| |___      _____  _ __| | __
    | |_) \___ \|  \| |/ _ \ __\ \ /\ / / _ \| '__| |/ /
    |  __/ ___) | |\  |  __/ |_ \ V  V / (_) | |  |   < 
    |_|   |____/|_| \_|\___|\__| \_/\_/ \___/|_|  |_|\_\
        _       _           _       _     _             _             
       / \   __| |_ __ ___ (_)_ __ (_)___| |_ _ __ __ _| |_  ___  _ __ 
      / _ \ / _` | '_ ` _ \| | '_ \| / __| __| '__/ _` | __|/ _ \| '__|
     / ___ \ (_| | | | | | | | | | | \__ \ |_| | | (_| | |_| (_) | |   
    /_/   \_\__,_|_| |_| |_|_|_| |_|_|___/\__|_|  \__,_|\__|\___/|_|
'@ -ForegroundColor Cyan

    # Display welcome message and version information
    $moduleVersion = (Get-Module PSNetworkAdministrator).Version.ToString()
    if (-not $moduleVersion) { $moduleVersion = "0.1.0" } # Fallback if version not found
    
    Write-Host "`n  Welcome to PSNetwork Administrator v$moduleVersion!" -ForegroundColor Cyan
    Write-Host "  Your one-stop tool for Windows network administration tasks`n" -ForegroundColor Gray
    
    # Log the start of the application
    try {
        Write-Log -Message "PSNetworkAdministrator started" -Level Info -LogPath $LogPath
    }
    catch {
        # Continue even if logging fails
        Write-Host "  Warning: Unable to write to log file. Continuing without logging." -ForegroundColor DarkYellow
    }
    
    # Display current connection information
    if (-not $Domain) {
        $Domain = $env:USERDNSDOMAIN
        if (-not $Domain) {
            $Domain = "Not connected to a domain"
        }
    }
    
    Write-Host "  Current domain: $Domain" -ForegroundColor White
    Write-Host "  Current user: $($env:USERNAME)" -ForegroundColor White
    Write-Host "`n  Please select an option from the menu below:`n" -ForegroundColor Green
    
    # Main menu options
    $menuOptions = @(
        "1.  User Management"
        "2.  Computer Management"
        "3.  Group Management"
        "4.  Network Diagnostics"
        "5.  DNS Management"
        "6.  DHCP Information"
        "7.  Domain Controller Information"
        "8.  Security Auditing"
        "9.  System Health Check"
        "10. Switch Domain"
        " Q. Quit"
    )
    
    # Display menu options
    foreach ($option in $menuOptions) {
        Write-Host "  $option" -ForegroundColor White
    }
    
    # Prompt for user selection
    Write-Host "`n  Select an option (1-10 or Q to quit): " -ForegroundColor Yellow -NoNewline
    $userChoice = Read-Host
    
    # Basic input processing (placeholder for more extensive menu handling)
    if ($userChoice -eq "Q" -or $userChoice -eq "q") {
        Write-Host "`n  Exiting PSNetworkAdministrator. Goodbye!`n" -ForegroundColor Cyan
    }
    else {
        Write-Host "`n  You selected option: $userChoice" -ForegroundColor Red
        Write-Host "  This functionality will be implemented in a future update.`n" -ForegroundColor Gray
    }
    
    # Return a status object for tracking but modify how it's displayed
    # First, create the object
    $statusObject = [PSCustomObject]@{
        ModuleName = "PSNetworkAdministrator"
        Version = $moduleVersion
        Status = "Initialized"
        Domain = $Domain
        Timestamp = Get-Date
    }
    
    # If running in interactive mode (not being captured in a variable), 
    # manually format the output instead of returning the object
    if ($MyInvocation.CommandOrigin -eq 'Runspace') {
        Write-Host "`n "
        Write-Host "  PSNetworkAdministrator Status:" -ForegroundColor Cyan
        Write-Host "  ModuleName  : $($statusObject.ModuleName)" -ForegroundColor gray
        Write-Host "  Version     : $($statusObject.Version)" -ForegroundColor gray
        Write-Host "  Status      : $($statusObject.Status)" -ForegroundColor gray
        Write-Host "  Domain      : $($statusObject.Domain)" -ForegroundColor gray
        Write-Host "  Timestamp   : $($statusObject.Timestamp)" -ForegroundColor gray
        Write-Host # Add another blank line
        return $null # Return nothing to prevent default format from appearing
    }
    else {
        # When called programmatically, return the object for further processing
        return $statusObject
    }
}

# Export function
Export-ModuleMember -Function Invoke-PSNetworkAdmin
