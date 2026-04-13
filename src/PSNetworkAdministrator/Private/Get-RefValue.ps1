function Get-RefValue {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [string]$DomainName,
        [string]$ComputerName,
        [string]$VariableName,

        $Value
    )

    # ===== Check the function variables =====
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    $ComputerNameCheck = Test-FunctionVariables -Param $ComputerName -ParamName '$ComputerName' -Language $Language
    $VariableNameCheck = Test-FunctionVariables -Param $VariableName -ParamName '$VariableName' -Language $Language
    $ValueCheck = Test-FunctionVariables -Param $Value -ParamName '$Value' -Language $Language

    if (-not ($DomainNameCheck.Success) -and -not ($ComputerNameCheck.Success) -and -not ($VariableNameCheck.Success) -and -not ($ValueCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
        if (-not ($ComputerNameCheck.Success)) {$ErrorMessages += $ComputerNameCheck.Message}
        if (-not ($VariableNameCheck.Success)) {$ErrorMessages += $VariableNameCheck.Message}
        if (-not ($ValueCheck.Success)) {$ErrorMessages += $ValueCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join ' || '

        throw $ErrorMessage
    }

    # ===== Create a reference value for a message =====
    $RefValueComAndVar = if ($ComputerName -and $VariableName) {"$ComputerName-$VariableName"} else {$null}

    $RefValues = @()
    if ($DomainName) {$RefValues += $DomainName}
    if ($RefValueComAndVar) {$RefValues += $RefValueComAndVar}
    if (-not $RefValueComAndVar) {
        if ($ComputerName) {$RefValues += $ComputerName}
        if ($VariableName) {$RefValues += $VariableName}
    }
    if ($Value) {$RefValues += $Value}

    $RefValuesJoin = $RefValues -join '|'
    $RefValue = "<$RefValuesJoin>"

    # ===== Return the reference value =====
    return $RefValue
}