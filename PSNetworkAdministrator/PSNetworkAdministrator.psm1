#requires -Version 5.1

# Check for ActiveDirectory module and warn if not available
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Warning "ActiveDirectory module is not available. Some functions may not work properly."
    Write-Warning "To install: Install-WindowsFeature -Name RSAT-AD-PowerShell (Windows Server) or install RSAT tools (Windows Client)"
}

# Import all module components
. $PSScriptRoot\Classes\NetworkAdminClasses.ps1
. $PSScriptRoot\Private\ConfigurationManager.ps1
. $PSScriptRoot\Private\NetworkOperations.ps1
. $PSScriptRoot\Private\ADOperations.ps1
. $PSScriptRoot\Private\CacheManager.ps1
. $PSScriptRoot\Private\UtilityFunctions.ps1
. $PSScriptRoot\Public\UserManagement.ps1
. $PSScriptRoot\Public\ComputerManagement.ps1
. $PSScriptRoot\Public\GroupManagement.ps1
. $PSScriptRoot\Public\NetworkDiagnostics.ps1
. $PSScriptRoot\Public\DNSManagement.ps1
. $PSScriptRoot\Public\DHCPInfo.ps1
. $PSScriptRoot\Public\DomainControllerInfo.ps1
. $PSScriptRoot\Public\SecurityAudit.ps1
. $PSScriptRoot\Public\MainInterface.ps1

# Module variables - Global scope for module functions
$script:ModuleConfig = @{}
$script:ModuleCache = @{}
$script:Domain = ""
$script:Credential = $null
$script:LogPath = ""
$script:NoLog = $false

# Initialize module variables from entry point if available
if ($Domain) { $script:Domain = $Domain }
if ($Credential) { $script:Credential = $Credential }
if ($LogPath) { $script:LogPath = $LogPath }
if ($NoLog) { $script:NoLog = $NoLog }

# Aliases for backwards compatibility
New-Alias -Name "netadmin" -Value "Start-NetworkAdminTool" -Description "Quick alias for network admin tool"

# Export only public functions
Export-ModuleMember -Function @(
    'Start-NetworkAdminTool',
    'Show-NetworkAdminBanner',
    'Show-NetworkAdminMainMenu', 
    'Show-NetworkAdminHelp',
    'Get-DomainName',
    'Test-DomainConnectivity',
    'Invoke-NetworkAdminUserManagement',
    'Invoke-NetworkAdminComputerManagement',
    'Invoke-NetworkAdminGroupManagement',
    'Invoke-NetworkAdminNetworkDiagnostics',
    'Invoke-NetworkAdminDNSManagement',
    'Invoke-NetworkAdminDHCPInfo',
    'Invoke-NetworkAdminDomainControllerInfo',
    'Invoke-NetworkAdminSecurityAudit',
    'Invoke-SystemHealthCheck'
) -Alias 'netadmin'
