function Initialize-Domain {
    <#
    .SYNOPSIS
        Detects and returns the current computer's Active Directory domain membership.
    
    .DESCRIPTION
        The Initialize-Domain function checks whether the current computer is joined to an Active Directory domain.
        If domain membership is detected, it retrieves and returns the domain name. This function is useful for
        automatically detecting the user's domain environment and can be used as an initial step in domain
        configuration workflows. If the computer is not domain-joined, the function throws an error prompting
        the user to manually add a domain.
    
    .EXAMPLE
        Initialize-Domain
    
        Checks domain membership and returns the domain name if the computer is domain-joined.
    
    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        PSCustomObject
        Returns an object containing:
        - Domain: The fully qualified domain name (FQDN) of the computer's domain
    
        Throws an exception if the computer is not joined to a domain.

    .NOTES
        Author: Niklas Schneider
        Version: 1.0.0
        Requires: PowerShell 7.0+, Windows Operating System, Write-AppLogging function
    
        This is a public function exported by the PSNetworkAdministrator module.
        The function uses WMI/CIM to query domain membership status.
        Domain membership detection requires the computer to be properly joined to an Active Directory domain.
    
        Note: This function only detects the current computer's domain membership, not all accessible domains.
        For workgroup computers or non-domain environments, use Add-Domain to manually specify a domain.
    #>

    [CmdletBinding()]
    param()

    # ===== Check if user is in a domain =====
    $IsDomain = (Get-CimInstance Win32_ComputerSystem).PartOfDomain

    # ===== Return domain name =====
    if ($IsDomain) {
        $DomainName = (Get-CimInstance Win32_ComputerSystem).Domain

        $RefValue = Get-RefValue -DomainName $DomainName
        $InfoMessageText = 'Domain has been detected'
        $InfoMessage = "$InfoMessageText | Ref=$RefValue"

        Write-AppLogging -LoggingMessage $InfoMessage -LoggingLevel 'Info'
        
        Return [pscustomobject]@{
            DomainName = $DomainName
        }
    }
    else {
        $RefValue = Get-RefValue -VariableName '$IsDomain' -Value $IsDomain
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'SYx0000011' -RefValue $RefValue
        throw $ErrorMessage
    }
}