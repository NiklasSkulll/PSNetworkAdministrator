function Test-FunctionVariables {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Param,

        [bool]$WriteLogging = $false,

        [string]$Message
    )

    # === validate if param is null ===
    if ($null -eq $Param) {
        $ErrorMessage = if (-not $Message) {"Variable in this function is null."} else {$Message}
        if ($WriteLogging) {Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel "Error"}
        return $false
    }

    # === validate if param is string and check on empty/whitespace ===
    if ($Param -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Param)) {
            $ErrorMessage = if (-not $Message) {"Variable in this function is empty/whitespace."} else {$Message}
            if ($WriteLogging) {Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel "Error"}
            return $false
        }
    }

    # === validate if list/array/etc. is empty ===
    if ($Param -is [System.Collections.ICollection]) {
        if ($Param.Count -eq 0) {
            $ErrorMessage = if (-not $Message) {"Collection variable in this function is empty."} else {$Message}
            if ($WriteLogging) {Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel "Error"}
            return $false
        }
    }

    # === all checks successful, return $true ===
    return $true
}