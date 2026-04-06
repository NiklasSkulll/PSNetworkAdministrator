function Test-FunctionVariables {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Param,

        [Parameter(Mandatory)]
        [string]$ParamName,

        [bool]$WriteLogging = $false,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== validate if param is null =====
    if ($null -eq $Param) {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000001' -VariableName $ParamName -Language $Language

        if ($WriteLogging) {Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error'}

        return [PSCustomObject]@{
            Success = $false
            Message = $ErrorMessage
        }
    }

    # ===== validate if param is string and check on empty/whitespace =====
    if ($Param -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Param)) {
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000002' -VariableName $ParamName -Language $Language

            if ($WriteLogging) {Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error'}

            return [PSCustomObject]@{
                Success = $false
                Message = $ErrorMessage
            }
        }
    }

    # ===== validate if list/array/etc. is empty =====
    if ($Param -is [System.Collections.ICollection]) {
        if ($Param.Count -eq 0) {
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000005' -VariableName $ParamName -Language $Language

            if ($WriteLogging) {Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error'}

            return [PSCustomObject]@{
                Success = $false
                Message = $ErrorMessage
            }
        }
    }

    # ===== all checks successful, return $true =====
    $SuccessMessage = if ($Language -eq "de") {
        "|$ParamName|: Variable in dieser Funktion ist valide."
    }
    else {
        "|$ParamName|: Variable in this function is valid."
    }

    return [PSCustomObject]@{
        Success = $true
        Message = $SuccessMessage
    }
}