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
        [string]$Language = $script:ModuleConfig.Language
    )

    # ===== Create reference value for messages =====
    $RefValue = "<$ParamName>"

    # ===== Validate if $Param is null =====
    if ($null -eq $Param) {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000001' -RefValue $RefValue -Language $Language

        if ($WriteLogging) {Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error' -Language $Language}

        return [pscustomobject]@{
            Success = $false
            Message = $ErrorMessage
        }
    }

    # ===== Validate if $Param is a string and check if null or whitespace =====
    if ($Param -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Param)) {
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000002' -RefValue $RefValue -Language $Language

            if ($WriteLogging) {Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error' -Language $Language}

            return [pscustomobject]@{
                Success = $false
                Message = $ErrorMessage
            }
        }
    }

    # ===== Validate if $Param is a list/array/etc. and check if empty =====
    if ($Param -is [System.Collections.ICollection]) {
        if ($Param.Count -eq 0) {
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000005' -RefValue $RefValue -Language $Language

            if ($WriteLogging) {Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error' -Language $Language}

            return [pscustomobject]@{
                Success = $false
                Message = $ErrorMessage
            }
        }
    }

    # ===== Create a message: all checks are successful =====
    $SuccessMessage = if ($Language -eq "de") {'Variable ist gültig'} else {'Variable is valid'}
    $SuccessMessageFull = "$SuccessMessage | Ref=$RefValue"

    # ===== Return $true =====
    return [pscustomobject]@{
        Success = $true
        Message = $SuccessMessageFull
    }
}