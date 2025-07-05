# Get-MenuOption.ps1
# Helper function to display and handle menu options

<#
.SYNOPSIS
    Manages the menu options for PSNetworkAdministrator
.DESCRIPTION
    Creates a collection of menu options, displays them, and handles user selection.
    Returns an object with properties indicating whether the selection was valid,
    whether the user chose to quit, and the selected option details.
.PARAMETER SkipMenuDisplay
    If specified, suppresses the display of menu options and prompts.
    Useful for automated testing scenarios.
.PARAMETER TestInput
    Specifies a predefined input value to use instead of prompting the user.
    Valid values are 1-10, Q, or q.
    This is particularly useful for automated testing.
.OUTPUTS
    [PSCustomObject] with the following properties:
    - IsQuit: [bool] True if the user selected to quit
    - Option: [PSCustomObject] The selected menu option (or $null if invalid/quit)
    - IsValid: [bool] True if the selection was valid
.EXAMPLE
    $menuChoice = Get-MenuOption
    Gets the user's menu selection with visual menu display
.EXAMPLE
    $menuChoice = Get-MenuOption -SkipMenuDisplay
    Gets the user's menu selection without displaying the menu (for testing)
.EXAMPLE
    $menuChoice = Get-MenuOption -TestInput "1"
    Gets the menu selection using the provided test input value
.NOTES
    For internal module use only
#>
function Get-MenuOption {
    [CmdletBinding()]
    [OutputType('PSCustomObject')]
    param(
        [Parameter()]
        [switch]$SkipMenuDisplay,
        
        [Parameter()]
        [ValidateSet('1','2','3','4','5','6','7','8','9','10','Q','q')]
        [string]$TestInput
    )
    
    #region Menu Definition
    # Define menu structure - this makes it easier to add/modify options
    $menuDefinitions = @(
        @{ Number = "1"; Name = "User Management"; Command = "Invoke-UserManagement" },
        @{ Number = "2"; Name = "Computer Management"; Command = "Invoke-ComputerManagement" },
        @{ Number = "3"; Name = "Group Management"; Command = "Invoke-GroupManagement" },
        @{ Number = "4"; Name = "Network Diagnostics"; Command = "Invoke-NetworkDiagnostics" },
        @{ Number = "5"; Name = "DNS Management"; Command = "Invoke-DNSManagement" },
        @{ Number = "6"; Name = "DHCP Information"; Command = "Get-DHCPInformation" },
        @{ Number = "7"; Name = "Domain Controller Information"; Command = "Get-DCInformation" },
        @{ Number = "8"; Name = "Security Auditing"; Command = "Invoke-SecurityAudit" },
        @{ Number = "9"; Name = "System Health Check"; Command = "Invoke-SystemHealthCheck" },
        @{ Number = "10"; Name = "Switch Domain"; Command = "Switch-Domain" }
    )

    # Convert array of hashtables to array of PSObjects for easier access
    $script:menuOptions = $menuDefinitions | ForEach-Object {
        [PSCustomObject]$_
    }
    #endregion Menu Definition
    
    #region Display Menu
    # Display menu options
    Write-Verbose "Displaying menu options"
    # Check for global test mode as well as parameter
    $isTestMode = $SkipMenuDisplay -or ($Global:PSNetworkAdminTestMode -eq $true)
    
    if (-not $isTestMode) {
        foreach ($option in $script:menuOptions) {
            Write-Host ("  {0}.  {1}" -f $option.Number.PadRight(2), $option.Name) -ForegroundColor White
        }
        Write-Host "  Q.   Quit" -ForegroundColor White
    }
    else {
        Write-Verbose "Test mode active: Skipping menu display"
    }
    #endregion Display Menu
    
    #region Process Selection
    # Check for global test mode as well as parameter
    $isTestMode = $SkipMenuDisplay -or ($Global:PSNetworkAdminTestMode -eq $true)
    
    # Prompt for user selection
    if ($TestInput) {
        # Use provided test input (for automated testing)
        $userChoice = $TestInput
        Write-Verbose "Using explicit test input: $userChoice"
    }
    elseif (-not $isTestMode) {
        # Only show prompt and read input if not in test mode
        Write-Host "`n  Select an option (1-10 or Q to quit): " -ForegroundColor Yellow -NoNewline
        $userChoice = Read-Host
    }
    else {
        # In test mode, assume "Q" for testing if no TestInput provided
        $userChoice = "Q"
        Write-Verbose "Test mode active: Using default test input 'Q'"
    }
    Write-Verbose "User entered: $userChoice"
    
    # Handle the quit option
    if ($userChoice -eq "Q" -or $userChoice -eq "q") {
        Write-Verbose "User selected to quit"
        return [PSCustomObject]@{
            IsQuit = $true
            Option = $null
            IsValid = $true
        }
    }
    
    # Validate input is a number between 1-10
    if (-not [int]::TryParse($userChoice, [ref]$null) -or 
        [int]$userChoice -lt 1 -or [int]$userChoice -gt 10) {
        Write-Verbose "Invalid selection: $userChoice is not between 1 and 10"
        # Check for global test mode as well as parameter
        $isTestMode = $SkipMenuDisplay -or ($Global:PSNetworkAdminTestMode -eq $true)
        
        if (-not $isTestMode) {
            Write-Host "`n  Invalid option. Please select a number between 1 and 10 or Q to quit." -ForegroundColor Red
        }
        else {
            Write-Verbose "Test mode active: Suppressing invalid option message"
        }
        # Always return an invalid result for non-numeric or out-of-range input
        return [PSCustomObject]@{
            IsQuit = $false          # It's not a quit command
            Option = $null           # No valid menu option selected
            IsValid = $false         # The selection is not valid
        }
    }
    
    # Find the selected option
    $selectedOption = $menuOptions | Where-Object { $_.Number -eq $userChoice }
    Write-Verbose "Selected option: $($selectedOption.Name)"
    
    # Return the selection result
    return [PSCustomObject]@{
        IsQuit = $false
        Option = $selectedOption
        IsValid = $true
    }
    #endregion Process Selection
}
