function Get-OperatingSystem {
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

    # ===== Get computer OS informations =====
    try {
        # Create $ConnectionTarget
        $ConnectionTarget = if ($DNSHostNameCheck.Success) {$DNSHostName} else {"$ComputerName.$DomainName"}

        # Create CimSession on $ConnectionTarget
        $CimSession = $null
        $CimSession = New-CimSession -ComputerName $ConnectionTarget -Credential $Credential -ErrorAction Stop

        # Get OS informations
        try {
            $ComputerOSInfo = Get-CimInstance -CimSession $CimSession -ClassName Win32_OperatingSystem -ErrorAction Stop | Select-Object Caption, Version, OSArchitecture

            $OperatingSystem = $ComputerOSInfo.Caption
            $OperatingSystemVersion = $ComputerOSInfo.Version
            $OSArchitecture = $ComputerOSInfo.OSArchitecture
        }
        catch {
            $OperatingSystem = $null
            $OperatingSystemVersion = $null
            $OSArchitecture = $null
        }

        # Get $OSDisplayVersion
        try {
            $Hive = 2147483650 # HKEY_LOCAL_MACHINE
            $RegistryKey = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion'

            $DisplayVersionInformation = Invoke-CimMethod -CimSession $CimSession -Namespace root/default -ClassName StdRegProv -MethodName GetStringValue -Arguments @{
                hDefKey     = $Hive
                sSubKeyName = $RegistryKey
                sValueName  = 'DisplayVersion'
            } -ErrorAction Stop

            $CurrentBuildInformation = Invoke-CimMethod -CimSession $CimSession -Namespace root/default -ClassName StdRegProv -MethodName GetStringValue -Arguments @{
                hDefKey     = $Hive
                sSubKeyName = $RegistryKey
                sValueName  = 'CurrentBuild'
            } -ErrorAction Stop

            $DisplayVersion = $DisplayVersionInformation.sValue
            $CurrentBuild = $CurrentBuildInformation.sValue

            $BuildToVersion = @{
                '14393' = 'Server16'
                '19041' = '20H1 Win10' # Win10
                '19042' = '20H2 Win10'
                '19043' = '21H1 Win10'
                '19044' = '21H2 Win10'
                '19045' = '22H2 Win10'
                '22000' = '21H2 Win11' # Win11
                '22621' = '22H2 Win11'
                '22631' = '23H2 Win11'
                '26100' = '24H2 Win11|Server25'
                '26200' = '25H2 Win11|Server25'
            }

            $OSDisplayVersion = if ($DisplayVersion) {
                if ($BuildToVersion.ContainsKey([string]$CurrentBuild)) {
                    $BuildToVersion[[string]$CurrentBuild]
                }
                else {
                    $DisplayVersion
                }
            }
            elseif ($BuildToVersion.ContainsKey([string]$CurrentBuild)) {
                $BuildToVersion[[string]$CurrentBuild]
            }
            else {
                $null
            }
        }
        catch {
            $OSDisplayVersion = $null
        }

        # Return computer OS informations
        return [pscustomobject]@{
            ComputerName = $ComputerName
            DomainName = $DomainName
            OperatingSystem = $OperatingSystem
            OperatingSystemVersion = $OperatingSystemVersion
            OSDisplayVersion = $OSDisplayVersion
            OSArchitecture = $OSArchitecture
            ObservationDate = $ObservationDate
        }
    }
    catch {
        # Return $null if connection failed
        return [pscustomobject]@{
            ComputerName = $ComputerName
            DomainName = $DomainName
            OperatingSystem = $null
            OperatingSystemVersion = $null
            OSDisplayVersion = $null
            OSArchitecture = $null
            ObservationDate = $ObservationDate
        }
    }
    finally {
        if ($CimSession) {Remove-CimSession $CimSession}
    }
}