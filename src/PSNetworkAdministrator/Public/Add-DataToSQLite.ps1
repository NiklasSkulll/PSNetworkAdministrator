function Add-DataToSQLite {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [pscustomobject]$DataObject,

        [Parameter(Mandatory)]
        [string]$DataTableName,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # === check if DLL loaded ===
    if (-not $script:SQLiteAvailable) {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'INx0000004' -DomainName $DomainName -Language $Language
        
        Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error' -Language $Language
        throw $ErrorMessage
    }

    # === initialize data schema ===
    try {
        $InitializedDataSchema = Initialize-SQLiteSchema -DomainName $DomainName -DataTableName $DataTableName -DataObject $DataObject -Language $Language
    }
    catch {
        throw "$($_.Exception.Message)"
    }
    
    # === SQLite file path ===
    $DataFilePath = $script:DBFilePath
    Initialize-FilePath -FilePath $DataFilePath -Language $Language

    # === create table and write data ===
    try {
        # create the SQLite table if it doesn't exists
        Initialize-SQLiteTable -DomainName $DomainName -DataTableName $DataTableName -DataFilePath $DataFilePath -DataObject $DataObject -Language $Language

        # open SQLite connection
        $SQLiteConnection = [Microsoft.Data.Sqlite.SqliteConnection]::new("Data Source=$DataFilePath")
        $SQLiteConnection.Open()

        # enable foreign key enforcement
        $PragmaCommand = $SQLiteConnection.CreateCommand()
        $PragmaCommand.CommandText = "PRAGMA foreign_keys = ON;"
        $PragmaCommand.ExecuteNonQuery() | Out-Null
        $PragmaCommand.Dispose()

        # write data into the table
        $SQLiteCommandText = "INSERT INTO $($InitializedDataSchema.QuotedDataTableName) ($($InitializedDataSchema.AllColumnNamesWithoutIDList)) VALUES ($($InitializedDataSchema.DataValuePlaceholderList));"
        $SQLiteCommand = $SQLiteConnection.CreateCommand()
        $SQLiteCommand.CommandText = $SQLiteCommandText
        $i = 0
        foreach ($DataValue in $($InitializedDataSchema.DataValuesInOrder)) {
            $SQLParamName = "$($InitializedDataSchema.SQLParamName)$i"

            $SQLParam = $SQLiteCommand.CreateParameter()
            $SQLParam.ParameterName = $SQLParamName
            $SQLParam.Value = if ($null -eq $DataValue) {[DBNull]::Value} else {$DataValue}

            [void]$SQLiteCommand.Parameters.Add($SQLParam)

            $i++
        }
        $SQLiteCommand.ExecuteNonQuery() | Out-Null

        $InfoMessageRefVar = '$DataTableName'
        $InfoMessage = if ($Language -eq "de") {'Daten wurden erfolgreich in SQLite-Tabelle gespeichert'} else {'Successfully saved data into SQLite table'}
        Write-AppLogging -LoggingMessage "|$DomainName|$InfoMessageRefVar|$DataTableName| $InfoMessage." -LoggingLevel 'Info' -Language $Language
    }
    catch {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000014' -ExceptionMessage "$($_.Exception.Message)" -DomainName $DomainName -VariableName '$DataTableName' -VariableValue $DataTableName -Language $Language
        
        Write-AppLogging -LoggingMessage $ErrorMessage -LoggingLevel 'Error' -Language $Language
        throw $ErrorMessage
    }
    finally {
        # close SQLite command and connection
        if ($SQLiteCommand) {$SQLiteCommand.Dispose()}
        if ($SQLiteConnection) {$SQLiteConnection.Dispose()}
    }
}