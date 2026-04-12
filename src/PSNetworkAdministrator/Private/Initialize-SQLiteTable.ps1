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
        [pscustomobject]$DataObject,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # === initialize data schema ===
    try {
        $InitializedDataSchema = Initialize-SQLiteSchema -DomainName $DomainName -DataTableName $DataTableName -DataObject $DataObject -Language $Language
    }
    catch {
        throw "$($_.Exception.Message)"
    }

    # === create table if it don't exists ===
    try {
        # checks file path
        Initialize-FilePath -FilePath $DataFilePath -Language $Language

        # open SQLite connection
        $SQLiteConnection = [Microsoft.Data.Sqlite.SqliteConnection]::new("Data Source=$DataFilePath")
        $SQLiteConnection.Open()

        # enable foreign key enforcement
        $PragmaCommand = $SQLiteConnection.CreateCommand()
        $PragmaCommand.CommandText = "PRAGMA foreign_keys = ON;"
        $PragmaCommand.ExecuteNonQuery() | Out-Null
        $PragmaCommand.Dispose()

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
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000013' -ExceptionMessage "$($_.Exception.Message)" -DomainName $DomainName -VariableName '$DataTableName' -VariableValue $DataTableName -Language $Language
        throw $ErrorMessage
    }
    finally {
        # close SQLite command and connection
        if ($SQLiteCommand) {$SQLiteCommand.Dispose()}
        if ($SQLiteConnection) {$SQLiteConnection.Dispose()}
    }
}