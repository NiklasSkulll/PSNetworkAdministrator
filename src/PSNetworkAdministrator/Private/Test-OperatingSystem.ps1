function Test-OperatingSystem {
    <#
    .SYNOPSIS
        Validates that the script is running on a Windows operating system.
    
    .DESCRIPTION
        Checks the current operating system using PowerShell automatic variables ($IsWindows, $IsLinux, $IsMacOS).
        If the OS is not Windows, displays an error message and exits the script with code 1.
    
    .EXAMPLE
        Test-OperatingSystem
        
        Checks if running on Windows. Exits if not on Windows.
    
    .OUTPUTS
        None. The function writes to the host and may exit the script.
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0
        Requires: PowerShell 7.0+
    #>

    [CmdletBinding()]
    param()

    # check if the user is on Windows
    if ($IsWindows) {
        Write-Host "Running on Windows." -ForegroundColor Green
        return $true
    }
    elseif ($IsLinux) {
        Write-Host "Your are currently running on Linux." -ForegroundColor Red
        Write-Host "Windows is required for this tool." -ForegroundColor Red
        exit 1
    }
    elseif ($IsMacOS) {
        Write-Host "Your are currently running on MacOs." -ForegroundColor Red
        Write-Host "Windows is required for this tool." -ForegroundColor Red
        exit 1
    }
    else {
        Write-Host "Your are currently running not on Windows." -ForegroundColor Red
        Write-Host "Windows is required for this tool." -ForegroundColor Red
        exit 1
    }
}