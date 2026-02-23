function Initialize-FilePath {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    # === get file directory ===
    $FilePathIsNotEmpty = Test-FunctionVariables -Param $FilePath
    if ($FilePathIsNotEmpty) {$FileDirectory = Split-Path -Path $FilePath -Parent} else {throw "File is empty/null/whitespace."}

    # === check database folder, creates it ===
    $FileDirectoryIsNotEmpty = Test-FunctionVariables -Param $DataTableName
    if ($FileDirectoryIsNotEmpty) {
        if (-not (Test-Path -LiteralPath $FileDirectory)) {
            New-Item -ItemType Directory -Path $FileDirectory -Force | Out-Null
        }
    }
    else {
        throw "File directory is empty/null/whitespace."
    }
}