function Get-DomainCredentials {
    <#
    .SYNOPSIS
        Retrieves stored domain credentials from Windows Credential Manager.
    
    .DESCRIPTION
        The Get-DomainCredentials function retrieves previously stored Active Directory domain credentials
        from Windows Credential Manager using a unique identifier based on the domain name.
        It validates that credentials exist for the specified domain and returns them as a PSCredential object
        wrapped in a structured result. This function is typically used in conjunction with Add-DomainCredentials
        and is essential for authenticating domain operations without prompting users repeatedly.
    
    .PARAMETER DomainName
        The fully qualified domain name (FQDN) for which to retrieve stored credentials.
        This parameter is mandatory and must match the domain name used when storing credentials.
    
    .EXAMPLE
        $storedCreds = Get-DomainCredentials -DomainName "contoso.com"
        $storedCreds.DomainCredentials
    
        Retrieves stored credentials for contoso.com domain.
    
    .INPUTS
        None. This function does not accept pipeline input.
    
    .OUTPUTS
        PSCustomObject
        Returns an object containing:
        - Domain: The domain for which credentials were retrieved
        - DomainCredentials: PSCredential object with stored username and password
    
        Throws an exception if no credentials are found for the specified domain.
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0.0
        Requires: PowerShell 7.0+, CredentialManager module, Write-AppLogging function
    
        This is a public function exported by the PSNetworkAdministrator module.
        Credentials are retrieved using the unique identifier: "PSNetAdmin_Domain_<DomainName>"
        The function will throw an error if credentials don't exist for the specified domain.
    
        Security Considerations:
        - Retrieval uses Windows Data Protection API (DPAPI) decryption
        - Only works on the machine where credentials were originally stored
        - Requires appropriate Windows permissions to access Credential Manager
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName
    )

    # === get the stored credential with the unique identifier ===
    try {
        $DomainNameIsNotEmpty = Test-FunctionVariables -Param $DomainName
        if (-not $DomainNameIsNotEmpty) {throw "Domain name is null/empty."}

        $UniqueIdentifier = "PSNetAdmin_Domain_$DomainName"
        $StoredCred = Get-StoredCredential -Target $UniqueIdentifier

        if ($null -eq $StoredCred) {
            Write-AppLogging -LoggingMessage "No credentials found for domain: $DomainName" -LoggingLevel "Error"
            throw "No credentials found for domain: $DomainName"
        }

        return [PSCustomObject]@{
            Domain = $DomainName
            DomainCredentials = $StoredCred
        }
    }
    catch {
        Write-AppLogging -LoggingMessage "Failed to get credentials for domain '$DomainName': $($_.Exception.Message)" -LoggingLevel "Error"
        throw "Failed to get credentials for domain '$DomainName': $($_.Exception.Message)"
    }
}