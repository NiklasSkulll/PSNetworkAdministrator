function Add-DomainComputers {
    <#
    .SYNOPSIS
        Adds computers (server) to PSNetworkAdministrator.
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
                Name = $_.Name
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

        # separate "$AllADComputer" into servers
        $ADServers = $AllADComputer | Where-Object {$_.OperatingSystem -like '*Server*'}

        # separate "$AllADComputer" into clients (windows, linux, macOs, unknown)
        $WindowsClients = $AllADComputer | Where-Object {$_.OperatingSystem -like '*Windows*' -and $_.OperatingSystem -notlike '*Server*'}
        $LinuxClients = $AllADComputer | Where-Object {$_.OperatingSystem -match 'Linux|Ubuntu|Debian|Red Hat|CentOS|SUSE'}
        $MacosClients = $AllADComputer | Where-Object {$_.OperatingSystem -match 'Mac|OS X|macOS'}
        $UnknownClients = $AllADComputer | Where-Object {[string]::IsNullOrWhiteSpace($_.OperatingSystem)}

        return [PSCustomObject]@{
            Domain = $DomainName
            Servers = $ADServers
            WindowsClients = $WindowsClients
            LinuxClients = $LinuxClients
            MacosClients = $MacosClients
            UnknownClients = $UnknownClients
        }
    }
    catch {
        Write-AppLogging -LoggingMessage "Failed to get the Computers(Clients/Servers) for '$DomainName': $($_.Exception.Message)" -LoggingLevel "Error"
        throw "Failed to get the Computers(Clients/Servers) for '$DomainName': $($_.Exception.Message)"
    }
}