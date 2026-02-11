function Remove-DomainCredentials {
    <#
    .SYNOPSIS
        Removes saved credentials for the Domain.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName
    )

    # remove the stored credential with the unique identifier
    try {
        $UniqueIdentifier = "PSNetAdmin_Domain_$DomainName"
        $StoredCred = Get-StoredCredential -Target $UniqueIdentifier

        if ($null -eq $StoredCred) {
            Write-AppLogging -LoggingMessage "No credentials found for Domain: $DomainName" -LoggingLevel "Warning"
            return [PSCustomObject]@{
                DomainName = $DomainName
                Removed = $false
                Reason = "Credential not found."
            }
        }
        
        Remove-StoredCredential -Target $UniqueIdentifier
        Write-AppLogging -LoggingMessage "Successfully removed credentials for Domain: $DomainName" -LoggingLevel "Info"
        return [PSCustomObject]@{
            DomainName = $DomainName
            Removed = $true
            Storage = "Windows Credential Manager"
        }
    }
    catch {
        Write-AppLogging -LoggingMessage "Failed to remove credentials for Domain '$DomainName': $($_.Exception.Message)" -LoggingLevel "Error"
        throw "Failed to remove credentials for Domain '$DomainName': $($_.Exception.Message)"
    }
}