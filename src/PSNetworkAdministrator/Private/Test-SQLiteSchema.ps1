function Test-SQLiteSchema {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$DataSchema,

        [Parameter(Mandatory)]
        [hashtable]$DataUniqueIndex,

        [Parameter(Mandatory)]
        [string]$DataTableName,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # === validate input ===
    $DataSchemaCheck = Test-FunctionVariables -Param $DataSchema -ParamName '$DataSchema' -Language $Language
    $DataUniqueIndexCheck = Test-FunctionVariables -Param $DataUniqueIndex -ParamName '$DataUniqueIndex' -Language $Language
    $DataTableNameCheck = Test-FunctionVariables -Param $DataTableName -ParamName '$DataTableName' -Language $Language

    if (-not ($DataSchemaCheck.Success) -or -not ($DataUniqueIndexCheck.Success) -or -not ($DataTableNameCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DataSchemaCheck.Success)) {$ErrorMessages += $DataSchemaCheck.Message}
        if (-not ($DataUniqueIndexCheck.Success)) {$ErrorMessages += $DataUniqueIndexCheck.Message}
        if (-not ($DataTableNameCheck.Success)) {$ErrorMessages += $DataTableNameCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join ' || '

        throw $ErrorMessage
    }

    # === define naming pattern (regex) and a list with allowed types ===
    $NamingPattern = '^[A-Za-z_][A-Za-z0-9_]*$'
    $AllowedTypes = @('INTEGER', 'TEXT', 'REAL', 'BLOB')

    # === check if Table, Columns, Name and Type are available ===
    if (-not ($DataSchema.ContainsKey('Table')) -or -not ($DataSchema.ContainsKey('Columns'))) {
        $ErrorMessages = @()
        if (-not ($DataSchema.ContainsKey('Table'))) {
            $ErrorMessageTables = Get-ErrorMessages -ErrorCode 'DBx0000001' -VariableName '$DataSchema' -VariableValue $DataTableName -Language $Language
            $ErrorMessages += $ErrorMessageTables
        }
        if (-not ($DataSchema.ContainsKey('Columns'))) {
            $ErrorMessageColumns = Get-ErrorMessages -ErrorCode 'DBx0000002' -VariableName '$DataSchema' -VariableValue $DataTableName -Language $Language
            $ErrorMessages += $ErrorMessageColumns
        }

        $ErrorMessage = $ErrorMessages -join ' || '
        
        throw $ErrorMessage
    }

    if (-not $DataSchema.Columns -or $DataSchema.Columns.Count -eq 0) {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000003' -VariableName '$DataSchema.Columns' -VariableValue $DataTableName -Language $Language
        throw $ErrorMessage
    }

    foreach ($DataColumn in $DataSchema.Columns) {
        if ([string]::IsNullOrWhiteSpace($DataColumn.Name) -or [string]::IsNullOrWhiteSpace($DataColumn.Type)) {
            $ErrorMessages = @()
            if ([string]::IsNullOrWhiteSpace($DataColumn.Name)) {
                $ErrorMessageColName = Get-ErrorMessages -ErrorCode 'DBx0000004' -VariableName '$DataColumn.Name' -VariableValue $DataTableName -Language $Language
                $ErrorMessages += $ErrorMessageColName
            }
            if ([string]::IsNullOrWhiteSpace($DataColumn.Type)) {
                $ErrorMessageColType = Get-ErrorMessages -ErrorCode 'DBx0000005' -VariableName '$DataColumn.Type' -VariableValue $DataTableName -Language $Language
                $ErrorMessages += $ErrorMessageColType
            }

            $ErrorMessage = $ErrorMessages -join ' || '

            throw $ErrorMessage
        }
    }

    # === check if UX, IndexNames and Name are available and if index isn't just ID ===
    if (-not ($DataUniqueIndex.ContainsKey('UX')) -or -not ($DataUniqueIndex.ContainsKey('IndexNames'))) {
        $ErrorMessages = @()
        if (-not ($DataUniqueIndex.ContainsKey('UX'))) {
            $ErrorMessageDataUniqUX = Get-ErrorMessages -ErrorCode 'DBx0000006' -VariableName '$DataUniqueIndex' -VariableValue $DataTableName -Language $Language
            $ErrorMessages += $ErrorMessageDataUniqUX
        }
        if (-not ($DataUniqueIndex.ContainsKey('IndexNames'))) {
            $ErrorMessageDataUniqIN = Get-ErrorMessages -ErrorCode 'DBx0000007' -VariableName '$DataUniqueIndex' -VariableValue $DataTableName -Language $Language
            $ErrorMessages += $ErrorMessageDataUniqIN
        }

        $ErrorMessage = $ErrorMessages -join ' || '

        throw $ErrorMessage
    }

    if (-not $DataUniqueIndex.IndexNames -or $DataUniqueIndex.IndexNames.Count -eq 0) {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000008' -VariableName '$DataUniqueIndex.IndexNames' -VariableValue $DataTableName -Language $Language
        throw $ErrorMessage
    }
    
    foreach ($DataIndex in $DataUniqueIndex.IndexNames) {
        if ([string]::IsNullOrWhiteSpace($DataIndex.Name)) {
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000009' -VariableName '$DataIndex.Name' -VariableValue $DataTableName -Language $Language
            throw $ErrorMessage
        }
    }

    # === check naming pattern for $DataSchema ===
    if ($DataSchema.Table -notmatch $NamingPattern) {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000007' -VariableName '$DataSchema.Table' -VariableValue $DataTableName -Language $Language
        throw $ErrorMessage
    }
    foreach ($DataColumn in $DataSchema.Columns) {
        if ($DataColumn.Name -notmatch $NamingPattern) {
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000007' -VariableName '$DataColumn.Name' -VariableValue $DataTableName -Language $Language
            throw $ErrorMessage
        }
    }

    # === check naming pattern for $DataUniqueIndex ===
    if ($DataUniqueIndex.UX -notmatch $NamingPattern) {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000007' -VariableName '$DataUniqueIndex.UX' -VariableValue $DataTableName -Language $Language
        throw $ErrorMessage
    }
    foreach ($DataIndex in $DataUniqueIndex.IndexNames) {
        if ($DataIndex.Name -notmatch $NamingPattern) {
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000007' -VariableName '$DataIndex.Name' -VariableValue $DataTableName -Language $Language
            throw $ErrorMessage
        }
    }

    # === validate if index columns exist in the schema ===
    $DataSchemaColumnNames = $DataSchema.Columns | ForEach-Object { $_.Name }
    foreach ($DataIndex in $DataUniqueIndex.IndexNames) {
        if ($DataIndex.Name -notin $DataSchemaColumnNames) {
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000010' -VariableName '$DataIndex.Name' -VariableValue $DataTableName -Language $Language
            throw $ErrorMessage
        }
    }

    # === check duplicate names inside IndexNames ===
    $IndexNamesLowerCase = $DataUniqueIndex.IndexNames | ForEach-Object {$_.Name.ToLowerInvariant()}
    $DuplicateIndexNames = $IndexNamesLowerCase | Group-Object | Where-Object Count -gt 1
    if ($DuplicateIndexNames) {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000011' -VariableName '$DataUniqueIndex.IndexNames' -VariableValue $DataTableName -Language $Language
        throw $ErrorMessage
    }

    # === check each column type ===
    $DataColumnNormalized = foreach ($DataColumn in $DataSchema.Columns) {
        $FormattedTypes = ($DataColumn.Type).Trim().ToUpperInvariant()

        if ($FormattedTypes -notin $AllowedTypes) {
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000012' -VariableName '$DataSchema.Columns' -VariableValue $DataTableName -Language $Language
            throw $ErrorMessage
        }

        @{
            Name = $DataColumn.Name
            Type = $FormattedTypes
            Constraints = $DataColumn.Constraints
        }
    }

    $FunctionReturn = @{
        Table = $DataSchema.Table
        Columns = $DataColumnNormalized
    }

    # return normalized $DataSchema
    return $FunctionReturn
}