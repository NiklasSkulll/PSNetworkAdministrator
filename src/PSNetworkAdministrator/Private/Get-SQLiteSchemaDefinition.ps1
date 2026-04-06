function Get-SQLiteSchemaDefinition {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DataTableName,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== return the right database schema =====
    if ($DataTableName -eq "_DomainComputers_") {
        # database schema
        $DataSchema = @{
            Table = '_DomainComputers_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='ComputerName'; Type='TEXT'; Constraints='NOT NULL'}
                @{Name='DomainName'; Type='TEXT'; Constraints='NOT NULL'}
                @{Name='MacAddress'; Type='TEXT'}
                @{Name='ServerClientTag'; Type='TEXT'}
                @{Name='GroupTag'; Type='TEXT'}
            )
        }
        # database index definition
        $DataUniqueIndex = @{
            UX = 'UX_DomainComputers_DomainName_ComputerName'
            IndexNames = @(
                @{Name='ComputerName'}
                @{Name='DomainName'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerSystemInformations_") {
        # database schema
        $DataSchema = @{
            Table = '_ComputerSystemInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='ComputerSystemManufacturer'; Type='TEXT'}
                @{Name='ComputerSystemModel'; Type='TEXT'}
                @{Name='BIOSManufacturer'; Type='TEXT'}
                @{Name='BIOSSerialNumber'; Type='TEXT'}
                @{Name='SMBIOSBIOSVersion'; Type='TEXT'}
                @{Name='CPUGenerationName'; Type='TEXT'}
                @{Name='CPUReleaseDate'; Type='TEXT'}
                @{Name='CPUStillNewDate'; Type='TEXT'}
                @{Name='CPUMaxUsedDate'; Type='TEXT'}
            )
        }
        # database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerSystemInformations_DomainComputersID'
            IndexNames = @(
                @{Name='DomainComputersID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerOSInformations_") {
        # database schema
        $DataSchema = @{
            Table = '_ComputerOSInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='OSType'; Type='TEXT'}
                @{Name='OperatingSystem'; Type='TEXT'}
                @{Name='OperatingSystemVersion'; Type='TEXT'}
                @{Name='OSVersion'; Type='TEXT'}
                @{Name='OSArchitecture'; Type='TEXT'}
            )
        }
        # database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerOSInformations_DomainComputersID'
            IndexNames = @(
                @{Name='DomainComputersID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerADInformations_") {
        # database schema
        $DataSchema = @{
            Table = '_ComputerADInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='IsDomainController'; Type='INTEGER'}
                @{Name='MemberOf'; Type='TEXT'}
                @{Name='Enabled'; Type='INTEGER'}
                @{Name='InteractiveUser'; Type='TEXT'}
                @{Name='AdminListDirectMembers'; Type='TEXT'}
            )
        }
        # database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerADInformations_DomainComputersID'
            IndexNames = @(
                @{Name='DomainComputersID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerNetworkInformations_") {
        # database schema
        $DataSchema = @{
            Table = '_ComputerNetworkInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='IPv4Address'; Type='TEXT'}
                @{Name='SubnetMask'; Type='TEXT'}
                @{Name='DNSHostName'; Type='TEXT'}
                @{Name='UsesDHCP'; Type='INTEGER'}
                @{Name='UsesWINS'; Type='INTEGER'}
                @{Name='DNSResolve'; Type='INTEGER'}
                @{Name='WsManWinRM'; Type='INTEGER'}
                @{Name='TCPConnection'; Type='INTEGER'}
                @{Name='PingResponse'; Type='INTEGER'}
            )
        }
        # database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerNetworkInformations_DomainComputersID'
            IndexNames = @(
                @{Name='DomainComputersID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerAddInsInformations_") {
        # database schema
        $DataSchema = @{
            Table = '_ComputerAddInsInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='AddInID'; Type='INTEGER'}
                @{Name='AddInPassword'; Type='TEXT'}
            )
        }
        # database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerAddInsInformations_ID'
            IndexNames = @(
                @{Name='ID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerDCInformations_") {
        # database schema
        $DataSchema = @{
            Table = '_ComputerDCInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='ComputerADInformationsID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _ComputerADInformations_(ID)'}
                @{Name='FSMORoles'; Type='TEXT'}
                @{Name='GlobalCatalogs'; Type='TEXT'}
            )
        }
        # database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerDCInformations_ComputerADInformationsID'
            IndexNames = @(
                @{Name='ComputerADInformationsID'}
            )
        }
    }
    elseif ($DataTableName -eq "_DomainUsers_") {
        # database schema
        $DataSchema = @{
            Table = '_DomainUsers_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='UserName'; Type='TEXT'; Constraints='NOT NULL'}
                @{Name='DomainName'; Type='TEXT'; Constraints='NOT NULL'}
                @{Name='GroupTag'; Type='TEXT'}
            )
        }
        # database index definition
        $DataUniqueIndex = @{
            UX = 'UX_DomainUsers_DomainName_UserName'
            IndexNames = @(
                @{Name='UserName'}
                @{Name='DomainName'}
            )
        }
    }
    else {
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000006' -VariableName '$DataTableName' -VariableValue $DataTableName -Language $Language
        throw $ErrorMessage
    }

    return [PSCustomObject]@{
        DataSchema = $DataSchema
        DataUniqueIndex = $DataUniqueIndex
    }
}