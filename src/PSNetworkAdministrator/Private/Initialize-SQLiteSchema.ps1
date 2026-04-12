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
        [pscustomobject]$DataObject,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== check function parameter =====
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    $DataTableNameCheck = Test-FunctionVariables -Param $DataTableName -ParamName '$DataTableName' -Language $Language
    $DataObjectCheck = Test-FunctionVariables -Param $DataObject -ParamName '$DataObject' -Language $Language
    
    if (-not ($DomainNameCheck.Success) -or -not ($DataTableNameCheck.Success) -or -not ($DataObjectCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
        if (-not ($DataTableNameCheck.Success)) {$ErrorMessages += $DataTableNameCheck.Message}
        if (-not ($DataObjectCheck.Success)) {$ErrorMessages += $DataObjectCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join ' || '

        throw $ErrorMessage
    }

    # ===== check table and get schema =====
    try {
        $DataSchemaFull = Get-SQLiteSchemaDefinition -DataTableName $DataTableName -Language $Language
        $DataSchema = $DataSchemaFull.DataSchema
        $DataUniqueIndex = $DataSchemaFull.DataUniqueIndex
    }
    catch {
        throw "$($_.Exception.Message)"
    }

    # ===== check data schema content =====
    $DataSchemaFullCheck = Test-FunctionVariables -Param $DataSchemaFull -ParamName '$DataSchemaFull' -Language $Language
    if (-not ($DataSchemaFullCheck.Success)) {throw "$($DataSchemaFullCheck.Message)"}

    try {
        # validate $DataSchema
        $DataSchemaValidated = Test-SQLiteSchema -DataSchema $DataSchema -DataUniqueIndex $DataUniqueIndex -DataTableName $DataTableName -Language $Language

        # store all column names with and without 'ID'
        $AllColumnNames = $DataSchemaValidated.Columns | ForEach-Object {$_.Name}
        $AllColumnNamesWithoutID = $AllColumnNames | Where-Object {$_ -ne 'ID'}

        # Build a list from $DataSchemaValidated.Columns
        $DataTableColumnParts = foreach ($DataColumn in $DataSchemaValidated.Columns) {
            $ColumnName = '"' + $DataColumn.Name + '"'
            $ColumnDefinition  = "$ColumnName $($DataColumn.Type)"

            if ($DataColumn.ContainsKey('Constraints') -and -not [string]::IsNullOrWhiteSpace($DataColumn.Constraints)) {$ColumnDefinition += " $($DataColumn.Constraints)"}

            $ColumnDefinition
        }

        # Build a list from $DataUniqueIndex with quotes
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
        $DataValuesInOrder = Write-SQLiteSchemaValuesInOrder -DataObject $DataObject -AllColumnNamesWithoutID $AllColumnNamesWithoutID -DomainName $DomainName -Language $Language

        # create a list of placeholders for the values
        $DataValuesInOrder = @($DataValuesInOrder)
        $CountDataValues = $DataValuesInOrder.Count

        if ($CountDataValues -eq 0) {
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000005' -VariableName '$DataValuesInOrder' -Language $Language
            throw $ErrorMessage
        }

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
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'INx0000003' -ExceptionMessage "$($_.Exception.Message)" -DomainName $DomainName -VariableName '$DataTableName' -VariableValue $DataTableName -Language $Language
        throw $ErrorMessage
    }
}