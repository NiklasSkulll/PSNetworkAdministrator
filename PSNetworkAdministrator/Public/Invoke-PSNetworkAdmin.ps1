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
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Default")]
    param(
        [Parameter(Position = 0, ParameterSetName = "Default")]
        [Parameter(Position = 0, ParameterSetName = "WithCredentials")]
        [string]$Domain,
        
        [Parameter(DontShow)]
        [switch]$TestMode,
        
        [Parameter(Position = 1, Mandatory = $false, ParameterSetName = "WithCredentials")]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Position = 2, ParameterSetName = "Default")]
        [Parameter(Position = 2, ParameterSetName = "WithCredentials")]
        [string]$LogPath
    )

    #region Initialization
    Write-Verbose "Starting PSNetworkAdministrator..."
    
    # Set default log path if not specified
    if (-not $LogPath) {
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $LogPath = Join-Path -Path $moduleRoot -ChildPath "Logs"
        $LogPath = Join-Path -Path $LogPath -ChildPath "PSNetworkAdmin_$((Get-Date).ToString('yyyyMMdd')).log"
        Write-Verbose "Using default log path: $LogPath"
    }
    
    # Clear the terminal for a clean interface (but skip in test mode)
    if (-not $WhatIfPreference -and -not $TestMode -and -not $Global:PSNetworkAdminTestMode) {
        Clear-Host
    }
    else {
        Write-Verbose "Skipping Clear-Host in test/WhatIf mode"
    }
    #endregion Initialization
    
    #region Display Header
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
    if (-not $moduleVersion) { 
        $moduleVersion = "0.1.0" # Fallback if version not found
        Write-Verbose "Could not determine module version. Using fallback: $moduleVersion"
    } else {
        Write-Verbose "Module version: $moduleVersion"
    }
    
    # Display welcome message
    Write-Host "`n  Welcome to PSNetwork Administrator v$moduleVersion!" -ForegroundColor Cyan
    Write-Host "  Your one-stop tool for Windows network administration tasks`n" -ForegroundColor Gray
    #endregion Display Header
    
    #region Logging and Connection Info
    # Log the start of the application
    try {
        if ($PSCmdlet.ShouldProcess("Log file", "Write startup entry")) {
            Write-Log -Message "PSNetworkAdministrator started" -Level Info -LogPath $LogPath
            Write-Verbose "Startup log entry created successfully"
        }
    }
    catch {
        # Continue even if logging fails
        Write-Host "  Warning: Unable to write to log file. Continuing without logging." -ForegroundColor DarkYellow
        Write-Verbose "Failed to create log entry: $_"
    }
    
    # Handle domain information
    Write-Verbose "Processing domain information"
    if ([string]::IsNullOrEmpty($Domain)) {
        try {
            # Try to get the domain name safely
            $Domain = $env:USERDNSDOMAIN
            Write-Verbose "Domain from environment: $Domain"
        }
        catch {
            Write-Verbose "Failed to get domain from environment: $_"
        }
        
        # If still empty, set default message
        if ([string]::IsNullOrEmpty($Domain)) {
            $Domain = "Not connected to a domain"
            Write-Verbose "No domain detected, using default message"
        }
    } else {
        Write-Verbose "Using provided domain: $Domain"
    }
    
    # Display connection information
    Write-Host "  Current domain: $Domain" -ForegroundColor White
    Write-Host "  Current user: $($env:USERNAME)" -ForegroundColor White
    Write-Host "`n  Please select an option from the menu below:`n" -ForegroundColor Green
    #endregion Logging and Connection Info
    
    #region Menu Processing
    # Get user menu selection using the helper function
    Write-Verbose "Displaying menu options"
    if ($PSCmdlet.ShouldProcess("Menu options", "Display and get selection")) {
        # Check if we're in test mode
        if ($TestMode -or $Global:PSNetworkAdminTestMode) {
            $menuSelection = Get-MenuOption -SkipMenuDisplay -TestInput "1"
            Write-Verbose "Test mode: Using predefined menu selection"
        } else {
            $menuSelection = Get-MenuOption
        }
        Write-Verbose "User selected: $(if($menuSelection.IsQuit){'Quit'}elseif($menuSelection.IsValid){$menuSelection.Option.Name}else{'Invalid option'})"
    } else {
        # Create a placeholder selection for WhatIf mode
        $menuSelection = [PSCustomObject]@{
            IsQuit = $false
            IsValid = $true
            Option = [PSCustomObject]@{
                Number = "WhatIf"
                Name = "WhatIf Mode (No Selection)"
            }
        }
    }
    
    # Process the menu selection
    if ($menuSelection.IsQuit) {
        Write-Host "`n  Exiting PSNetworkAdministrator. Goodbye!`n" -ForegroundColor Cyan
        Write-Verbose "User chose to quit"
        return "Quit"  # Exit immediately with the quit value
    }
    elseif (-not $menuSelection.IsValid) {
        # Handle invalid selection (already displayed message in Get-MenuOption)
        Write-Verbose "User made an invalid selection"
        # Fall through to show status and prompt to continue
    }
    else {
        # Valid selection, show what was selected
        Write-Host "`n  You selected: $($menuSelection.Option.Name)" -ForegroundColor Cyan
        
        if ($PSCmdlet.ShouldProcess("$($menuSelection.Option.Name)", "Execute function")) {
            Write-Host "  This functionality will be implemented in a future update.`n" -ForegroundColor Gray
            Write-Verbose "Functionality not yet implemented for: $($menuSelection.Option.Name)"
            
            # In the future, you would call the appropriate command here:
            # & $menuSelection.Option.Command -Domain $Domain -Credential $Credential
        }
    }
    #endregion Menu Processing
    
    #region Status Display and Exit
    # Create and display the status object
    Write-Verbose "Creating status object"
    $userChoiceValue = if ($menuSelection.IsQuit) {
        "Q"
    } elseif ($menuSelection.Option -and $menuSelection.Option.Number) {
        $menuSelection.Option.Number
    } else {
        "Invalid"
    }
    
    $statusObject = New-StatusObject -Version $moduleVersion -Domain $Domain -UserChoice $userChoiceValue -Status "Completed"
    Show-StatusInformation -StatusObject $statusObject
    
    # For interactive console use, prompt to press Q to quit
    # Skip in test mode, WhatIf mode, or when global test flag is set
    if (-not $WhatIfPreference -and -not $TestMode -and -not $Global:PSNetworkAdminTestMode) {
        Write-Host "`n  Press Q to quit..." -ForegroundColor Cyan
        Write-Verbose "Waiting for user to press Q to exit"
        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        
        # Check if user pressed Q to quit
        if ($key.Character -eq 'Q' -or $key.Character -eq 'q') {
            Write-Host "`n  Exiting PSNetworkAdministrator. Goodbye!`n" -ForegroundColor Cyan
            Write-Verbose "User pressed Q to exit"
            return "Quit"
        }
    }
    else {
        Write-Verbose "Skipping interactive 'press Q to quit' prompt in test/WhatIf mode"
        # In test mode, just return as if Q was pressed
        if ($TestMode -or $Global:PSNetworkAdminTestMode) {
            return "Quit"
        }
    }
    
    # Return the status object for programmatic use or null for interactive use
    Write-Verbose "Function complete, returning appropriate value"
    if ($MyInvocation.CommandOrigin -ne 'Runspace') {
        Write-Verbose "Returning status object for programmatic use"
        return $statusObject
    } else {
        Write-Verbose "Returning null for interactive use"
        return $null
    }
    #endregion Status Display and Exit
}

# Export function
Export-ModuleMember -Function Invoke-PSNetworkAdmin
