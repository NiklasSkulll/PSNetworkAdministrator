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
        [pscustomobject]$DataObject,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== Initialize data schema =====
    try {
        $InitializedDataSchema = Initialize-SQLiteSchema -DomainName $DomainName -DataTableName $DataTableName -DataObject $DataObject -Language $Language
    }
    catch {
        $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000009' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }

    # ===== Create table if it don't exists =====
    try {
        # Checks database file path
        $DataFilePath = $script:DBFilePath
        Initialize-FilePath -FilePath $DataFilePath -Language $Language

        # Open SQLite connection
        $SQLiteConnection = [Microsoft.Data.Sqlite.SqliteConnection]::new("Data Source=$DataFilePath")
        $SQLiteConnection.Open()

        # Enable foreign key enforcement
        $PragmaCommand = $SQLiteConnection.CreateCommand()
        $PragmaCommand.CommandText = "PRAGMA foreign_keys = ON;"
        $PragmaCommand.ExecuteNonQuery() | Out-Null
        $PragmaCommand.Dispose()

        # Create table if it don't exists
        $SQLiteCommandText = "CREATE TABLE IF NOT EXISTS $($InitializedDataSchema.QuotedDataTableName) ($($InitializedDataSchema.DataTableColumnList));"
        $SQLiteCommand = $SQLiteConnection.CreateCommand()
        $SQLiteCommand.CommandText = $SQLiteCommandText
        $SQLiteCommand.ExecuteNonQuery() | Out-Null

        # Create unique index if not exists
        $SQLiteCommandText = "CREATE UNIQUE INDEX IF NOT EXISTS $($InitializedDataSchema.QuotedUX) ON $($InitializedDataSchema.QuotedDataTableName) ($($InitializedDataSchema.DataUniqueIndexList));"
        $SQLiteCommand.CommandText = $SQLiteCommandText
        $SQLiteCommand.ExecuteNonQuery() | Out-Null
    }
    catch {
        $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000006' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }
    finally {
        # Close SQLite command and connection
        if ($PragmaCommand) {$PragmaCommand.Dispose()}
        if ($SQLiteCommand) {$SQLiteCommand.Dispose()}
        if ($SQLiteConnection) {$SQLiteConnection.Dispose()}
    }
}