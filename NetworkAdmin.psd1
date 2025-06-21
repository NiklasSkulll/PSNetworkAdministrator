#
# Module manifest for NetworkAdmin module
#
@{
    # Script module or binary module file associated with this manifest
    RootModule = 'NetworkAdmin.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-1234-567890abcdef'
    
    # Author of this module
    Author = 'System Administrator'
    
    # Company or vendor of this module
    CompanyName = 'Company'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Company. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Comprehensive network administration module for company networks'
      # Minimum version of PowerShell required
    PowerShellVersion = '5.1'
    
    # Functions to export from this module (aligned with NetworkAdmin.psm1)
    FunctionsToExport = @(
        'Start-NetworkAdminTool',
        'Get-NetworkAdminConfig', 
        'Set-NetworkAdminConfig',
        'Test-NetworkAdminConnectivity',
        'Export-NetworkAdminResults'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @('netadmin')
    
    # Modules that must be imported before this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @('Network', 'Administration', 'ActiveDirectory', 'DNS', 'DHCP', 'Security', 'Audit')
            ProjectUri = ''
            LicenseUri = ''
            ReleaseNotes = @'
Version 2.0 (June 2025)
- Complete modular architecture migration
- Enhanced error handling and retry mechanisms  
- Performance optimizations with caching
- Advanced configuration management
- Enterprise-grade logging and auditing
- Domain controller failover support
'@
            ExternalModuleDependencies = @('ActiveDirectory')
        }
    }
}
