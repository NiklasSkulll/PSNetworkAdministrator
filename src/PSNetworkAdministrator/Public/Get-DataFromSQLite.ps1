function Get-DataFromSQLite {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$DataIndices,

        [Parameter(Mandatory)]
        [string]$DataTableName
    )

    # === check parameters ===
    $DataIndicesIsNotEmpty = Test-FunctionVariables -Param $DataIndices
    $DataTableNameIsNotEmpty = Test-FunctionVariables -Param $DataTableName
    if (-not $DataIndicesIsNotEmpty -or -not $DataTableNameIsNotEmpty) {throw "Data indices/data table name is null/empty."}
    
    # === check, if SQLite file is available ===
    # $DataFilePath = $script:DBFilePath
    # if (-not (...)) {throw "No SQLite file found to get data from."}

    # === get data from SQLite ===
    try {
        # format the indeces as list
        $DataIndicesList = $DataIndices -join ", "

        # get schema from table
        $DataSchemaFull = Get-SQLiteSchemaDefinition -DataTableName $DataTableName
        $DataSchema = $DataSchemaFull.DataSchema

        
    }
    catch {

    }
    finally {

    }
}