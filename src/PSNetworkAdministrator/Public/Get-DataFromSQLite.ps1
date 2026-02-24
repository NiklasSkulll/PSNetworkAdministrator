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
    $DataFilePath = $script:DBFilePath
    if ([string]::IsNullOrWhiteSpace($DataFilePath)) {throw "SQLite DB file path is empty."}
    if (-not (Test-Path -LiteralPath $DataFilePath -PathType Leaf)) {throw "No SQLite DB file found at '$DataFilePath' to get data from '$DataTableName'."}

    # === get data from SQLite ===
    try {
        $DataIndexName2IsNotEmpty = Test-FunctionVariables -Param $DataIndexName2
        $DataIndexValue2IsNotEmpty = Test-FunctionVariables -Param $DataIndexValue2

        # connect index name and value
        $SQLWhereParts = @()
        $SQLWhereParts += '"' + $DataIndexName1 + '" = @DVP0'
        if ($DataIndexName2IsNotEmpty -and $DataIndexValue2IsNotEmpty) {
            $SQLWhereParts += '"' + $DataIndexName2 + '" = @DVP1'
        }
        $SQLWhereStatement = $SQLWhereParts -join ' AND '

        $QuotedDataTableName = '"' + $DataTableName + '"'

        # open SQLite connection
        $SQLiteConnection = [Microsoft.Data.Sqlite.SqliteConnection]::new("Data Source=$DataFilePath")
        $SQLiteConnection.Open()

        # write data into the table
        $SQLiteCommandText = "SELECT * FROM $QuotedDataTableName WHERE $SQLWhereStatement;"

        $SQLiteCommand = $SQLiteConnection.CreateCommand()
        $SQLiteCommand.CommandText = $SQLiteCommandText

        $DVP0 = $SQLiteCommand.CreateParameter()
        $DVP0.ParameterName = '@DVP0'
        $DVP0.Value = $DataIndexValue1
        [void]$SQLiteCommand.Parameters.Add($DVP0)

        if ($DataIndexName2IsNotEmpty -and $DataIndexValue2IsNotEmpty) {
            $DVP1 = $SQLiteCommand.CreateParameter()
            $DVP1.ParameterName = '@DVP1'
            $DVP1.Value = $DataIndexValue2
            [void]$SQLiteCommand.Parameters.Add($DVP1)
        }

        $reader = $SQLiteCommand.ExecuteReader()
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