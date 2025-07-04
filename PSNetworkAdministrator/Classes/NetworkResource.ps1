# NetworkResource.ps1
# Class definitions for network resources

<#
.SYNOPSIS
    Defines custom classes for network resources.

.DESCRIPTION
    This file contains class definitions for various network resources
    used throughout the PSNetworkAdministrator module, including
    ADObject, ADComputer, ADUser, and DNSRecord classes.

.NOTES
    These classes provide a consistent object model for working with
    network resources across different module functions.
#>

# Base class for all AD objects
class ADObject {
    # Common properties for all AD objects
    [string]$Name
    [string]$DistinguishedName
    [guid]$ObjectGUID
    [datetime]$Created
    [datetime]$Modified
    
    # Constructor with minimal required properties
    ADObject([string]$Name, [string]$DistinguishedName) {
        $this.Name = $Name
        $this.DistinguishedName = $DistinguishedName
        $this.ObjectGUID = [guid]::NewGuid()  # In a real implementation, this would come from AD
        $this.Created = Get-Date
        $this.Modified = $this.Created
    }
    
    # Virtual method to be overridden by child classes
    [string] ToString() {
        return $this.Name
    }
}

# Computer object in Active Directory
class ADComputer : ADObject {
    # Computer-specific properties
    [string]$DNSHostName
    [string]$OperatingSystem
    [bool]$Enabled = $true
    [datetime]$LastLogon
    
    # Constructor with required properties
    ADComputer([string]$Name, [string]$DNSHostName, [string]$Domain) : base($Name, "CN=$Name,OU=Computers,DC=$($Domain.Replace('.', ',DC='))") {
        $this.DNSHostName = $DNSHostName
        
        # Default the last logon to never (represented by the minimum DateTime value)
        # This clearly indicates a computer that has never logged in to the domain
        $this.LastLogon = [datetime]::MinValue
    }
    
    # Override ToString to provide more meaningful output
    [string] ToString() {
        return "$($this.Name) ($($this.DNSHostName))"
    }
    
    # Method to update the last logon time
    [void] UpdateLastLogon() {
        $this.LastLogon = Get-Date
        $this.Modified = $this.LastLogon
    }
}

# User object in Active Directory
class ADUser : ADObject {
    # User-specific properties
    [string]$SamAccountName
    [string]$UserPrincipalName
    [string]$DisplayName
    [string]$Department
    [bool]$Enabled = $true
    [datetime]$LastLogon
    [string[]]$MemberOf = @()
    
    # Constructor with required properties
    ADUser([string]$SamAccountName, [string]$DisplayName, [string]$Domain) : base($SamAccountName, "CN=$DisplayName,OU=Users,DC=$($Domain.Replace('.', ',DC='))") {
        $this.SamAccountName = $SamAccountName
        $this.DisplayName = $DisplayName
        $this.UserPrincipalName = "$SamAccountName@$Domain"
        
        # Default the last logon to never
        $this.LastLogon = [datetime]::MinValue
    }
    
    # Override ToString to provide more meaningful output
    [string] ToString() {
        return "$($this.DisplayName) ($($this.SamAccountName))"
    }
    
    # Method to update the last logon time
    [void] UpdateLastLogon() {
        $this.LastLogon = Get-Date
        $this.Modified = $this.LastLogon
    }
    
    # Method to add group membership
    [void] AddGroupMembership([string]$GroupName) {
        # Check if user is already a member of the group
        if ($this.MemberOf -notcontains $GroupName) {
            $this.MemberOf += $GroupName
            $this.Modified = Get-Date
        }
    }
    
    # Method to remove group membership
    [void] RemoveGroupMembership([string]$GroupName) {
        $this.MemberOf = $this.MemberOf | Where-Object { $_ -ne $GroupName }
        $this.Modified = Get-Date
    }
}

# DNS Record
class DNSRecord {
    [string]$Name
    [string]$RecordType
    [string]$Data
    [TimeSpan]$TimeToLive
    [datetime]$Timestamp
    [string]$ZoneName
    
    # Constructor with required properties
    DNSRecord([string]$Name, [string]$RecordType, [string]$Data, [string]$ZoneName) {
        $this.Name = $Name
        $this.RecordType = $RecordType
        $this.Data = $Data
        $this.ZoneName = $ZoneName
        $this.TimeToLive = [TimeSpan]::FromHours(1)  # Default TTL
        $this.Timestamp = Get-Date
    }
    
    # Constructor with all properties
    DNSRecord([string]$Name, [string]$RecordType, [string]$Data, [string]$ZoneName, [TimeSpan]$TimeToLive) {
        $this.Name = $Name
        $this.RecordType = $RecordType
        $this.Data = $Data
        $this.ZoneName = $ZoneName
        $this.TimeToLive = $TimeToLive
        $this.Timestamp = Get-Date
    }
    
    # Return the FQDN of this record
    [string] GetFQDN() {
        if ($this.Name -eq "@") {
            return $this.ZoneName
        }
        return "$($this.Name).$($this.ZoneName)"
    }
    
    # Override ToString to provide more meaningful output
    [string] ToString() {
        return "$($this.GetFQDN()) ($($this.RecordType)) -> $($this.Data)"
    }
}
