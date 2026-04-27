function Initialize-FilePath {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [ValidateSet('de', 'en')]
        [string]$Language = $script:ModuleConfig.Language
    )

    # ===== Check the function variable =====
    $FilePathCheck = Test-FunctionVariables -Param $FilePath -ParamName '$FilePath' -Language $Language

    # ===== Get file directory =====
    if ($FilePathCheck.Success) {
        $FileDirectory = Split-Path -Path $FilePath -Parent
    }
    else {
        throw "$($FilePathCheck.Message)"
    }

    # ===== Check database folder and create it =====
    $FileDirectoryCheck = Test-FunctionVariables -Param $FileDirectory -ParamName '$FileDirectory' -Language $Language

    if ($FileDirectoryCheck.Success) {
        if (-not (Test-Path -LiteralPath $FileDirectory)) {New-Item -ItemType Directory -Path $FileDirectory -Force | Out-Null}
    }
    else {
        throw "$($FileDirectoryCheck.Message)"
    }
}