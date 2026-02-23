function Initialize-SQLiteTable {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DataTableName,

        [Parameter(Mandatory)]
        [string]$DataFilePath
    )

    # === check table and get schema ===
    try {
        $DataSchemaFull = Get-SQLiteSchemaDefinition -DataTableName $DataTableName
        $DataSchema = $DataSchemaFull.DataSchema
        $DataUniqueIndex = $DataSchemaFull.DataUniqueIndex
    }
    catch {
        throw "Failed to get table schema: $($_.Exception.Message)"
    }

    # === create table if it don't exists ===
    if ($DataSchemaFull) {
        try {
            # check naming pattern of $DataSchema
            $DataSchemaValidated = Test-SQLiteSchema -DataSchema $DataSchema -DataUniqueIndex $DataUniqueIndex

            # store all column names with and without 'ID'
            $AllColumnNames = $DataSchemaValidated.Columns | ForEach-Object {$_.Name}
            $AllColumnNamesWithoutID = $AllColumnNames | Where-Object {$_ -ne 'Id'}

            # checks file path
            Initialize-FilePath -FilePath $DataFilePath

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

            $QuotedDataTableName = '"' + $DataSchemaValidated.Table + '"'
            $QuotedUX = '"' + $DataUniqueIndex.UX + '"'

            # open SQLite connection
            $SQLiteConnection = [Microsoft.Data.Sqlite.SqliteConnection]::new("Data Source=$DataFilePath")
            $SQLiteConnection.Open()

            # create table if it don't exists
            $SQLiteCommandText = "CREATE TABLE IF NOT EXISTS $QuotedDataTableName ($DataTableColumnList);"
            $SQLiteCommand = $SQLiteConnection.CreateCommand()
            $SQLiteCommand.CommandText = $SQLiteCommandText
            $SQLiteCommand.ExecuteNonQuery() | Out-Null

            # create unique index if not exists
            $SQLiteCommandText = "CREATE UNIQUE INDEX IF NOT EXISTS $QuotedUX ON $QuotedDataTableName ($DataUniqueIndexList);"
            $SQLiteCommand.CommandText = $SQLiteCommandText
            $SQLiteCommand.ExecuteNonQuery() | Out-Null

            return [PSCustomObject]@{
                DataTableName = $DataSchemaValidated.Table
                QuotedDataTableName = $QuotedDataTableName
                DataTableColumnList = $DataTableColumnList
                AllColumnNamesWithoutID = $AllColumnNamesWithoutID
                AllColumnNamesWithoutIDList = ($AllColumnNamesWithoutID | ForEach-Object { '"' + $_ + '"' }) -join ', '
            }
        }
        catch {
            throw "Failed to create table: $($_.Exception.Message)"
        }
        finally {
            # close SQLite command and connection
            if ($SQLiteCommand) {$SQLiteCommand.Dispose()}
            if ($SQLiteConnection) {$SQLiteConnection.Dispose()}
        }
    }
}