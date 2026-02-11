function Add-DomainCredentials {
    <#
    .SYNOPSIS
        Adds credentials for the Domain.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName,
    
        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )

    # store credential in Windows Credential Manager
    try {
        $UniqueIdentifier = "PSNetAdmin_Domain_$DomainName"
        New-StoredCredential -Target $UniqueIdentifier -UserName $Credential.UserName -Password $Credential.GetNetworkCredential().Password -Type Generic -Persist LocalMachine

        Write-AppLogging -LoggingMessage "Credentials stored for domain: $DomainName" -LoggingLevel "Info"

        return [PSCustomObject]@{
            DomainName = $DomainName
            Stored = $true
            Storage = "Windows Credential Manager"
        }
    }
    catch {
        Write-AppLogging -LoggingMessage "Failed to store credentials for domain '$DomainName': $($_.Exception.Message)" -LoggingLevel "Error"
        throw "Failed to store credentials for domain '$DomainName': $($_.Exception.Message)"
    }
}