function Test-PowerShellVersion {
    <#
    .SYNOPSIS
        Validates that the script is running in PowerShell Version 7 or higher.
    
    .DESCRIPTION
        Checks the current PowerShell Version using the $PSVersionTable.PSVersion.Major.
        If the script doesn't run in PowerShell Version 7 or higher, displays an error message and asks user to install PowerShell Version 7.
        If "Y" PowerShell Version 7.5.4.0 gets installed, "N" exit the script.
    
    .EXAMPLE
        Test-PowerShellVersion
        
        Checks if running in PowerShell Version 7 or higher.
        If not running in PowerShell Version 7 or higher, user can install it with "Y".
        If "Y" PowerShell Version 7.5.4.0. Exits if "N".
    
    .OUTPUTS
        None. The function writes to the host and may exit the script.
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0
        Requires: PowerShell 7.0+
    #>

    [CmdletBinding()]
    param()

    # variable for the PowerShell-Major-Version of the user.
    $UserPSVersion = $PSVersionTable.PSVersion.Major

    # check if the version is 7 or higher.
    Write-Host "`nChecking current PowerShell Version..." -ForegroundColor Yellow
    if ($UserPSVersion -ge 7) {
	    Write-Host "PowerShell Version 7 or higher is active." -ForegroundColor Green
        return
    }
    else {
	    Write-Host "PowerShell Version 7 or higher is required." -ForegroundColor Red
	    Write-Host "Current PowerShell Version: $UserPSVersion" -ForegroundColor Red
	
        # loop: installing PowerShell-Version 7.5.4: yes or no with error handling.
	    do {
		    $InstallPSVersion = Read-Host "`nInstall PowerShell Version 7? (Y/n)"
		    $InstallPSVersionFormatted = $InstallPSVersion.Trim().ToUpper()
		
		    if ($InstallPSVersionFormatted -eq "Y") {
                Write-Host "`nInstalling PowerShell Version 7..." -ForegroundColor Yellow
			    try {
                    winget install --id Microsoft.PowerShell --version "7.5.4.0" --source winget --silent
                    Write-Host "`nSuccessfully installed PowerShell Version 7." -ForegroundColor Green
                    throw "Start a new Terminal and continue."
                }
                catch {
                    throw "Update to PowerShell Version 7 failed: $($_.Exception.Message)."
                }
		    }
            elseif ($InstallPSVersionFormatted -eq "N") {
                throw "Tool needs the PowerShell Version 7 to run."
            }
            else {
                Write-Host "`nWrong input. 'Y' or 'n' is required." -ForegroundColor Red
                # Loop continues to ask again for installation.
	        }
        }
	    while ($InstallPSVersionFormatted -ne "Y" -and $InstallPSVersionFormatted -ne "N")
    }
}