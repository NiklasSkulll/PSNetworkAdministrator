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

    # Set default log path if not specified
    if (-not $LogPath) {
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $LogPath = Join-Path -Path $moduleRoot -ChildPath "Logs"
        $LogPath = Join-Path -Path $LogPath -ChildPath "PSNetworkAdmin_$((Get-Date).ToString('yyyyMMdd')).log"
    }
    
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

    # Get module version
    $moduleVersion = (Get-Module PSNetworkAdministrator).Version.ToString()
    if (-not $moduleVersion) { $moduleVersion = "0.1.0" } # Fallback if version not found
    
    # Display welcome message
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
    
    # Handle domain information
    if ([string]::IsNullOrEmpty($Domain)) {
        try {
            # Try to get the domain name safely
            $Domain = $env:USERDNSDOMAIN
        }
        catch {
            # Ignore any errors
        }
        
        # If still empty, set default message
        if ([string]::IsNullOrEmpty($Domain)) {
            $Domain = "Not connected to a domain"
        }
    }
    
    # Display connection information
    Write-Host "  Current domain: $Domain" -ForegroundColor White
    Write-Host "  Current user: $($env:USERNAME)" -ForegroundColor White
    Write-Host "`n  Please select an option from the menu below:`n" -ForegroundColor Green
    
    # Get user menu selection using the helper function
    $menuSelection = Get-MenuOption
    
    # Process the menu selection
    if ($menuSelection.IsQuit) {
        Write-Host "`n  Exiting PSNetworkAdministrator. Goodbye!`n" -ForegroundColor Cyan
        return "Quit"  # Exit immediately with the quit value
    }
    elseif (-not $menuSelection.IsValid) {
        # Handle invalid selection (already displayed message in Get-MenuOption)
        # Fall through to show status and prompt to continue
    }
    else {
        # Valid selection, show what was selected
        Write-Host "`n  You selected: $($menuSelection.Option.Name)" -ForegroundColor Cyan
        Write-Host "  This functionality will be implemented in a future update.`n" -ForegroundColor Gray
        
        # In the future, you would call the appropriate command here:
        # & $menuSelection.Option.Command -Domain $Domain -Credential $Credential
    }
    
    # Create and display the status object
    $userChoiceValue = if ($menuSelection.IsQuit) {
        "Q"
    } elseif ($menuSelection.Option -and $menuSelection.Option.Number) {
        $menuSelection.Option.Number
    } else {
        "Invalid"
    }
    
    $statusObject = New-StatusObject -Version $moduleVersion -Domain $Domain -UserChoice $userChoiceValue
    Show-StatusInformation -StatusObject $statusObject
    
    # For interactive console use, prompt to press Q to quit
    Write-Host "`n  Press Q to quit..." -ForegroundColor Cyan
    $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    
    # Check if user pressed Q to quit
    if ($key.Character -eq 'Q' -or $key.Character -eq 'q') {
        Write-Host "`n  Exiting PSNetworkAdministrator. Goodbye!`n" -ForegroundColor Cyan
        return "Quit"
    }
    
    # Return the status object for programmatic use or null for interactive use
    if ($MyInvocation.CommandOrigin -ne 'Runspace') {
        return $statusObject
    } else {
        return $null
    }
}

# Export function
Export-ModuleMember -Function Invoke-PSNetworkAdmin
