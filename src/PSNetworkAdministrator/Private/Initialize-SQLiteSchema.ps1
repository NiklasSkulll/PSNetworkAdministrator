function Initialize-SQLiteSchema {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$DataTableName,

        [Parameter(Mandatory)]
        [pscustomobject]$DataObject
    )

    # === check function parameter ===
    $DomainNameIsNotEmpty = Test-FunctionVariables -Param $DomainName
    $DataTableNameIsNotEmpty = Test-FunctionVariables -Param $DataTableName
    $DataObjectIsNotEmpty = Test-FunctionVariables -Param $DataObject
    if (-not $DomainNameIsNotEmpty -or -not $DataTableNameIsNotEmpty -or -not $DataObjectIsNotEmpty) {throw "Data object or domain/table name is null/empty."}

    # === check table and get schema ===
    try {
        $DataSchemaFull = Get-SQLiteSchemaDefinition -DataTableName $DataTableName
        $DataSchema = $DataSchemaFull.DataSchema
        $DataUniqueIndex = $DataSchemaFull.DataUniqueIndex
    }
    catch {
        throw "Failed to get table schema: $($_.Exception.Message)"
    }

    # === check data schema content ===
    $DataSchemaFullIsNotEmpty = Test-FunctionVariables -Param $DataSchemaFull
    if (-not $DataSchemaFullIsNotEmpty) {throw "Data schema is null/empty."}

    try {
        # check naming pattern of $DataSchema
        $DataSchemaValidated = Test-SQLiteSchema -DataSchema $DataSchema -DataUniqueIndex $DataUniqueIndex

        # store all column names with and without 'ID'
        $AllColumnNames = $DataSchemaValidated.Columns | ForEach-Object {$_.Name}
        $AllColumnNamesWithoutID = $AllColumnNames | Where-Object {$_ -ne 'Id'}

        # Build a list from $DataSchemaValidated.Columns
        $DataTableColumnParts = foreach ($DataColumn in $DataSchemaValidated.Columns) {
            $ColumnName = '"' + $DataColumn.Name + '"'
            $ColumnDefinition  = "$ColumnName $($DataColumn.Type)"

            if ($DataColumn.ContainsKey('Constraints') -and -not [string]::IsNullOrWhiteSpace($DataColumn.Constraints)) {
                $ColumnDefinition += " $($DataColumn.Constraints)"
            }

            $ColumnDefinition
        }

        # Build a list from $DataUniqueIndex with quotes
        if (-not $DataUniqueIndex) {throw "Schema didn't provided a unique identifier (unique index)."}
        $DataUniqueIndexParts = foreach ($DataIndex in $DataUniqueIndex.IndexNames) {
            $DataIndexName = '"' + $DataIndex.Name + '"'
            $DataIndexName
        }

        # join list with commas, format table name
        $DataTableColumnList = $DataTableColumnParts -join ", "
        $DataUniqueIndexList = $DataUniqueIndexParts -join ", "
        $AllColumnNamesWithoutIDList = ($AllColumnNamesWithoutID | ForEach-Object { '"' + $_ + '"' }) -join ', '

        $QuotedDataTableName = '"' + $DataSchemaValidated.Table + '"'
        $QuotedUX = '"' + $DataUniqueIndex.UX + '"'

        # order the values of the $DataObject
        $DataValuesInOrder = Write-SQLiteSchemaValuesInOrder -DataObject $DataObject -AllColumnNamesWithoutID $AllColumnNamesWithoutID -DomainName $DomainName

        # create a list of placeholders for the values
        $DataValuesInOrder = @($DataValuesInOrder)
        $CountDataValues = $DataValuesInOrder.Count
        if ($CountDataValues -eq 0) {throw "'$DataTableName' has no insertable columns. Columns might contain only the ID."}
        $SQLParamName = "@DVP"
        $DataValuesPlaceholder = 0..($CountDataValues-1) | ForEach-Object { "$SQLParamName$_" }
        $DataValuePlaceholderList = $DataValuesPlaceholder -join ", "

        # return important formatted schema
        return [PSCustomObject]@{
            DataTableName = $DataSchemaValidated.Table
            QuotedDataTableName = $QuotedDataTableName
            DataTableColumnList = $DataTableColumnList
            AllColumnNames = $AllColumnNames
            AllColumnNamesWithoutID = $AllColumnNamesWithoutID
            AllColumnNamesWithoutIDList = $AllColumnNamesWithoutIDList
            QuotedUX = $QuotedUX
            DataUniqueIndexList = $DataUniqueIndexList
            DataValuesInOrder = $DataValuesInOrder
            DataValuesPlaceholder = $DataValuesPlaceholder
            DataValuePlaceholderList = $DataValuePlaceholderList
            SQLParamName = $SQLParamName
        }
    }
    catch {
        throw "Failed to initialize data schema: $($_.Exception.Message)"
    }
}