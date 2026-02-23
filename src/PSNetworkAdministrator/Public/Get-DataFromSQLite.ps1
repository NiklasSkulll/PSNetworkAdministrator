function Get-DataFromSQLite {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DataTableName,

        [Parameter(Mandatory)]
        $DataIndexName1,

        $DataIndexName2,

        [Parameter(Mandatory)]
        $DataIndexValue1,

        $DataIndexValue2
    )

    # === check parameters ===
    $DataTableNameIsNotEmpty = Test-FunctionVariables -Param $DataTableName
    $DataIndexName1IsNotEmpty = Test-FunctionVariables -Param $DataIndexName1
    $DataIndexValue1IsNotEmpty = Test-FunctionVariables -Param $DataIndexValue1
    if (-not $DataIndexName1IsNotEmpty -or -not $DataTableNameIsNotEmpty -or -not $DataIndexValue1IsNotEmpty) {throw "Data table name/Index name/Index value is null/empty."}
    
    # === check, if SQLite file is available ===
    # $DataFilePath = $script:DBFilePath
    # if (-not (...)) {throw "No SQLite file found to get data from '$DataTableName'."}

    # === get data from SQLite ===
    try {
        $DataIndexName2IsNotEmpty = Test-FunctionVariables -Param $DataIndexName2
        $DataIndexValue2IsNotEmpty = Test-FunctionVariables -Param $DataIndexValue2

        # connect index name and value
        $SQLWhereStatement = if ($DataIndexName2IsNotEmpty -and $DataIndexValue2IsNotEmpty) {
            "$DataIndexName1=$DataIndexValue1 AND $DataIndexName2=$DataIndexValue2"
        }
        else {
            "$DataIndexName1=$DataIndexValue1"
        }

        # open SQLite connection
        $SQLiteConnection = [Microsoft.Data.Sqlite.SqliteConnection]::new("Data Source=$DataFilePath")
        $SQLiteConnection.Open()

        # write data into the table
        $SQLiteCommandText = "SELECT * FROM $DataTableName WHERE $SQLWhereStatement;"
        $SQLiteCommand = $SQLiteConnection.CreateCommand()
        $SQLiteCommand.CommandText = $SQLiteCommandText

        $SQLiteCommand.ExecuteNonQuery() | Out-Null
    }
    catch {
        Write-AppLogging -LoggingMessage "Failed to get data from '$DataTableName': $($_.Exception.Message)" -LoggingLevel "Error"
        throw "Failed to get data from '$DataTableName': $($_.Exception.Message)"
    }
    finally {
        # close SQLite command and connection
        if ($SQLiteCommand) {$SQLiteCommand.Dispose()}
        if ($SQLiteConnection) {$SQLiteConnection.Dispose()}
    }
}