<#
.SYNOPSIS
    Creates a status object for PSNetworkAdministrator
.DESCRIPTION
    Creates a standardized status object with information about the current state of the PSNetworkAdministrator module
.PARAMETER ModuleName
    Name of the module, defaults to PSNetworkAdministrator
.PARAMETER Version
    Version of the module
.PARAMETER Status
    Current status of the module
.PARAMETER Domain
    Active Directory domain being used
.PARAMETER UserChoice
    The user's menu choice, if applicable
.EXAMPLE
    $status = New-StatusObject -Status "Processing"
    Creates a status object with status set to "Processing"
.NOTES
    For internal module use only
#>
function New-StatusObject {
    [CmdletBinding()]
    param(
        [string]$ModuleName = "PSNetworkAdministrator",
        [string]$Version = (Get-Module PSNetworkAdministrator).Version.ToString(),
        [string]$Status = "Initialized",
        [string]$Domain = $env:USERDNSDOMAIN,
        [string]$UserChoice = ""
    )
    
    # If version is empty, use default
    if (-not $Version) { $Version = "0.1.0" }
    
    # If domain is empty, use appropriate default
    if (-not $Domain) { $Domain = "Not connected to a domain" }
    
    return [PSCustomObject]@{
        ModuleName = $ModuleName
        Version = $Version
        Status = $Status
        Domain = $Domain
        Timestamp = Get-Date
        UserChoice = $UserChoice
    }
}
