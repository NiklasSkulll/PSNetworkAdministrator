function Initialize-SQLiteTable {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$DataTableName,

        [Parameter(Mandatory)]
        [string]$DataFilePath,

        [Parameter(Mandatory)]
        [pscustomobject]$DataObject
    )

    # === initialize data schema ===
    try {
        $InitializedDataSchema = Initialize-SQLiteSchema -DomainName $DomainName -DataTableName $DataTableName -DataObject $DataObject
    }
    catch {
        throw "Failed to initialize schema: $($_.Exception.Message)"
    }

    # === create table if it don't exists ===
    try {
        # checks file path
        Initialize-FilePath -FilePath $DataFilePath

        # open SQLite connection
        $SQLiteConnection = [Microsoft.Data.Sqlite.SqliteConnection]::new("Data Source=$DataFilePath")
        $SQLiteConnection.Open()

        # create table if it don't exists
        $SQLiteCommandText = "CREATE TABLE IF NOT EXISTS $($InitializedDataSchema.QuotedDataTableName) ($($InitializedDataSchema.DataTableColumnList));"
        $SQLiteCommand = $SQLiteConnection.CreateCommand()
        $SQLiteCommand.CommandText = $SQLiteCommandText
        $SQLiteCommand.ExecuteNonQuery() | Out-Null

        # create unique index if not exists
        $SQLiteCommandText = "CREATE UNIQUE INDEX IF NOT EXISTS $($InitializedDataSchema.QuotedUX) ON $($InitializedDataSchema.QuotedDataTableName) ($($InitializedDataSchema.DataUniqueIndexList));"
        $SQLiteCommand.CommandText = $SQLiteCommandText
        $SQLiteCommand.ExecuteNonQuery() | Out-Null
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