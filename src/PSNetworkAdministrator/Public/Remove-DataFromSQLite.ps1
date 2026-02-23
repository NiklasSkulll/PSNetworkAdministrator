function Remove-DataFromSQLite {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$DataObject,

        [Parameter(Mandatory)]
        [string]$DataTableName
    )
}