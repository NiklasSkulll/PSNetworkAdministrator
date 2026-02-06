function Initialize-Configuration {
    <#
    .SYNOPSIS
        Loads application configuration
    #>

    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Join-Path $PSScriptRoot "..\..\..\config\config.psd1")
    )

    # check if config file isn't available and throw error
    if (-not (Test-Path $ConfigPath)){
        throw "Missing config file at: $ConfigPath"
    }

    # load config file data
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