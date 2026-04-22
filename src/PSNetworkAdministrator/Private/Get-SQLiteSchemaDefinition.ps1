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

    # ===== Return the right database schema =====
    if ($DataTableName -eq "_DomainComputers_") {
        # Database schema
        $DataSchema = @{
            Table = '_DomainComputers_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='ComputerName'; Type='TEXT'; Constraints='NOT NULL'}
                @{Name='DomainName'; Type='TEXT'; Constraints='NOT NULL'}
                @{Name='GroupTag'; Type='TEXT'}
                @{Name='SystemEnvironmentTag'; Type='TEXT'}
                @{Name='UpdatedAtDate'; Type='TEXT'}
            )
        }
        # Database index definition
        $DataUniqueIndex = @{
            UX = 'UX_DomainComputers_DomainName_ComputerName'
            IndexNames = @(
                @{Name='ComputerName'}
                @{Name='DomainName'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerSystemInformations_") {
        # Database schema
        $DataSchema = @{
            Table = '_ComputerSystemInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='ComputerSystemManufacturer'; Type='TEXT'}
                @{Name='ComputerSystemModel'; Type='TEXT'}
                @{Name='ComputerSystemType'; Type='TEXT'}
                @{Name='BIOSManufacturer'; Type='TEXT'}
                @{Name='BIOSSerialNumber'; Type='TEXT'}
                @{Name='SMBIOSVersion'; Type='TEXT'}
                @{Name='CPUGenerationName'; Type='TEXT'}
                @{Name='CPUNumberOfCores'; Type='INTEGER'}
                @{Name='CPUNumberOfLogicalProcessors'; Type='INTEGER'}
                @{Name='CPUReleaseDate'; Type='TEXT'}
                @{Name='CPUStillNewDate'; Type='TEXT'}
                @{Name='CPUMaxUsedDate'; Type='TEXT'}
                @{Name='TotalPhysicalMemoryGB'; Type='REAL'}
                @{Name='TotalLocalStorageSizeGB'; Type='REAL'}
                @{Name='TotalLocalStorageFreeGB'; Type='REAL'}
                @{Name='TotalLocalStorageUsedGB'; Type='REAL'}
                @{Name='ObservationDate'; Type='TEXT'}
            )
        }
        # Database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerSystemInformations_DomainComputersID'
            IndexNames = @(
                @{Name='DomainComputersID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerOSInformations_") {
        # Database schema
        $DataSchema = @{
            Table = '_ComputerOSInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='OperatingSystem'; Type='TEXT'}
                @{Name='OperatingSystemVersion'; Type='TEXT'}
                @{Name='OSDisplayVersion'; Type='TEXT'}
                @{Name='OSArchitecture'; Type='TEXT'}
                @{Name='ObservationDate'; Type='TEXT'}
            )
        }
        # Database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerOSInformations_DomainComputersID'
            IndexNames = @(
                @{Name='DomainComputersID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerADInformations_") {
        # Database schema
        $DataSchema = @{
            Table = '_ComputerADInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='ComputerDomainRole'; Type='INTEGER'}
                @{Name='HostRole'; Type='TEXT'}
                @{Name='IsDomainController'; Type='INTEGER'}
                @{Name='MemberOf'; Type='TEXT'}
                @{Name='Enabled'; Type='INTEGER'}
                @{Name='ObservationDate'; Type='TEXT'}
            )
        }
        # Database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerADInformations_DomainComputersID'
            IndexNames = @(
                @{Name='DomainComputersID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerSystemUserInformations_") {
        # Database schema
        $DataSchema = @{
            Table = '_ComputerSystemUserInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='SystemUserName'; Type='TEXT'}
                @{Name='InteractiveUser'; Type='TEXT'}
                @{Name='AdminMembers'; Type='TEXT'}
                @{Name='ObservationDate'; Type='TEXT'}
            )
        }
        # Database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerSystemUserInformations_DomainComputersID'
            IndexNames = @(
                @{Name='DomainComputersID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerNetworkInformations_") {
        # Database schema
        $DataSchema = @{
            Table = '_ComputerNetworkInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='DNSHostName'; Type='TEXT'}
                @{Name='MacAddress'; Type='TEXT'}
                @{Name='IPv4Address'; Type='TEXT'}
                @{Name='SubnetMask'; Type='TEXT'}
                @{Name='UsesDHCP'; Type='INTEGER'}
                @{Name='ObservationDate'; Type='TEXT'}
            )
        }
        # Database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerNetworkInformations_DomainComputersID'
            IndexNames = @(
                @{Name='DomainComputersID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerConnectionInformations_") {
        # Database schema
        $DataSchema = @{
            Table = '_ComputerConnectionInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='DNSResolve'; Type='INTEGER'}
                @{Name='PingResponse'; Type='INTEGER'}
                @{Name='WsManWinRM'; Type='INTEGER'}
                @{Name='TCPConnection'; Type='INTEGER'}
                @{Name='ObservationDate'; Type='TEXT'}
            )
        }
        # Database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerConnectionInformations_DomainComputersID'
            IndexNames = @(
                @{Name='DomainComputersID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerAddInsInformations_") {
        # Database schema
        $DataSchema = @{
            Table = '_ComputerAddInsInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='DomainComputersID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _DomainComputers_(ID)'}
                @{Name='AddInName'; Type='TEXT'}
                @{Name='AddInPath'; Type='TEXT'}
                @{Name='AddInArgument'; Type='TEXT'}
                @{Name='AddInPassword'; Type='TEXT'}
                @{Name='ObservationDate'; Type='TEXT'}
            )
        }
        # Database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerAddInsInformations_ID'
            IndexNames = @(
                @{Name='ID'}
            )
        }
    }
    elseif ($DataTableName -eq "_ComputerDCInformations_") {
        # Database schema
        $DataSchema = @{
            Table = '_ComputerDCInformations_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='ComputerADInformationsID'; Type='INTEGER'; Constraints='NOT NULL REFERENCES _ComputerADInformations_(ID)'}
                @{Name='FSMORoles'; Type='TEXT'}
                @{Name='GlobalCatalogs'; Type='TEXT'}
                @{Name='ObservationDate'; Type='TEXT'}
            )
        }
        # Database index definition
        $DataUniqueIndex = @{
            UX = 'UX_ComputerDCInformations_ComputerADInformationsID'
            IndexNames = @(
                @{Name='ComputerADInformationsID'}
            )
        }
    }
    elseif ($DataTableName -eq "_DomainUsers_") {
        # Database schema
        $DataSchema = @{
            Table = '_DomainUsers_'
            Columns = @(
                @{Name='ID'; Type='INTEGER'; Constraints='PRIMARY KEY'}
                @{Name='UserName'; Type='TEXT'; Constraints='NOT NULL'}
                @{Name='DomainName'; Type='TEXT'; Constraints='NOT NULL'}
                @{Name='GroupTag'; Type='TEXT'}
                @{Name='ObservationDate'; Type='TEXT'}
            )
        }
        # Database index definition
        $DataUniqueIndex = @{
            UX = 'UX_DomainUsers_DomainName_UserName'
            IndexNames = @(
                @{Name='UserName'}
                @{Name='DomainName'}
            )
        }
    }
    else {
        $RefValue = Get-RefValue -VariableName '$DataTableName' -Value $DataTableName -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'VAx0000006' -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }

    # ===== Return the database schema =====
    return [pscustomobject]@{
        DataSchema = $DataSchema
        DataUniqueIndex = $DataUniqueIndex
    }
}