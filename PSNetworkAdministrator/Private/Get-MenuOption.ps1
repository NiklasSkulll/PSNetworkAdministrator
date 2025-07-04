# Get-MenuOption.ps1
# Helper function to display and handle menu options

<#
.SYNOPSIS
    Manages the menu options for PSNetworkAdministrator
.DESCRIPTION
    Creates a collection of menu options, displays them, and handles user selection
.PARAMETER None
    This function doesn't accept parameters
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
    
    # Display menu options
    foreach ($option in $menuOptions) {
        Write-Host ("  {0}.  {1}" -f $option.Number.PadRight(2), $option.Name) -ForegroundColor White
    }
    Write-Host "  Q. Quit" -ForegroundColor White
    
    # Prompt for user selection
    Write-Host "`n  Select an option (1-10 or Q to quit): " -ForegroundColor Yellow -NoNewline
    $userChoice = Read-Host
    
    # Handle the quit option
    if ($userChoice -eq "Q" -or $userChoice -eq "q") {
        return [PSCustomObject]@{
            IsQuit = $true
            Option = $null
        }
    }
    
    # Validate input is a number between 1-10
    if (-not [int]::TryParse($userChoice, [ref]$null) -or 
        [int]$userChoice -lt 1 -or [int]$userChoice -gt 10) {
        Write-Host "`n  Invalid option. Please select a number between 1 and 10 or Q to quit." -ForegroundColor Red
        return [PSCustomObject]@{
            IsQuit = $false
            Option = $null
            IsValid = $false
        }
    }
    
    # Find the selected option
    $selectedOption = $menuOptions | Where-Object { $_.Number -eq $userChoice }
    
    # Return the selection result
    return [PSCustomObject]@{
        IsQuit = $false
        Option = $selectedOption
        IsValid = $true
    }
}
