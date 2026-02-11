function Add-Domain {
    <#
    .SYNOPSIS
        Adds Domain from user input.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainToAdd
    )

    # trims input
    $DomainToAdd = $DomainToAdd.Trim()

    # checks if input is empty/null/whitespace
    if ([string]::IsNullOrWhiteSpace($DomainToAdd)) {
        throw "Empty Input. You need to write the Domain name."
    }

    # return the Domain
    Write-AppLogging -LoggingMessage "Domain manually added: $DomainToAdd" -LoggingLevel "Info"
    return [PSCustomObject]@{
            AddedDomain = $DomainToAdd
        }
}