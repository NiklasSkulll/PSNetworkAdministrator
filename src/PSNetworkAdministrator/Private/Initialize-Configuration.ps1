function Initialize-Configuration {
    <#
    .SYNOPSIS
        Loads application configuration
    #>

    [CmdletBinding()]
    param()

    # path definition of the config file
    $ConfigPath = "$PSScriptRoot\..\..\..\config\config.psd1"

    # check if config file is available, if not: load minimal default
    if (Test-Path $ConfigPath) {
        try {
            $ConfigData = Import-PowerShellDataFile -Path $ConfigPath

            Write-Host "Configuration loaded from: $ConfigPath" -ForegroundColor Green
            return $ConfigData
        }
        catch {
            throw "Failed to load config: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "Config file not found at: $ConfigPath. Using defaults." -ForegroundColor Red
        return @{
            AppName = 'PSNetworkAdministrator'
            Logging = @{
                Enabled = $true
                LoggingLevel = 'Info'
                LoggingPath = 'logs/app.log'
            }
        }
    }
}