function Initialize-Configuration {
    <#
    .SYNOPSIS
        Loads and parses the application configuration file.

    .DESCRIPTION
        The Initialize-Configuration function loads the PSNetworkAdministrator configuration from a PowerShell data file (.psd1).
        It validates the configuration file exists, imports it and returns a structured PSCustomObject with all configuration settings
        including application metadata, logging settings, network parameters, and UI preferences.
    
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
    param()

    # ===== Create config variables (user and default) =====
    $DefaultConfigPath = Join-Path $PSScriptRoot "..\..\..\config\DEFAULTconfig.psd1"
    $UserConfigPath = Join-Path $PSScriptRoot "..\..\..\config\config.psd1"

    # ===== Check if config file is available =====
    if (-not (Test-Path $UserConfigPath)) {
        if (Test-Path $DefaultConfigPath) {
            Copy-Item -Path $DefaultConfigPath -Destination $UserConfigPath
        }
        else {
            $RefValue = Get-RefValue -VariableName '$DefaultConfigPath' -Value $DefaultConfigPath
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'IOx0000001' -RefValue $RefValue
            throw $ErrorMessage
        }
    }
    elseif ([string]::IsNullOrWhiteSpace((Get-Content $UserConfigPath -Raw))) {
        if (Test-Path $DefaultConfigPath) {
            Copy-Item -Path $DefaultConfigPath -Destination $UserConfigPath -Force
        }
        else {
            $RefValue = Get-RefValue -VariableName '$DefaultConfigPath' -Value $DefaultConfigPath
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'IOx0000001' -RefValue $RefValue
            throw $ErrorMessage
        }
    }

    # ===== Load config file data =====
    try {
        $ConfigData = Import-PowerShellDataFile -Path $UserConfigPath

        return [pscustomobject]@{
            AppName = $ConfigData.AppName
            Version = $ConfigData.Version
            Logging = [pscustomobject]@{
                Enabled = $ConfigData.Logging.Enabled
                LoggingPath = $ConfigData.Logging.LoggingPath
                MaxLoggingSizeMB = $ConfigData.Logging.MaxLoggingSizeMB
            }
            Network = [pscustomobject]@{
                DefaultTimeout = $ConfigData.Network.DefaultTimeout
                MaxRetries = $ConfigData.Network.MaxRetries
            }
            Database = [pscustomobject]@{
                DBRoot = $ConfigData.Database.DBRoot
                DBFolder = $ConfigData.Database.DBFolder
                DepsFolder = $ConfigData.Database.DepsFolder
                DBName = $ConfigData.Database.DBName
            }
            Tags = [pscustomobject]@{
                HostRole = $ConfigData.Tags.HostRole
                Group = $ConfigData.Tags.Group
                SystemEnvironment = $ConfigData.Tags.SystemEnvironment
            }
            AddIns = [pscustomobject]@{
                AddInCount = $ConfigData.AddIns.AddInCount
                AddInNames = $ConfigData.AddIns.AddInNames
                AddInPaths = $ConfigData.AddIns.AddInPaths
                AddInArguments = $ConfigData.AddIns.AddInArguments
            }
            UI = [pscustomobject]@{
                Theme = $ConfigData.UI.Theme
                WindowWidth = $ConfigData.UI.WindowWidth
                WindowHeight = $ConfigData.UI.WindowHeight
            }
        }
    }
    catch {
        $RefValue = Get-RefValue -VariableName '$UserConfigPath' -Value $UserConfigPath
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'IOx0000002' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue
        throw $ErrorMessage
    }
}