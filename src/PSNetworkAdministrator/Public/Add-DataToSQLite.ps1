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

    # === initial checks (DLL loaded, input is null) ===
    if (-not $script:SQLiteAvailable) {
        Write-AppLogging -LoggingMessage "Failed to load SQLite DLL during the PSNetworkAdministrator module import." -LoggingLevel "Error"
        throw "Failed to load SQLite DLL during the PSNetworkAdministrator module import."
    }
    $DataObjectIsNotEmpty = Test-FunctionVariables -Param $DataObject
    $DomainNameIsNotEmpty = Test-FunctionVariables -Param $DomainName
    $DataTableNameIsNotEmpty = Test-FunctionVariables -Param $DataTableName
    if (-not $DataObjectIsNotEmpty -or -not $DomainNameIsNotEmpty -or -not $DataTableNameIsNotEmpty) {throw "Data object or domain/table name is null/empty."}
    
    # === SQLite file path ===
    $DataFilePath = $script:DBFilePath
    Initialize-FilePath -FilePath $DataFilePath 

    # === create table and write data ===
    try {
        # create the SQLite table if it doesn't exists and get table properties
        $DataTableProperties = Initialize-SQLiteTable -DataTableName $DataTableName -DataFilePath $DataFilePath

        # order the values of the $DataObject
        $DataValuesInOrder = Write-SQLiteSchemaValuesInOrder -DataObject $DataObject -AllColumnNamesWithoutID $DataTableProperties.AllColumnNamesWithoutID -DomainName $DomainName

        # create a list of placeholders for the values
        $DataValuesInOrder = @($DataValuesInOrder)
        $CountDataValues = $DataValuesInOrder.Count
        if ($CountDataValues -eq 0) {throw "'$DataTableName' has no insertable columns. Columns might contain only the ID."}
        $DataValuesPlaceholder = 0..($CountDataValues-1) | ForEach-Object { "@DVP$_" }
        $DataValuePlaceholderList = $DataValuesPlaceholder -join ", "

        # open SQLite connection
        $SQLiteConnection = [Microsoft.Data.Sqlite.SqliteConnection]::new("Data Source=$DataFilePath")
        $SQLiteConnection.Open()

        # write data into the table
        $SQLiteCommandText = "INSERT INTO $($DataTableProperties.QuotedDataTableName) ($($DataTableProperties.AllColumnNamesWithoutIDList)) VALUES ($DataValuePlaceholderList);"
        $SQLiteCommand = $SQLiteConnection.CreateCommand()
        $SQLiteCommand.CommandText = $SQLiteCommandText
        $i = 0
        foreach ($DataValue in $DataValuesInOrder) {
            $SQLParamName = "@DVP$i"

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