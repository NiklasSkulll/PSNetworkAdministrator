# Get-MenuOption.ps1
# Helper function to display and handle menu options

<#
.SYNOPSIS
    Manages the menu options for PSNetworkAdministrator
.DESCRIPTION
    Creates a collection of menu options, displays them, and handles user selection.
    Returns an object with properties indicating whether the selection was valid,
    whether the user chose to quit, and the selected option details.
.OUTPUTS
    [PSCustomObject] with the following properties:
    - IsQuit: [bool] True if the user selected to quit
    - Option: [PSCustomObject] The selected menu option (or $null if invalid/quit)
    - IsValid: [bool] True if the selection was valid
.EXAMPLE
    $menuChoice = Get-MenuOption
    Gets the user's menu selection
.NOTES
    For internal module use only
#>
function Get-MenuOption {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()
    
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
    $menuOptions = $menuDefinitions | ForEach-Object {
        [PSCustomObject]$_
    }
    #endregion Menu Definition
    
    #region Display Menu
    # Display menu options
    Write-Verbose "Displaying menu options"
    foreach ($option in $menuOptions) {
        Write-Host ("  {0}.  {1}" -f $option.Number.PadRight(2), $option.Name) -ForegroundColor White
    }
    Write-Host "  Q.   Quit" -ForegroundColor White
    #endregion Display Menu
    
    #region Process Selection
    # Prompt for user selection
    Write-Host "`n  Select an option (1-10 or Q to quit): " -ForegroundColor Yellow -NoNewline
    $userChoice = Read-Host
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
        Write-Host "`n  Invalid option. Please select a number between 1 and 10 or Q to quit." -ForegroundColor Red
        return [PSCustomObject]@{
            IsQuit = $false
            Option = $null
            IsValid = $false
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
