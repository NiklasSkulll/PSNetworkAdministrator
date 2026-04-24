function Get-DomainComputers {
    <#

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName,
    
        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== Check the function variables =====
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    $CredentialCheck = Test-FunctionVariables -Param $Credential -ParamName '$Credential' -Language $Language

    if (-not ($DomainNameCheck.Success) -or -not ($CredentialCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
        if (-not ($CredentialCheck.Success)) {$ErrorMessages += $CredentialCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }

    # ===== Get all computers from domain =====
    try {
        # Get all computers
        $DomainComputers = Get-ADComputer -Server $DomainName -Credential $Credential -Filter * -Properties Description

        # Get current date and time
        $UpdatedAtDate = Get-Date -Format "yyyy-MM-dd,HH:mm:ss"

        # Expand $DomainComputers with properties
        $DomainComputers = $DomainComputers | ForEach-Object {
            [pscustomobject]@{
                ComputerName = $_.Name
                DomainName = $DomainName
                ComputerDescription = $_.Description
                UpdatedAtDate = $UpdatedAtDate
            }
        }

        return $DomainComputers
    }
    catch {
        $RefValue = Get-RefValue -DomainName $DomainName -AdditionalRef 'DomainComputers'
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'SYx0000012' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue -Language $Language

        Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error' -Language $Language
        throw $ErrorMessage
    }
}