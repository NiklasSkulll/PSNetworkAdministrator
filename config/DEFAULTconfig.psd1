# ------------------------------
# Configuration file for the "PSNetworkAdministrator"-Tool
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

    Database = @{
        DBRoot = (Join-Path $PSScriptRoot "Data")
        DBFolder = (Join-Path $PSScriptRoot "Data\db")
        DepsFolder = (Join-Path $PSScriptRoot "Data\deps")
        DBName = 'PSNetworkAdministrator.sqlite'
    }

    Tags = @{
        HostRole = 'Client,Server'
        Group = 'GroupA,GroupB'
        SystemEnvironment = 'DEV,TEST,PRD'
    }

    AddIns = @{
        AddInCount = 1
        AddInNames = 'RDP'
        AddInPaths = 'mstsc.exe'
        AddInArguments = '/v:{Computer}.{Domain}'
    }

    UI = @{
        Theme = 'Light'
        WindowWidth = 1200
        WindowHeight = 800
    }
}