function Test-SQLiteSchema {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$DataSchema,

        [Parameter(Mandatory)]
        [hashtable]$DataUniqueIndex
    )

    # === validate input ===
    $DataSchemaIsNotEmpty = Test-FunctionVariables -Param $DataSchema
    $DataUniqueIndexIsNotEmpty = Test-FunctionVariables -Param $DataUniqueIndex
    if (-not $DataSchemaIsNotEmpty -or -not $DataUniqueIndexIsNotEmpty) {throw "Schema/Index is null/empty."}

    # === define naming pattern (regex) and a list with allowed types ===
    $NamingPattern = '^[A-Za-z_][A-Za-z0-9_]*$'
    $AllowedTypes = @('INTEGER', 'TEXT', 'REAL', 'BLOB')

    # === check if Table, Columns, Name and Type are available ===
    if (-not $DataSchema.ContainsKey('Table') -or -not $DataSchema.ContainsKey('Columns')) {throw "Schema missing Table/Columns."}
    if (-not $DataSchema.Columns -or $DataSchema.Columns.Count -eq 0) {throw "Columns are empty."}
    foreach ($DataColumn in $DataSchema.Columns) {
        if ([string]::IsNullOrWhiteSpace($DataColumn.Name) -or [string]::IsNullOrWhiteSpace($DataColumn.Type)) {
            throw "Column missing Name/Type."
        }
    }

    # === check if UX, IndexNames and Name are available and if index isn't just ID ===
    if (-not $DataUniqueIndex.ContainsKey('UX') -or -not $DataUniqueIndex.ContainsKey('IndexNames')) {throw "Index missing UX/IndexNames."}
    if (-not $DataUniqueIndex.IndexNames -or $DataUniqueIndex.IndexNames.Count -eq 0) {throw "IndexNames are empty."}
    if ($DataUniqueIndex.IndexNames.Name -eq 'Id' -or ($DataUniqueIndex.IndexNames | Where-Object Name -ne 'Id').Count -eq 0) {throw "Unique index must include at least one column other than 'Id'."}
    foreach ($DataIndex in $DataUniqueIndex.IndexNames) {
        if ([string]::IsNullOrWhiteSpace($DataIndex.Name)) {
            throw "IndexName missing Name."
        }
    }

    # === check naming pattern for $DataSchema ===
    if ($DataSchema.Table -notmatch $NamingPattern) {
        throw "Invalid table name in schema: '$($DataSchema.Table)'. Allowed: letters/numbers/_ and shouldn't start with a number."
    }
    foreach ($DataColumn in $DataSchema.Columns) {
        if ($DataColumn.Name -notmatch $NamingPattern) {
            throw "Invalid column name in schema: '$($DataColumn.Name)'. Allowed: letters/numbers/_ and shouldn't start with a number."
        }
    }

    # === check naming pattern for $DataUniqueIndex ===
    if ($DataUniqueIndex.UX -notmatch $NamingPattern) {
        throw "Invalid UX name in index: '$($DataUniqueIndex.UX)'. Allowed: letters/numbers/_ and shouldn't start with a number."
    }
    foreach ($DataIndex in $DataUniqueIndex.IndexNames) {
        if ($DataIndex.Name -notmatch $NamingPattern) {
            throw "Invalid column name in schema: '$($DataIndex.Name)'. Allowed: letters/numbers/_ and shouldn't start with a number."
        }
    }

    # === validate if index columns exist in the schema ===
    $DataSchemaColumnNames = $DataSchema.Columns | ForEach-Object { $_.Name }
    foreach ($DataIndex in $DataUniqueIndex.IndexNames) {
        if ($DataIndex.Name -notin $DataSchemaColumnNames) {
            throw "Index column '$($DataIndex.Name)' is not defined in schema columns: $($DataSchemaColumnNames -join ', ')"
        }
    }

    # === check duplicate names inside IndexNames ===
    $IndexNamesLowerCase = $DataUniqueIndex.IndexNames | ForEach-Object {$_.Name.ToLowerInvariant()}
    $DuplicateIndexNames = $IndexNamesLowerCase | Group-Object | Where-Object Count -gt 1
    if ($DuplicateIndexNames) {throw "IndexNames contains duplicates: $($DuplicateIndexNames.Name -join ', ')"}

    # === check each column type ===
    $DataColumnNormalized = foreach ($DataColumn in $DataSchema.Columns) {
        $FormattedTypes = ($DataColumn.Type).Trim().ToUpperInvariant()

        if ($FormattedTypes -notin $AllowedTypes) {
            throw "Invalid SQLite type for column '$($DataColumn.Name)': '$($DataColumn.Type)'. Allowed types: $($AllowedTypes -join ', ')"
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