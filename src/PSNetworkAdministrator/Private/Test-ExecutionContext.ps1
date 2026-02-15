function Test-ExecutionContext {
    <#
    .SYNOPSIS
        Validates that the script is running with Administrator privileges.
    
    .DESCRIPTION
        The Test-ExecutionContext function checks whether the current PowerShell session is running with Administrator privileges.
        It uses the current user's security principal and verifies membership in the Administrator role.
        This function is critical for operations that require elevated permissions, such as Active Directory management
        and system configuration changes.
    
    .EXAMPLE
        Test-ExecutionContext
    
        Checks if running as Administrator and returns a status object if successful.
    
    .INPUTS
        None. This function does not accept pipeline input.
    
    .OUTPUTS
        PSCustomObject
        Returns an object with:
        - Status: "Passed" if running as Administrator
        - Message: Confirmation message about Administrator status
    
        Throws an exception if not running as Administrator.
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0.0
        Requires: PowerShell 7.0+, Windows Operating System

        This function is intended for internal use only (Private function).
        The function will throw a terminating error if Administrator privileges are not detected.
        It should be called early in script execution to ensure proper permissions.
    #>

    [CmdletBinding()]
    param()

    # get the current user status, "Administrator" role
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $IsAdmin = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # check if the PowerShell runs as "Administrator"
    if ($IsAdmin) {
        return [PSCustomObject]@{
            Status = "Passed"
            Message = "Running as Administrator."
        }
    }
    else {
        throw "Running as non-Administrator. Tool needs to run as Administrator."
    }
}