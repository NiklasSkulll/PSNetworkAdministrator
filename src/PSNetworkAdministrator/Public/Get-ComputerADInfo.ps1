function Get-ComputerADInfo {
    <#

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$ComputerName,
    
        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [string]$DNSHostName,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== Check the function variables =====
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    $ComputerNameCheck = Test-FunctionVariables -Param $ComputerName -ParamName '$ComputerName' -Language $Language
    $CredentialCheck = Test-FunctionVariables -Param $Credential -ParamName '$Credential' -Language $Language
    $DNSHostNameCheck = Test-FunctionVariables -Param $DNSHostName -ParamName '$DNSHostName' -Language $Language

    if (-not ($DomainNameCheck.Success) -or -not ($ComputerNameCheck.Success) -or -not ($CredentialCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
        if (-not ($ComputerNameCheck.Success)) {$ErrorMessages += $ComputerNameCheck.Message}
        if (-not ($CredentialCheck.Success)) {$ErrorMessages += $CredentialCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }

    # ===== Get current date and time =====
    $ObservationDate = Get-Date -Format "yyyy-MM-dd,HH:mm:ss"

    # ===== Get domain role informations =====
    try {
        # Create $ConnectionTarget
        $ConnectionTarget = if ($DNSHostNameCheck.Success) {$DNSHostName} else {"$ComputerName.$DomainName"}

        # Create CimSession on $ConnectionTarget
        $CimSession = $null
        $CimSession = New-CimSession -ComputerName $ConnectionTarget -Credential $Credential -ErrorAction Stop

        # Get domain role informations with CimSession
        try {
            $ComputerDomainRoleInfo = Get-CimInstance -CimSession $CimSession -ClassName Win32_ComputerSystem -ErrorAction Stop | Select-Object DomainRole

            $ComputerDomainRole = $ComputerDomainRoleInfo.DomainRole
            $HostRole = if ($ComputerDomainRole -eq 0 -or $ComputerDomainRole -eq 1) {'Client'} elseif ($null -eq $ComputerDomainRole) {$null} else {'Server'}
            $IsDomainController = if ($ComputerDomainRole -eq 4 -or $ComputerDomainRole -eq 5) {$true} elseif ($null -eq $ComputerDomainRole) {$null} else {$false}
        }
        catch {
            $ComputerDomainRole = $null
            $HostRole = $null
            $IsDomainController = $null
        }
    }
    catch {
        $ComputerDomainRole = $null
        $HostRole = $null
        $IsDomainController = $null
    }
    finally {
        if ($CimSession) {Remove-CimSession $CimSession}
    }

    # Get AD informations with ActiveDirectory module
    try {
        $ComputerADInfo = Get-ADComputer -Server $DomainName -Credential $Credential -Filter "Name -eq '$ComputerName'" -Properties Enabled, MemberOf

        $MemberOf = @($ComputerADInfo.MemberOf | Where-Object {$_}) | ConvertTo-Json -Compress -AsArray
        $Enabled = $ComputerADInfo.Enabled
    }
    catch {
        $MemberOf = $null
        $Enabled = $null
    }
    
    # Return computer AD informations
    return [pscustomobject]@{
        ComputerName = $ComputerName
        DomainName = $DomainName
        ComputerDomainRole = $ComputerDomainRole
        HostRole = $HostRole
        IsDomainController = $IsDomainController
        MemberOf = $MemberOf
        Enabled = $Enabled
        ObservationDate = $ObservationDate
    }
}