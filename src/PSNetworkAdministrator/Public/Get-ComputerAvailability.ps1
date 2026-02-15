function Get-ComputerAvailability {
    <#
    .SYNOPSIS
        Determines the network availability and manageability status of a remote computer.
    
    .DESCRIPTION
        The Get-ComputerAvailability function performs comprehensive availability checks on remote computers
        by combining ICMP ping tests and TCP port connectivity checks. It intelligently selects appropriate
        management ports based on the operating system and returns detailed status information including
        connectivity status, reason for the determination, and individual test results.
        
        The function prioritizes DNSHostName over IPv4Address for connection attempts and adapts port
        checking strategies based on the detected operating system (Windows, Linux, macOS).
    
    .PARAMETER ComputerName
        The computer name or identifier from Active Directory.
        This parameter is mandatory and is used primarily for logging and identification purposes.
    
    .PARAMETER DNSHostName
        The fully qualified domain name (FQDN) of the target computer.
        This parameter is mandatory and is the preferred connection target.
        If empty or whitespace, the function falls back to IPv4Address.
    
    .PARAMETER IPv4Address
        The IPv4 address of the target computer.
        This parameter is optional and serves as a fallback when DNSHostName is unavailable.
    
    .PARAMETER OperatingSystem
        The operating system of the target computer.
        This parameter is optional and is used to determine appropriate management ports:
        - Linux/Unix/macOS systems: Tests SSH (port 22)
        - Windows systems: Tests WinRM (5985), SMB (445), RDP (3389)
        - Unknown systems: Tests all common management ports
    
    .EXAMPLE
        Get-ComputerAvailability -ComputerName "WKS001" -DNSHostName "wks001.contoso.com" -OperatingSystem "Windows 11"
        
        Tests availability of a Windows workstation using its FQDN.
        Returns status object with Online/Offline status and detailed reason.

    .EXAMPLE
        $computer | Get-ComputerAvailability -ComputerName $_.Name -DNSHostName $_.DNSHostName -IPv4Address $_.IPv4 -OperatingSystem $_.OS
        
        Pipeline usage to check availability of multiple computers from Active Directory query results.
    
    .INPUTS
        None. This function does not accept pipeline input.
    
    .OUTPUTS
        PSCustomObject
        Returns an object containing:
        - ConnectionTarget: The hostname or IP address used for connectivity tests
        - Status: "Online", "Offline", or "Unknown"
        - Reason: Detailed explanation of the status determination
        - PingResult: Boolean indicating successful ICMP ping response
        - PortCheck: Boolean indicating at least one management port is open
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0
        Requires: PowerShell 7.0+, Test-TCPPortAvailability function, Write-AppLogging function
        
        This is a public function exported by the PSNetworkAdministrator module.
        
        Status Determination Logic:
        - "Online": Computer responds to ICMP ping OR at least one management port is open
        - "Offline": No ICMP response AND no management ports are accessible
        - "Unknown": Both DNSHostName and IPv4Address are empty/null/whitespace
        
        Port Testing Strategy by OS:
        - Linux/Unix/macOS: Port 22 (SSH)
        - Windows: Ports 5985 (WinRM), 445 (SMB), 3389 (RDP)
        - Unknown OS: All common ports (5985, 445, 22, 3389)
        
        Timeout Settings:
        - ICMP ping timeout: 1 second
        - TCP port check timeout: 800ms (per Test-TCPPortAvailability)
        
        Performance Considerations:
        - Port checks stop after first successful connection
        - Single ping attempt to minimize wait time
        - Fast failure for unreachable computers
        
        Network Requirements:
        - ICMP may be blocked by firewalls (function handles this gracefully)
        - At least one management port should be accessible for manageability confirmation
        - Function works across subnets and through most firewall configurations
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [string]$DNSHostName,
    
        [string]$IPv4Address,

        [string]$OperatingSystem
    )

    # checks if $DNSHostName is empty/null/whitespace, fallback to $IPv4Address
    $ConnectionTarget = if (-not [string]::IsNullOrWhiteSpace($DNSHostName)) {$DNSHostName} else {$IPv4Address}
    if ([string]::IsNullOrWhiteSpace($ConnectionTarget)) {
        Write-AppLogging -LoggingMessage "Empty DNSHostName or IPv4 address for '$ComputerName'." -LoggingLevel "Warning"
        return [PSCustomObject]@{
            ConnectionTarget = $ConnectionTarget
            Status = "Unknown"
            Reason = "Empty DNSHostName or IPv4 address for '$ComputerName'."
            PingResult = $false
            PortCheck = $false
        }
    }

    # ping the IPv4 address to check if the network is reachable
    try {
        $PingResult = Test-Connection -TargetName $ConnectionTarget -Quiet -Count 1 -TimeoutSeconds 1 -ErrorAction Stop
    }
    catch {
        $PingResult = $false
    }

    # define ports based on OS, fallback to a list
    $PortList = if ($OperatingSystem -match 'Linux|Ubuntu|Debian|Red Hat|CentOS|SUSE|macOS|OS X|Mac') {
        @(22)
    }
    elseif ($OperatingSystem -like '*Windows*') {
        @(5985, 445, 3389)
    }
    else {
        @(5985, 445, 22, 3389)
    }

    # check $PortList with Test-TCPPortAvailability to check if the computer is manageable
    $PortCheck = $false
    $OpenPort = $null
    foreach ($Port in $PortList) {
        if (Test-TCPPortAvailability -HostName $ConnectionTarget -Port $Port) {
            $PortCheck = $true
            $OpenPort = $Port
            break
        }
    }

    # define the availability of the computer (online/offline)
    $AvailabilityStatus = if ($PingResult -or $PortCheck) {"Online"} else {"Offline"}
    $Reason = if ($PingResult -and $PortCheck) {
        "Network is reachable and computer is manageable. ICMP reply and TCP port '$OpenPort' answered."
    }
    elseif ($PingResult) {
        "Network is reachable. ICMP reply."
    }
    elseif ($PortCheck) {
        "Computer is manageable. TCP port answered: $OpenPort"
    }
    else {
        "No ICMP reply and no TCP port answered."
    }
    
    return [PSCustomObject]@{
        ConnectionTarget = $ConnectionTarget
        Status = $AvailabilityStatus
        Reason = $Reason
        PingResult = $PingResult
        PortCheck = $PortCheck
    }
}