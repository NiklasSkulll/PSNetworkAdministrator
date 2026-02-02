function Test-ExecutionContext {
    <#
    .SYNOPSIS
        Validates that the script is running as "Administrator".
    
    .DESCRIPTION
        Checks the current user status using the current user Principal and IsInRole.
        If the script doesn't run as "Administrator", displays an error message and exits the script with code 1.
    
    .EXAMPLE
        Test-ExecutionContext
        
        Checks if running as "Administrator". Exits if not running as administrator.
    
    .OUTPUTS
        None. The function writes to the host and may exit the script.
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0
        Requires: PowerShell 7.0+
    #>

    [CmdletBinding()]
    param()

    # get the current user status, "Administrator" role
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $IsAdmin = $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # check if the PowerShell runs as "Administrator"
    Write-Host "`nChecking current Execution Context..." -ForegroundColor Cyan
    if ($IsAdmin) {
        Write-Host "Running as Administrator." -ForegroundColor Green
        return
    }
    else {
        throw "Running as non-Administrator. Tool needs to run as Administrator."
    }
}