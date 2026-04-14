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

    # ===== Check the function variables =====
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    $DataTableNameCheck = Test-FunctionVariables -Param $DataTableName -ParamName '$DataTableName' -Language $Language
    $DataObjectCheck = Test-FunctionVariables -Param $DataObject -ParamName '$DataObject' -Language $Language
    
    if (-not ($DomainNameCheck.Success) -or -not ($DataTableNameCheck.Success) -or -not ($DataObjectCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
        if (-not ($DataTableNameCheck.Success)) {$ErrorMessages += $DataTableNameCheck.Message}
        if (-not ($DataObjectCheck.Success)) {$ErrorMessages += $DataObjectCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }

    # ===== Check table and get schema =====
    try {
        $DataSchemaFull = Get-SQLiteSchemaDefinition -DataTableName $DataTableName -Language $Language
        $DataSchema = $DataSchemaFull.DataSchema
        $DataUniqueIndex = $DataSchemaFull.DataUniqueIndex
    }
    catch {
        $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000008' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }

    # ===== Check data schema content =====
    $DataSchemaFullCheck = Test-FunctionVariables -Param $DataSchemaFull -ParamName '$DataSchemaFull' -Language $Language
    if (-not ($DataSchemaFullCheck.Success)) {throw "$($DataSchemaFullCheck.Message)"}

    # ===== Initialize schema and return formatted schema properties =====
    try {
        # Validate $DataSchema
        $DataSchemaValidated = Test-SQLiteSchema -DataSchema $DataSchema -DataUniqueIndex $DataUniqueIndex -DataTableName $DataTableName -Language $Language

        # Store all column names with and without 'ID'
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

        # Join list with commas and format table name
        $DataTableColumnList = $DataTableColumnParts -join ", "
        $DataUniqueIndexList = $DataUniqueIndexParts -join ", "
        $AllColumnNamesWithoutIDList = ($AllColumnNamesWithoutID | ForEach-Object { '"' + $_ + '"' }) -join ', '

        $QuotedDataTableName = '"' + $DataSchemaValidated.Table + '"'
        $QuotedUX = '"' + $DataUniqueIndex.UX + '"'

        # Order the values of the $DataObject
        $DataValuesInOrder = Write-SQLiteSchemaValuesInOrder -DataObject $DataObject -AllColumnNamesWithoutID $AllColumnNamesWithoutID -DomainName $DomainName -Language $Language

        # Create a list of placeholders for the values
        $DataValuesInOrder = @($DataValuesInOrder)
        $CountDataValues = $DataValuesInOrder.Count

        if ($CountDataValues -eq 0) {
            $RefValue = Get-RefValue -VariableName '$DataValuesInOrder' -Language $Language
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000005' -RefValue $RefValue -Language $Language
            throw $ErrorMessage
        }

        $SQLParamName = "@DVP"
        $DataValuesPlaceholder = 0..($CountDataValues-1) | ForEach-Object { "$SQLParamName$_" }
        $DataValuePlaceholderList = $DataValuesPlaceholder -join ", "

        # Return important formatted schema
        return [pscustomobject]@{
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
        $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000009' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }
}