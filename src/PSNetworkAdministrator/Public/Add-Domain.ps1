function Add-Domain {
    <#
    .SYNOPSIS
        Adds a domain name to the PSNetworkAdministrator application.
    
    .DESCRIPTION
        The Add-Domain function accepts a domain name as input, validates it, and prepares it for use in the application.
        It trims whitespace from the input and validates that the domain name is not empty or null.
        The function logs the addition of the domain and returns a structured object containing the added domain name.
        This is typically the first step in managing a new domain within the application.
    
    .PARAMETER DomainName
        The fully qualified domain name (FQDN) to add to the application.
        This parameter is mandatory and should contain a valid domain name.
    
    .EXAMPLE
        Add-Domain -DomainName "contoso.com"
    
        Adds the domain "contoso.com" to the application and logs the action.
    
    .EXAMPLE
        $result = Add-Domain -DomainName "  contoso.com  "
        $result.Domain
    
        Adds the domain "contoso.com" (after trimming whitespace) and retrieves the added domain name.
    
    .INPUTS
        None. This function does not accept pipeline input directly.
    
    .OUTPUTS
        PSCustomObject
        Returns an object containing:
        - Domain: The trimmed domain name that was added
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0.0
        Requires: PowerShell 7.0+, Write-AppLogging function
    
        This is a public function exported by the PSNetworkAdministrator module.
        The function performs basic validation but does not verify that the domain is reachable or valid.
        Subsequent operations (like Add-DomainCredentials, Add-DomainComputers) will require valid credentials
        and network connectivity to the domain.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName
    )

    # === trims input ===
    $DomainName = $DomainName.Trim()

    # === checks if input is empty/null/whitespace ===
    if ([string]::IsNullOrWhiteSpace($DomainName)) {
        throw "Empty Input. You need to provide a domain name."
    }

    # === return the domain ===
    Write-AppLogging -LoggingMessage "Domain manually added: $DomainName" -LoggingLevel "Info"
    return [PSCustomObject]@{
            Domain = $DomainName
        }
}