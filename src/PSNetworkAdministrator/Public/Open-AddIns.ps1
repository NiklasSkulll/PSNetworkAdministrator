function Open-AddIns {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AddInName,

        [Parameter(Mandatory)]
        [string]$AddInPath,

        [Parameter(Mandatory)]
        [string]$AddInArgument,

        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$ComputerName,

        [ValidateSet('de', 'en')]
        [string]$Language = $script:ModuleConfig.Language
    )

    # ===== Check the function variables =====
    $AddInNameCheck = Test-FunctionVariables -Param $AddInName -ParamName '$AddInName' -Language $Language
    $AddInPathCheck = Test-FunctionVariables -Param $AddInPath -ParamName '$AddInPath' -Language $Language
    $AddInArgumentCheck = Test-FunctionVariables -Param $AddInArgument -ParamName '$AddInArgument' -Language $Language
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    $ComputerNameCheck = Test-FunctionVariables -Param $ComputerName -ParamName '$ComputerName' -Language $Language

    if (-not ($AddInNameCheck.Success) -or -not ($AddInPathCheck.Success) -or -not ($AddInArgumentCheck.Success) -or -not ($DomainNameCheck.Success) -or -not ($ComputerNameCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($AddInNameCheck.Success)) {$ErrorMessages += $AddInNameCheck.Message}
        if (-not ($AddInPathCheck.Success)) {$ErrorMessages += $AddInPathCheck.Message}
        if (-not ($AddInArgumentCheck.Success)) {$ErrorMessages += $AddInArgumentCheck.Message}
        if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
        if (-not ($ComputerNameCheck.Success)) {$ErrorMessages += $ComputerNameCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }

    # ===== Open AddIn =====
    try {
        $ResolvedArgument = $AddInArgument
        $Placeholders = @{
            '{Computer}' = $ComputerName
            '{Domain}'   = $DomainName
        }

        foreach ($Key in $Placeholders.Keys) {
            $ResolvedArgument = $ResolvedArgument.Replace($Key, $Placeholders[$Key])
        }

        Start-Process -FilePath $AddInPath -ArgumentList $ResolvedArgument
    }
    catch {
        $RefValue = Get-RefValue -VariableName '$AddInName' -Value $AddInName -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'INx0000006' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }
}