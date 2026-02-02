function Test-DotnetVersion{
    <#
    .SYNOPSIS
        Validates that .Net SDK Version 8.* is installed.
    
    .DESCRIPTION
        Checks the dotnet installation and what dotnet Version is active.
        If the dotnet version isn't 8, displays an error message and exits the script with code 1.
    
    .EXAMPLE
        Test-DotnetVersion
        
        Checks if .Net is installed and if the Version is 8. Exits if not.
    
    .OUTPUTS
        None. The function writes to the host and may exit the script.
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0
        Requires: PowerShell 7.0+
    #>

    [CmdletBinding()]
    param()

    $CheckDotnetInstallation = Get-Command dotnet -ErrorAction SilentlyContinue

    if ($CheckDotnetInstallation) {
        Write-Host ".Net installed." -ForegroundColor Green
        Write-Host "`nCheck current .Net Version..." -ForegroundColor Yellow

        $CheckDotnetVersion = dotnet --version
        $CheckDotnetMajorVersion = $CheckDotnetVersion.Split('.')[0]

        if ($CheckDotnetMajorVersion -eq 8) {
            Write-Host ".Net Version $CheckDotnetMajorVersion is installed." -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "You need .Net Version 8 for this Tool." -ForegroundColor Red
            Write-Host "You currently have: $CheckDotnetMajorVersion" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host ".Net isn't installed." -ForegroundColor Red
        Write-Host "You need to install .Net for this Tool." -ForegroundColor Red
        exit 1
    }
}