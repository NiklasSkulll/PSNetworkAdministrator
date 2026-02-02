function Test-WpfAvailability{
    <#
    .SYNOPSIS
        Validates that WPF assemblies can load. Ensures the Availability of WPF.
    
    .DESCRIPTION
        Checks that the WPF assemblies can load.
        If the WPF assemblies can load, displays an error message and exits the script with code 1.
    
    .EXAMPLE
        Test-WpfAvailability
        
        Checks if WPF assemblies can load.
    
    .OUTPUTS
        None. The function writes to the host and may exit the script.
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0
        Requires: PowerShell 7.0+
    #>

    [CmdletBinding()]
    param()

    # Check if WPF assemblies can load
    Write-Host "`nChecking WPF availability..." -ForegroundColor Cyan
    try {
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
        Write-Host "WPF is available." -ForegroundColor Green
        return
    }
    catch {
        throw "WPF isn't available. This tool requires Windows Desktop runtime with WPF support."
    }
}