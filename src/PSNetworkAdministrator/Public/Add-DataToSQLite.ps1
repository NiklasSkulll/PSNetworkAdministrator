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
        [string]$DataTableName
    )

    # === check if DLL loaded ===
    if (-not $script:SQLiteAvailable) {
        Write-AppLogging -LoggingMessage "Failed to load SQLite DLL during the PSNetworkAdministrator module import." -LoggingLevel "Error"
        throw "Failed to load SQLite DLL during the PSNetworkAdministrator module import."
    }

    # === initialize data schema ===
    try {
        $InitializedDataSchema = Initialize-SQLiteSchema -DomainName $DomainName -DataTableName $DataTableName -DataObject $DataObject
    }
    catch {
        throw "Failed to initialize schema: $($_.Exception.Message)"
    }
    
    # === SQLite file path ===
    $DataFilePath = $script:DBFilePath
    Initialize-FilePath -FilePath $DataFilePath 

    # === create table and write data ===
    try {
        # create the SQLite table if it doesn't exists
        Initialize-SQLiteTable -DomainName $DomainName -DataTableName $DataTableName -DataFilePath $DataFilePath -DataObject $DataObject

        # open SQLite connection
        $SQLiteConnection = [Microsoft.Data.Sqlite.SqliteConnection]::new("Data Source=$DataFilePath")
        $SQLiteConnection.Open()

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

        Write-AppLogging -LoggingMessage "Successfully saved data into SQLite table: $DataTableName" -LoggingLevel "Info"
    }
    catch {
        Write-AppLogging -LoggingMessage "Failed to create '$DataTableName' and write data: $($_.Exception.Message)" -LoggingLevel "Error"
        throw "Failed to create '$DataTableName' and write data: $($_.Exception.Message)"
    }
    finally {
        # close SQLite command and connection
        if ($SQLiteCommand) {$SQLiteCommand.Dispose()}
        if ($SQLiteConnection) {$SQLiteConnection.Dispose()}
    }
}