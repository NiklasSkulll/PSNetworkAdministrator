function Get-RefValue {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [string]$DomainName,
        [string]$ComputerName,
        [string]$VariableName,

        $Value,
        [string]$AdditionalRef,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== Check the function variables =====
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    $ComputerNameCheck = Test-FunctionVariables -Param $ComputerName -ParamName '$ComputerName' -Language $Language
    $VariableNameCheck = Test-FunctionVariables -Param $VariableName -ParamName '$VariableName' -Language $Language
    $ValueCheck = Test-FunctionVariables -Param $Value -ParamName '$Value' -Language $Language
    $AdditionalRefCheck = Test-FunctionVariables -Param $AdditionalRef -ParamName '$AdditionalRef' -Language $Language

    if (-not ($DomainNameCheck.Success) -and -not ($ComputerNameCheck.Success) -and -not ($VariableNameCheck.Success) -and -not ($ValueCheck.Success) -and -not ($AdditionalRefCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
        if (-not ($ComputerNameCheck.Success)) {$ErrorMessages += $ComputerNameCheck.Message}
        if (-not ($VariableNameCheck.Success)) {$ErrorMessages += $VariableNameCheck.Message}
        if (-not ($ValueCheck.Success)) {$ErrorMessages += $ValueCheck.Message}
        if (-not ($AdditionalRefCheck.Success)) {$ErrorMessages += $AdditionalRefCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }

    # ===== Create a reference value for a message =====
    $RefValueDomAndCom = if ($DomainNameCheck.Success -and $ComputerNameCheck.Success) {"$DomainName-$ComputerName"} else {$null}
    $RefValueVarAndVal = if ($VariableNameCheck.Success -and $ValueCheck.Success) {"$VariableName='$Value'"} else {$null}

    $RefValues = @()
    if ($RefValueDomAndCom) {$RefValues += $RefValueDomAndCom}
    if (-not $RefValueDomAndCom) {
        if ($DomainNameCheck.Success) {$RefValues += $DomainName}
        if ($ComputerNameCheck.Success) {$RefValues += $ComputerName}
    }
    if ($RefValueVarAndVal) {$RefValues += $RefValueVarAndVal}
    if (-not $RefValueVarAndVal) {
        if ($VariableNameCheck.Success) {$RefValues += $VariableName}
        if ($ValueCheck.Success) {$RefValues += $Value}
    }
    if ($AdditionalRefCheck.Success) {$RefValues += $AdditionalRef}

    $RefValuesJoin = $RefValues -join '|'
    $RefValue = "<$RefValuesJoin>"

    # ===== Return the reference value =====
    return $RefValue
}