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
        [string]$DomainName,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== Check the function variables =====
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    if (-not ($DomainNameCheck.Success)) {throw "$($DomainNameCheck.Message)"}

    # ===== Remove credentials from Windows Credential Manager =====
    try {
        # Get the stored credentials with the unique id
        $UniqueIdentifier = "PSNetAdmin_Domain_$DomainName"
        $StoredCred = Get-StoredCredential -Target $UniqueIdentifier

        # Check $StoredCred
        if ($null -eq $StoredCred) {
            $RefValue = Get-RefValue -DomainName $DomainName -AdditionalRef 'Credentials' -Language $Language
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'SYx0000012' -RefValue $RefValue -Language $Language
            throw $ErrorMessage
        }
        
        # Remove the stored credentials with the unique id
        Remove-StoredCredential -Target $UniqueIdentifier

        # Write info message in logs
        $InfoMessageText = if ($Language -eq "de") {'Credentials wurden entfernt'} else {'Credentials are removed'}
        $InfoMessage = "$InfoMessageText | Ref=$RefValue"
        Write-AppLogging -LoggingMessage $InfoMessage -LoggingLevel 'Info' -Language $Language

        # Return status information
        return [pscustomobject]@{
            DomainName = $DomainName
            Removed = $true
            Storage = 'Windows Credential Manager'
        }
    }
    catch {
        $RefValue = Get-RefValue -DomainName $DomainName -AdditionalRef 'Credentials' -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'SYx0000013' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue -Language $Language

        Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error' -Language $Language
        throw $ErrorMessage
    }
}