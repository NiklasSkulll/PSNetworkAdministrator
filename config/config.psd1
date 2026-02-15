# ------------------------------
# configuration file for the "PSNetworkAdministrator"-Tool
# ------------------------------

@{
    AppName = 'PSNetworkAdministrator'
    Version = '1.0.0'

    Logging = @{
        Enabled = $true
        LoggingLevel = 'Info'
        LoggingPath = (Join-Path $PSScriptRoot "..\..\..\logs\PSNetAdmin.log")
        MaxLoggingSizeMB = 10
    }

    Network = @{
        DefaultTimeout = 5000
        MaxRetries = 3
    }

    UI = @{
        Theme = 'Light'
        WindowWidth = 1200
        WindowHeight = 800
    }
}