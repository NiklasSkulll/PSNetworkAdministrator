function Get-DomainCredentials {
    <#
    .SYNOPSIS
        Gets credentials for the Domain.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName
    )

    # get the stored credential with the unique identifier
    try {
        $UniqueIdentifier = "PSNetAdmin_Domain_$DomainName"
        $StoredCred = Get-StoredCredential -Target $UniqueIdentifier

        if ($null -eq $StoredCred) {
            throw "No credentials found for domain: $DomainName"
        }

        return [PSCustomObject]@{
            DomainName = $DomainName
            DomainCredentials = $StoredCred
        }
    }
    catch {
        Write-AppLogging -LoggingMessage "Failed to get credentials for Domain '$DomainName': $($_.Exception.Message)" -LoggingLevel "Error"
        throw "Failed to get credentials for Domain '$DomainName': $($_.Exception.Message)"
    }
}