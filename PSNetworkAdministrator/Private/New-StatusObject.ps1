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
.OUTPUTS
    [PSCustomObject] A status object with standardized properties
.EXAMPLE
    $status = New-StatusObject -Status "Processing"
    Creates a status object with status set to "Processing"
.NOTES
    For internal module use only
#>
function New-StatusObject {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$ModuleName = "PSNetworkAdministrator",
        [string]$Version = (Get-Module PSNetworkAdministrator).Version.ToString(),
        [string]$Status = "Initialized",
        [string]$Domain = $env:USERDNSDOMAIN,
        [string]$UserChoice = ""
    )
    
    Write-Verbose "Creating new status object"
    
    # If version is empty, use default
    if (-not $Version) { 
        $Version = "0.1.0" 
        Write-Verbose "Using default version: $Version"
    }
    
    # If domain is empty, use appropriate default
    if (-not $Domain) { 
        $Domain = "Not connected to a domain" 
        Write-Verbose "No domain detected, using default message"
    } 
    else {
        Write-Verbose "Using domain: $Domain"
    }
    
    Write-Verbose "Status: $Status, UserChoice: $UserChoice"
    
    # Create and return the status object
    $statusObject = [PSCustomObject]@{
        ModuleName = $ModuleName
        Version = $Version
        Status = $Status
        Domain = $Domain
        Timestamp = Get-Date
        UserChoice = $UserChoice
    }
    
    # Add type name for potential future formatting
    $statusObject.PSTypeNames.Insert(0, 'PSNetworkAdministrator.StatusObject')
    
    return $statusObject
}
