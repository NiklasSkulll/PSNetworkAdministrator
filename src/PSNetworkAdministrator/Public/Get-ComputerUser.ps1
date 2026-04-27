function Get-ComputerUser {
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
        [string]$Language = $script:ModuleConfig.Language
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

    # ===== Get computer users =====
    try {
        # Create $ConnectionTarget
        $ConnectionTarget = if ($DNSHostNameCheck.Success) {$DNSHostName} else {"$ComputerName.$DomainName"}

        # Create CimSession on $ConnectionTarget
        $CimSession = $null
        $CimSession = New-CimSession -ComputerName $ConnectionTarget -Credential $Credential -ErrorAction Stop

        # Get current computer user
        try {
            $ComputerSystemUser = Get-CimInstance -CimSession $CimSession -ClassName Win32_ComputerSystem -ErrorAction Stop | Select-Object UserName

            $SystemUserName = $ComputerSystemUser.UserName
        }
        catch {
            $SystemUserName = $null
        }

        # Get interactive computer users
        try {
            $InteractiveUser = Get-CimInstance -CimSession $CimSession -ClassName Win32_LogonSession -Filter 'LogonType=2 OR LogonType=10' -ErrorAction Stop | ForEach-Object {Get-CimAssociatedInstance -InputObject $_ -Association Win32_LoggedOnUser -ErrorAction Stop | Where-Object {$_.Domain -ne 'NT AUTHORITY' -and $_.Name -notin 'SYSTEM','LOCAL SERVICE','NETWORK SERVICE'} | ForEach-Object {"$($_.Domain)\$($_.Name)"}} | Sort-Object -Unique

            $InteractiveUser = @($InteractiveUser | Where-Object {$_}) | ConvertTo-Json -Compress -AsArray
        }
        catch {
            $InteractiveUser = $null
        }

        # Get local computer admins
        try {
            # Get the admin group with the SID for the local administrators
            $AdminGroup = Get-CimInstance -CimSession $CimSession -ClassName Win32_Group -Filter "SID='S-1-5-32-544'" -ErrorAction Stop
            $AdminMembersRaw = Get-CimAssociatedInstance -InputObject $AdminGroup -Association Win32_GroupUser -ErrorAction Stop

            $AdminMembers = @($AdminMembersRaw | ForEach-Object {
                if ($_.Domain -and $_.Name) {"$($_.Domain)\$($_.Name)"}
            } | Where-Object {$_}) | ConvertTo-Json -Compress -AsArray
        }
        catch {
            $AdminMembers = $null
        }
        
        # Return computer user informations
        return [pscustomobject]@{
            ComputerName = $ComputerName
            DomainName = $DomainName
            SystemUserName = $SystemUserName
            InteractiveUser = $InteractiveUser
            AdminMembers = $AdminMembers
            ObservationDate = $ObservationDate
        }
    }
    catch {
        # Return $null if connection failed
        return [pscustomobject]@{
            ComputerName = $ComputerName
            DomainName = $DomainName
            SystemUserName = $null
            InteractiveUser = $null
            AdminMembers = $null
            ObservationDate = $ObservationDate
        }
    }
    finally {
        if ($CimSession) {Remove-CimSession $CimSession}
    }
}