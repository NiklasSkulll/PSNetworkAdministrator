function Initialize-Configuration {
    <#
    .SYNOPSIS
        Loads and parses the application configuration file.

    .DESCRIPTION
        The Initialize-Configuration function loads the PSNetworkAdministrator configuration from a PowerShell data file (.psd1).
        It validates the configuration file exists, imports it and returns a structured PSCustomObject with all configuration settings
        including application metadata, logging settings, network parameters, and UI preferences.

    .PARAMETER ConfigPath
        The path to the configuration file. Defaults to the config.psd1 file in the config directory.
        If not specified, automatically resolves to '..\..\..\config\config.psd1' relative to the script location.
    
    .EXAMPLE
        Initialize-Configuration

        Loads the default configuration file and returns a structured configuration object.

    .EXAMPLE
        Initialize-Configuration -ConfigPath "C:\CustomPath\config.psd1"
    
        Loads a custom configuration file from the specified path.
    
    .INPUTS
        None. This function does not accept pipeline input.
    
    .OUTPUTS
        PSCustomObject
        Returns a custom object containing:
        - AppName: Application name
        - Version: Application version
        - Logging: Logging configuration (Enabled, LoggingLevel, LoggingPath, MaxLoggingSizeMB)
        - Network: Network settings (DefaultTimeout, MaxRetries)
        - UI: User interface settings (Theme, WindowWidth, WindowHeight)

    .NOTES
        Author: Niklas Schneider
        Version: 1.0.0
        Requires: PowerShell 7.0+
    
        This function is intended for internal use only (Private function).
        It throws an exception if the configuration file is missing or cannot be loaded.
    #>

    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Join-Path $PSScriptRoot "..\..\..\config\config.psd1")
    )

    # === check if config file isn't available ===
    if (-not (Test-Path $ConfigPath)){
        throw "Missing config file at: $ConfigPath"
    }

    # === load config file data ===
    try {
        $ConfigData = Import-PowerShellDataFile -Path $ConfigPath

        return [PSCustomObject]@{
            AppName = $ConfigData.AppName
            Version = $ConfigData.Version
            Logging = [PSCustomObject]@{
                Enabled = $ConfigData.logging.Enabled
                LoggingLevel = $ConfigData.logging.LoggingLevel
                LoggingPath = $ConfigData.logging.LoggingPath
                MaxLoggingSizeMB = $ConfigData.logging.MaxLoggingSizeMB
            }
            Network = [PSCustomObject]@{
                DefaultTimeout = $ConfigData.Network.DefaultTimeout
                MaxRetries = $ConfigData.Network.MaxRetries
            }
            UI = [PSCustomObject]@{
                Theme = $ConfigData.UI.Theme
                WindowWidth = $ConfigData.UI.WindowWidth
                WindowHeight = $ConfigData.UI.WindowHeight
            }
        }
    }
    catch {
        throw "Failed to load the config file from '$ConfigPath': $($_.Exception.Message)"
    }
}