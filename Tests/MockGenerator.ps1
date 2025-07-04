# MockGenerator.ps1
# This script provides common mock objects and functions for testing
# without having to create actual unit tests

# Load test setup first
. "$PSScriptRoot\TestSetup.ps1"

function New-MockADUser {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SamAccountName,
        
        [Parameter()]
        [string]$DisplayName = $SamAccountName,
        
        [Parameter()]
        [bool]$Enabled = $true,
        
        [Parameter()]
        [string]$Department = "IT",
        
        [Parameter()]
        [hashtable]$AdditionalProperties = @{}
    )
    
    $user = [PSCustomObject]@{
        SamAccountName = $SamAccountName
        Name = $DisplayName
        DisplayName = $DisplayName
        Enabled = $Enabled
        Department = $Department
        DistinguishedName = "CN=$DisplayName,OU=Users,DC=contoso,DC=test"
        ObjectClass = "user"
        ObjectGUID = [Guid]::NewGuid()
    }
    
    # Add any additional properties
    foreach ($key in $AdditionalProperties.Keys) {
        $user | Add-Member -MemberType NoteProperty -Name $key -Value $AdditionalProperties[$key]
    }
    
    return $user
}

function New-MockADComputer {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [bool]$Enabled = $true,
        
        [Parameter()]
        [string]$OperatingSystem = "Windows Server 2022",
        
        [Parameter()]
        [hashtable]$AdditionalProperties = @{}
    )
    
    $computer = [PSCustomObject]@{
        Name = $Name
        DNSHostName = "$Name.$script:TestDomain"
        Enabled = $Enabled
        OperatingSystem = $OperatingSystem
        DistinguishedName = "CN=$Name,OU=Computers,DC=contoso,DC=test"
        ObjectClass = "computer"
        ObjectGUID = [Guid]::NewGuid()
    }
    
    # Add any additional properties
    foreach ($key in $AdditionalProperties.Keys) {
        $computer | Add-Member -MemberType NoteProperty -Name $key -Value $AdditionalProperties[$key]
    }
    
    return $computer
}

function New-MockADGroup {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [string]$GroupCategory = "Security",
        
        [Parameter()]
        [string]$GroupScope = "Global",
        
        [Parameter()]
        [hashtable]$AdditionalProperties = @{}
    )
    
    $group = [PSCustomObject]@{
        Name = $Name
        GroupCategory = $GroupCategory
        GroupScope = $GroupScope
        DistinguishedName = "CN=$Name,OU=Groups,DC=contoso,DC=test"
        ObjectClass = "group"
        ObjectGUID = [Guid]::NewGuid()
    }
    
    # Add any additional properties
    foreach ($key in $AdditionalProperties.Keys) {
        $group | Add-Member -MemberType NoteProperty -Name $key -Value $AdditionalProperties[$key]
    }
    
    return $group
}

function New-MockDNSRecord {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [string]$RecordType = "A",
        
        [Parameter()]
        [string]$Data = "192.168.1.100",
        
        [Parameter()]
        [hashtable]$AdditionalProperties = @{}
    )
    
    $dnsRecord = [PSCustomObject]@{
        Name = $Name
        RecordType = $RecordType
        Data = $Data
        TimeToLive = [TimeSpan]::FromHours(1)
        Timestamp = Get-Date
    }
    
    # Add any additional properties
    foreach ($key in $AdditionalProperties.Keys) {
        $dnsRecord | Add-Member -MemberType NoteProperty -Name $key -Value $AdditionalProperties[$key]
    }
    
    return $dnsRecord
}

function New-MockDHCPScope {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScopeId,
        
        [Parameter()]
        [string]$Name = "Default Scope",
        
        [Parameter()]
        [string]$StartRange = "192.168.1.10",
        
        [Parameter()]
        [string]$EndRange = "192.168.1.254",
        
        [Parameter()]
        [string]$SubnetMask = "255.255.255.0",
        
        [Parameter()]
        [hashtable]$AdditionalProperties = @{}
    )
    
    $dhcpScope = [PSCustomObject]@{
        ScopeId = $ScopeId
        Name = $Name
        StartRange = $StartRange
        EndRange = $EndRange
        SubnetMask = $SubnetMask
        LeaseDuration = [TimeSpan]::FromDays(8)
        State = "Active"
    }
    
    # Add any additional properties
    foreach ($key in $AdditionalProperties.Keys) {
        $dhcpScope | Add-Member -MemberType NoteProperty -Name $key -Value $AdditionalProperties[$key]
    }
    
    return $dhcpScope
}

# Export mock generator functions
Export-ModuleMember -Function New-MockADUser, New-MockADComputer, New-MockADGroup, New-MockDNSRecord, New-MockDHCPScope
