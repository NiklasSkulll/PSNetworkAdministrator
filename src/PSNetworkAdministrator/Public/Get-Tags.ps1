function Get-Tags {
    <#

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$ComputerName,

        [string]$HostRole,
        [string]$GroupTag,
        [string]$SystemEnvironmentTag,
        [string]$OperatingSystem,

        [ValidateSet('de', 'en')]
        [string]$Language = $script:ModuleConfig.Language
    )

    # ===== Check the tag variables =====
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    $ComputerNameCheck = Test-FunctionVariables -Param $ComputerName -ParamName '$ComputerName' -Language $Language
    $HostRoleCheck = Test-FunctionVariables -Param $HostRole -ParamName '$HostRole' -Language $Language
    $GroupTagCheck = Test-FunctionVariables -Param $GroupTag -ParamName '$GroupTag' -Language $Language
    $SystemEnvironmentTagCheck = Test-FunctionVariables -Param $SystemEnvironmentTag -ParamName '$SystemEnvironmentTag' -Language $Language
    $OperatingSystemCheck = Test-FunctionVariables -Param $OperatingSystem -ParamName '$OperatingSystem' -Language $Language

    if (-not ($DomainNameCheck.Success) -or -not ($ComputerNameCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
        if (-not ($ComputerNameCheck.Success)) {$ErrorMessages += $ComputerNameCheck.Message}

        $ErrorMessage = $ErrorMessages -join '; '
        throw $ErrorMessage
    }

    # ===== Return the tags with the computer object =====
    return [pscustomobject]@{
        ComputerName = $ComputerName
        DomainName = $DomainName
        HostRole = if ($HostRoleCheck.Success) {$HostRole} else {$false}
        GroupTag = if ($GroupTagCheck.Success) {$GroupTag} else {$false}
        SystemEnvironmentTag = if ($SystemEnvironmentTagCheck.Success) {$SystemEnvironmentTag} else {$false}
        OperatingSystem = if ($OperatingSystemCheck.Success) {$OperatingSystem} else {$false}
    }
}