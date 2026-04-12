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

    Tags = @{
        HostRole = 'Client,Server'
        Group = 'GroupA,GroupB'
        SystemEnvironment = 'DEV,TEST,PRD'
    }

    AddIns = @{
        AddInCount = '1'
        AddInNames = 'RDP'
        AddInPaths = 'mstsc.exe'
    }

    UI = @{
        Theme = 'Light'
        WindowWidth = 1200
        WindowHeight = 800
    }
}