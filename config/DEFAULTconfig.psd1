# ------------------------------
# configuration file for the "PSNetworkAdministrator"-Tool
# ------------------------------

@{
    AppName = 'PSNetworkAdministrator'
    Version = '1.0.0'

    Logging = @{
        Enabled = $true
        LoggingPath = (Join-Path $PSScriptRoot "..\..\..\logs\PSNetAdmin.log")
        MaxLoggingSizeMB = 10
    }

    Network = @{
        DefaultTimeout = 800
        MaxRetries = 3
    }

    AddIns = @{
        AddInCount = '1'
        AddInNames = 'RDP'
        AddInPaths = '...'
    }

    UI = @{
        Theme = 'Light'
        WindowWidth = 1200
        WindowHeight = 800
    }
}