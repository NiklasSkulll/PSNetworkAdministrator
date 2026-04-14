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

    # ===== Check the function variables =====
    $DataSchemaCheck = Test-FunctionVariables -Param $DataSchema -ParamName '$DataSchema' -Language $Language
    $DataUniqueIndexCheck = Test-FunctionVariables -Param $DataUniqueIndex -ParamName '$DataUniqueIndex' -Language $Language
    $DataTableNameCheck = Test-FunctionVariables -Param $DataTableName -ParamName '$DataTableName' -Language $Language

    if (-not ($DataSchemaCheck.Success) -or -not ($DataUniqueIndexCheck.Success) -or -not ($DataTableNameCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DataSchemaCheck.Success)) {$ErrorMessages += $DataSchemaCheck.Message}
        if (-not ($DataUniqueIndexCheck.Success)) {$ErrorMessages += $DataUniqueIndexCheck.Message}
        if (-not ($DataTableNameCheck.Success)) {$ErrorMessages += $DataTableNameCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }

    # ===== Define naming pattern (regex) and a list with allowed types =====
    $NamingPattern = '^[A-Za-z_][A-Za-z0-9_]*$'
    $AllowedTypes = @('INTEGER', 'TEXT', 'REAL', 'BLOB')

    # ===== Check if Table and Columns are available =====
    if (-not ($DataSchema.ContainsKey('Table')) -or -not ($DataSchema.ContainsKey('Columns'))) {
        $ErrorMessages = @()
        if (-not ($DataSchema.ContainsKey('Table'))) {
            $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'Table' -Language $Language
            $ErrorMessageTable = Get-ErrorMessages -ErrorCode 'DBx0000001' -RefValue $RefValue -Language $Language
            $ErrorMessages += $ErrorMessageTable
        }
        if (-not ($DataSchema.ContainsKey('Columns'))) {
            $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'Columns' -Language $Language
            $ErrorMessageColumn = Get-ErrorMessages -ErrorCode 'DBx0000001' -RefValue $RefValue -Language $Language
            $ErrorMessages += $ErrorMessageColumn
        }

        $ErrorMessage = $ErrorMessages -join '; '
        
        throw $ErrorMessage
    }

    # ===== Check if Columns are not empty =====
    if (-not $DataSchema.Columns -or $DataSchema.Columns.Count -eq 0) {
        $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'DataSchema.Columns' -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000002' -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }

    # ===== Check if Columns has Name and Type =====
    foreach ($DataColumn in $DataSchema.Columns) {
        if ([string]::IsNullOrWhiteSpace($DataColumn.Name) -or [string]::IsNullOrWhiteSpace($DataColumn.Type)) {
            $ErrorMessages = @()
            if ([string]::IsNullOrWhiteSpace($DataColumn.Name)) {
                $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'DataSchema.Columns.Name' -Language $Language
                $ErrorMessageColName = Get-ErrorMessages -ErrorCode 'DBx0000002' -RefValue $RefValue -Language $Language
                $ErrorMessages += $ErrorMessageColName
            }
            if ([string]::IsNullOrWhiteSpace($DataColumn.Type)) {
                $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'DataSchema.Columns.Type' -Language $Language
                $ErrorMessageColType = Get-ErrorMessages -ErrorCode 'DBx0000002' -RefValue $RefValue -Language $Language
                $ErrorMessages += $ErrorMessageColType
            }

            $ErrorMessage = $ErrorMessages -join '; '

            throw $ErrorMessage
        }
    }

    # ===== Check if UX and IndexNames are available =====
    if (-not ($DataUniqueIndex.ContainsKey('UX')) -or -not ($DataUniqueIndex.ContainsKey('IndexNames'))) {
        $ErrorMessages = @()
        if (-not ($DataUniqueIndex.ContainsKey('UX'))) {
            $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'UX' -Language $Language
            $ErrorMessageDataUniqUX = Get-ErrorMessages -ErrorCode 'DBx0000001' -RefValue $RefValue -Language $Language
            $ErrorMessages += $ErrorMessageDataUniqUX
        }
        if (-not ($DataUniqueIndex.ContainsKey('IndexNames'))) {
            $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'IndexNames' -Language $Language
            $ErrorMessageDataUniqIN = Get-ErrorMessages -ErrorCode 'DBx0000001' -RefValue $RefValue -Language $Language
            $ErrorMessages += $ErrorMessageDataUniqIN
        }

        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }

    # ===== Check if IndexNames are not empty =====
    if (-not $DataUniqueIndex.IndexNames -or $DataUniqueIndex.IndexNames.Count -eq 0) {
        $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'DataUniqueIndex.IndexNames' -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000002' -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }
    
    # ===== Check if IndexNames has Name =====
    foreach ($DataIndex in $DataUniqueIndex.IndexNames) {
        if ([string]::IsNullOrWhiteSpace($DataIndex.Name)) {
            $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'DataUniqueIndex.IndexNames.Name' -Language $Language
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000002' -RefValue $RefValue -Language $Language
            throw $ErrorMessage
        }
    }

    # ===== Check naming pattern for $DataSchema =====
    if ($DataSchema.Table -notmatch $NamingPattern) {
        $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'Table' -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000007' -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }

    foreach ($DataColumn in $DataSchema.Columns) {
        if ($DataColumn.Name -notmatch $NamingPattern) {
            $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'DataSchema.Columns.Name' -Language $Language
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000007' -RefValue $RefValue -Language $Language
            throw $ErrorMessage
        }
    }

    # ===== Check naming pattern for $DataUniqueIndex =====
    if ($DataUniqueIndex.UX -notmatch $NamingPattern) {
        $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'UX' -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000007' -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }

    foreach ($DataIndex in $DataUniqueIndex.IndexNames) {
        if ($DataIndex.Name -notmatch $NamingPattern) {
            $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'DataUniqueIndex.IndexNames.Name' -Language $Language
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000007' -RefValue $RefValue -Language $Language
            throw $ErrorMessage
        }
    }

    # ===== Validate if index columns exist in the schema =====
    $DataSchemaColumnNames = $DataSchema.Columns | ForEach-Object { $_.Name }
    foreach ($DataIndex in $DataUniqueIndex.IndexNames) {
        if ($DataIndex.Name -notin $DataSchemaColumnNames) {
            $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'DataUniqueIndex.IndexNames.Name' -Language $Language
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000004' -RefValue $RefValue -Language $Language
            throw $ErrorMessage
        }
    }

    # ===== Check duplicate names inside IndexNames =====
    $IndexNamesLowerCase = $DataUniqueIndex.IndexNames | ForEach-Object {$_.Name.ToLowerInvariant()}
    $DuplicateIndexNames = $IndexNamesLowerCase | Group-Object | Where-Object Count -gt 1
    if ($DuplicateIndexNames) {
        $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'DataUniqueIndex.IndexNames.Name' -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000003' -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }

    # ===== Check each column type and create a normalized schema =====
    $DataColumnNormalized = foreach ($DataColumn in $DataSchema.Columns) {
        $FormattedTypes = ($DataColumn.Type).Trim().ToUpperInvariant()

        if ($FormattedTypes -notin $AllowedTypes) {
            $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -AdditionalRef 'DataSchema.Columns.Type' -Language $Language
            $ErrorMessage = Get-ErrorMessages -ErrorCode 'DBx0000005' -RefValue $RefValue -Language $Language
            throw $ErrorMessage
        }

        @{
            Name = $DataColumn.Name
            Type = $FormattedTypes
            Constraints = $DataColumn.Constraints
        }
    }

    # ===== Create the output with the normalized schema =====
    $FunctionReturn = @{
        Table = $DataSchema.Table
        Columns = $DataColumnNormalized
    }

    # ===== Return normalized $DataSchema =====
    return $FunctionReturn
}