function Get-DomainComputers {
    <#
    .SYNOPSIS
        Retrieves all computers (servers and clients) from an Active Directory domain.
    
    .DESCRIPTION
        The Get-DomainComputers function queries Active Directory to retrieve all computer objects with detailed properties.
        It resolves DNS names to IP addresses and categorizes computers into servers, Windows clients, Linux clients,
        macOS clients, and unknown operating systems. The function uses parallel processing for efficient DNS resolution
        and returns a comprehensive inventory of all domain computers organized by type.
    
    .PARAMETER DomainName
        The fully qualified domain name (FQDN) of the Active Directory domain to query.
        This parameter is mandatory.
    
    .PARAMETER Credential
        A PSCredential object containing valid credentials for querying the Active Directory domain.
        The credentials must have sufficient permissions to read computer objects and their properties.
        This parameter is mandatory.
    
    .EXAMPLE
        $cred = Get-Credential
        Get-DomainComputers -DomainName "contoso.com" -Credential $cred
    
        Retrieves all computers from the contoso.com domain using the provided credentials.
    
    .EXAMPLE
        $computers = Get-DomainComputers -DomainName "contoso.com" -Credential $cred
        $computers.WindowsServers | Select-Object Name, IPv4Address, OperatingSystem
    
        Retrieves all computers and displays Windows server information including name, IP address, and OS.
    
    .INPUTS
        None. This function does not accept pipeline input.
    
    .OUTPUTS
        PSCustomObject
        Returns an object containing:
        - Domain: The domain name queried
        - WindowsServers: Array of Windows server computer objects (OS contains "Server")
        - LinuxServers: Array of Linux-based server computer objects (OS contains "Server")
        - MacosServers: Array of macOS server computer objects (OS contains "Server")
        - WindowsClients: Array of Windows client computer objects
        - LinuxClients: Array of Linux-based computer objects
        - MacosClients: Array of macOS computer objects
        - OtherComputers: Array of computers with unknown operating systems (no Windows, Linux or macOS)
        - UnknownComputers: Array of computers with whitespace or null operating systems
    
        Each computer object contains: Name, DNSHostName, IPv4Address, OperatingSystem, 
        OperatingSystemVersion, MemberOf, Enabled
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0.0
        Requires: PowerShell 7.0+, ActiveDirectory module, Write-AppLogging function
    
        This is a public function exported by the PSNetworkAdministrator module.
        The function uses parallel processing (ThrottleLimit: 50) for DNS resolution to improve performance.
        Requires network connectivity to the domain controllers and DNS servers.
        DNS resolution failures for individual computers are handled gracefully (returns $null for IPv4Address).
    
        Required AD Permissions: Read access to computer objects and their properties.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName,
    
        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )
    
    try {
        # get all computer objects from Domain with the properties: "OperatingSystem, OperatingSystemVersion, DNSHostName, Enabled, MemberOf and IPv4Address"
        $AllADComputer = Get-ADComputer -Server $DomainName -Credential $Credential -Filter * -Properties OperatingSystem, OperatingSystemVersion, DNSHostName, Enabled, MemberOf
        $AllADComputer = $AllADComputer | ForEach-Object -Parallel {
            [PSCustomObject]@{
                ComputerName = $_.Name
                DNSHostName = $_.DNSHostName
                IPv4Address = if ($_.DNSHostName) {
                    try {
                        (Resolve-DnsName -Name $_.DNSHostName -Type A -ErrorAction Stop | Where-Object {$_.IPAddress} | Select-Object -First 1).IPAddress
                    }
                    catch {
                        $null
                    }
                }
                OperatingSystem = $_.OperatingSystem
                OperatingSystemVersion = $_.OperatingSystemVersion
                MemberOf = $_.MemberOf
                Enabled = $_.Enabled
            }
        } -ThrottleLimit 50

        # separate "$AllADComputer" into servers (windows, linux, macOs)
        $WindowsServers = $AllADComputer | Where-Object {$_.OperatingSystem -like '*Server*' -and $_.OperatingSystem -like '*Windows*'}
        $LinuxServers = $AllADComputer | Where-Object {$_.OperatingSystem -like '*Server*' -and $_.OperatingSystem -match 'Linux|Ubuntu|Debian|Red Hat|CentOS|SUSE'}
        $MacosServers = $AllADComputer | Where-Object {$_.OperatingSystem -like '*Server*' -and $_.OperatingSystem -match 'Mac|OS X|macOS'}

        # separate "$AllADComputer" into clients (windows, linux, macOs)
        $WindowsClients = $AllADComputer | Where-Object {$_.OperatingSystem -like '*Windows*' -and $_.OperatingSystem -notlike '*Server*'}
        $LinuxClients = $AllADComputer | Where-Object {$_.OperatingSystem -match 'Linux|Ubuntu|Debian|Red Hat|CentOS|SUSE' -and $_.OperatingSystem -notlike '*Server*'}
        $MacosClients = $AllADComputer | Where-Object {$_.OperatingSystem -match 'Mac|OS X|macOS' -and $_.OperatingSystem -notlike '*Server*'}

        # collecting all unknown computer (unknown os and empty/whitespace "OperatingSystem-String")
        $OtherComputers = $AllADComputer | Where-Object {-not [string]::IsNullOrWhiteSpace($_.OperatingSystem) -and $_.OperatingSystem -notlike '*Windows*' -and $_.OperatingSystem -notmatch 'Linux|Ubuntu|Debian|Red Hat|CentOS|SUSE' -and $_.OperatingSystem -notmatch 'Mac|OS X|macOS'}
        $UnknownComputers = $AllADComputer | Where-Object {[string]::IsNullOrWhiteSpace($_.OperatingSystem)}

        return [PSCustomObject]@{
            Domain = $DomainName
            WindowsServers = $WindowsServers
            LinuxServers = $LinuxServers
            MacosServers = $MacosServers
            WindowsClients = $WindowsClients
            LinuxClients = $LinuxClients
            MacosClients = $MacosClients
            OtherComputers = $OtherComputers
            UnknownComputers = $UnknownComputers
        }
    }
    catch {
        Write-AppLogging -LoggingMessage "Failed to get the computers(clients/servers) for '$DomainName': $($_.Exception.Message)" -LoggingLevel "Error"
        throw "Failed to get the computers(clients/servers) for '$DomainName': $($_.Exception.Message)"
    }
}