function Add-DomainCredentials {
    <#
    .SYNOPSIS
        Stores domain credentials securely in Windows Credential Manager.
    
    .DESCRIPTION
        The Add-DomainCredentials function securely stores Active Directory domain credentials in the Windows Credential Manager.
        It creates a unique identifier for each domain to prevent conflicts and stores credentials at the LocalMachine level
        for persistence across user sessions. The function logs the operation and returns confirmation of successful storage.
        Stored credentials can be retrieved later using Get-DomainCredentials.
    
    .PARAMETER DomainName
        The fully qualified domain name (FQDN) for which to store credentials.
        This parameter is mandatory and is used to create a unique identifier in Credential Manager.

    .PARAMETER Credential
        A PSCredential object containing the username and password for the domain.
        This parameter is mandatory. The credentials should have appropriate permissions for the intended
        domain operations (typically domain user or administrator).
    
    .EXAMPLE
        $cred = Get-Credential
        Add-DomainCredentials -DomainName "contoso.com" -Credential $cred
    
        Prompts for credentials and stores them for the contoso.com domain.
    
    .INPUTS
        None. This function does not accept pipeline input.
    
    .OUTPUTS
        PSCustomObject
        Returns an object containing:
        - Domain: The domain for which credentials were stored
        - Stored: Boolean indicating successful storage ($true)
        - Storage: The storage location ("Windows Credential Manager")
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0.0
        Requires: PowerShell 7.0+, CredentialManager module, Write-AppLogging function
    
        This is a public function exported by the PSNetworkAdministrator module.
        Credentials are stored with a unique identifier: "PSNetAdmin_Domain_<DomainName>"
        Storage persistence level: LocalMachine (available across user profiles)
    
        Security Considerations:
        - Credentials are encrypted using Windows Data Protection API (DPAPI)
        - Only accessible on the same machine where they were stored
        - Requires appropriate Windows permissions to access Credential Manager
        - Consider implications of LocalMachine persistence in shared environments
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName,
    
        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # === store credential in Windows Credential Manager ===
    try {
        $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
        $CredentialCheck = Test-FunctionVariables -Param $Credential -ParamName '$Credential' -Language $Language

        if (-not ($DomainNameCheck.Success) -or -not ($CredentialCheck.Success)) {
            $ErrorMessages = @()
            if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
            if (-not ($CredentialCheck.Success)) {$ErrorMessages += $CredentialCheck.Message}
        
            $ErrorMessage = $ErrorMessages -join ' || '

            throw $ErrorMessage
        }

        $UniqueIdentifier = "PSNetAdmin_Domain_$DomainName"
        New-StoredCredential -Target $UniqueIdentifier -UserName $Credential.UserName -Password $Credential.GetNetworkCredential().Password -Type Generic -Persist LocalMachine

        $InfoMessage = if ($Language -eq "de") {'Für diese Domain wurden Credentials gespeichert'} else {'Credentials are stored for this domain'}
        Write-AppLogging -LoggingMessage "|$DomainName| $InfoMessage." -LoggingLevel 'Info' -Language $Language

        return [PSCustomObject]@{
            Domain = $DomainName
            Stored = $true
            Storage = "Windows Credential Manager"
        }
    }
    catch {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'INx0000005' -ExceptionMessage "$($_.Exception.Message)" -DomainName $DomainName -Language $Language
        Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error' -Language $Language
        throw $ErrorMessage
    }
}