function Remove-DomainCredentials {
    <#
    .SYNOPSIS
        Removes stored domain credentials from Windows Credential Manager.

    .DESCRIPTION
        The Remove-DomainCredentials function deletes previously stored Active Directory domain credentials
        from Windows Credential Manager. It first verifies that credentials exist for the specified domain,
        then removes them and returns a confirmation. If no credentials are found, the function returns
        a result indicating the credential was not found rather than throwing an error. This graceful handling
        makes it safe to call even when uncertain if credentials exist.
    
    .PARAMETER DomainName
        The fully qualified domain name (FQDN) for which to remove stored credentials.
        This parameter is mandatory and must match the domain name used when storing credentials.
    
    .EXAMPLE
        Remove-DomainCredentials -DomainName "contoso.com"
    
        Removes stored credentials for the contoso.com domain.
    
    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        PSCustomObject
        Returns an object containing:
        - Domain: The domain for which credentials were targeted for removal
        - Removed: Boolean indicating whether credentials were removed ($true or $false)
        - Storage: The storage location if removed ("Windows Credential Manager")
        - Reason: Explanation if credentials were not removed ("Credential not found.")

        May throw an exception if the removal operation fails for technical reasons.
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0.0
        Requires: PowerShell 7.0+, CredentialManager module, Write-AppLogging function
    
        This is a public function exported by the PSNetworkAdministrator module.
        Credentials are removed using the unique identifier: "PSNetAdmin_Domain_<DomainName>"
        The function logs warnings if credentials are not found and errors if removal fails.
    
        Security Considerations:
        - Removal requires appropriate Windows permissions to access Credential Manager
        - Once removed, credentials cannot be recovered and must be re-entered
        - Consider the impact on automated processes that depend on stored credentials
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName
    )

    # === remove the stored credential with the unique identifier ===
    try {
        $UniqueIdentifier = "PSNetAdmin_Domain_$DomainName"
        $StoredCred = Get-StoredCredential -Target $UniqueIdentifier

        if ($null -eq $StoredCred) {
            Write-AppLogging -LoggingMessage "Couldn't remove credentials. No credentials found for domain: $DomainName" -LoggingLevel "Warning"
            return [PSCustomObject]@{
                Domain = $DomainName
                Removed = $false
                Reason = "Credential not found."
            }
        }
        
        Remove-StoredCredential -Target $UniqueIdentifier
        Write-AppLogging -LoggingMessage "Successfully removed credentials for domain: $DomainName" -LoggingLevel "Info"
        return [PSCustomObject]@{
            Domain = $DomainName
            Removed = $true
            Storage = "Windows Credential Manager"
        }
    }
    catch {
        Write-AppLogging -LoggingMessage "Failed to remove credentials for domain '$DomainName': $($_.Exception.Message)" -LoggingLevel "Error"
        throw "Failed to remove credentials for domain '$DomainName': $($_.Exception.Message)"
    }
}