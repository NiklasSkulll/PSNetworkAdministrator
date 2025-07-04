# PSNetworkAdministrator Module Manifest
@{
    RootModule           = 'PSNetworkAdministrator.psm1'
    ModuleVersion        = '0.1.0'
    GUID                 = 'f2e2d59d-1e57-4cb5-ae1c-f982cfa77fdf'
    Author               = 'PSNetworkAdministrator Team'
    CompanyName          = 'PSNetworkAdministrator'
    Copyright            = '(c) 2025 PSNetworkAdministrator. All rights reserved.'
    Description          = 'A PowerShell module providing a text-based menu to administer Windows networks without using GUI tools.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # Functions to export
    FunctionsToExport    = '*'
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    
    # Required modules
    RequiredModules      = @()
    
    # Private data
    PrivateData          = @{
        PSData = @{
            Tags       = @('Network', 'Administration', 'ActiveDirectory')
            LicenseUri = 'https://github.com/NiklasSkulll/PSNetworkAdministrator/blob/main/LICENSE'
            ProjectUri = 'https://github.com/NiklasSkulll/PSNetworkAdministrator'
        }
    }
}
