function Get-SQLiteSchemaDefinition {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DataTableName
    )

    # === return the right Schema ===
    if ($DataTableName -eq "_DomainComputers_") {
        $DataSchema = @{
            Table = '_DomainComputers_'
            Columns = @(
                @{Name='Id'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainName'; Type='TEXT'; Constraints='NOT NULL'}
                @{Name='ComputerName'; Type='TEXT'; Constraints='NOT NULL'}
                @{Name='DNSHostName'; Type='TEXT'}
                @{Name='IPv4Address'; Type='TEXT'}
                @{Name='OperatingSystem'; Type='TEXT'}
                @{Name='OperatingSystemVersion'; Type='TEXT'}
                @{Name='MemberOf'; Type='TEXT'}
                @{Name='Enabled'; Type='INTEGER'}
            )
        }
        $DataUniqueIndex = @{
            UX = 'UX_DomainComputers_DomainName_ComputerName'
            IndexNames = @(
                @{Name='DomainName'}
                @{Name='ComputerName'}
            )
        }
        return [PSCustomObject]@{
            DataSchema = $DataSchema
            DataUniqueIndex = $DataUniqueIndex
        }
    }
    else {
        throw "Unknown table name: $DataTableName"
    }
}