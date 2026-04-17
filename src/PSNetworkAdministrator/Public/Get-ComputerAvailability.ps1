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
        Version: 1.0.0
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
        [string]$DomainName,
        
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [string]$DNSHostName,

        [Parameter(Mandatory)]
        [string]$IPv4Address,

        [string]$OperatingSystem,

        [string]$SystemEnvironmentTag,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== Check the function variables =====
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    $ComputerNameCheck = Test-FunctionVariables -Param $ComputerName -ParamName '$ComputerName' -Language $Language
    $DNSHostNameCheck = Test-FunctionVariables -Param $DNSHostName -ParamName '$DNSHostName' -Language $Language
    $IPv4AddressCheck = Test-FunctionVariables -Param $IPv4Address -ParamName '$IPv4Address' -Language $Language

    if (-not ($DomainNameCheck.Success) -or -not ($ComputerNameCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
        if (-not ($ComputerNameCheck.Success)) {$ErrorMessages += $ComputerNameCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }

    # ===== Define the connection target =====
    $ConnectionTarget = if ($DNSHostNameCheck.Success) {$DNSHostName} else {"$ComputerName.$DomainName"}

    # ===== Check if the DNS name of $ConnectionTarget is resolvable =====
    $DNSResolve = if (Resolve-DnsName -Name $ConnectionTarget -ErrorAction SilentlyContinue) {$true} else {$false}

    # ===== Redefine $ConnectionTarget if $DNSResolve is $false =====
    $ConnectionTarget = if ($DNSResolve) {
        $ConnectionTarget
    }
    else {
        if ($IPv4AddressCheck.Success) {$IPv4Address} else {$ConnectionTarget}
    }

    # ===== Check if $ConnectionTarget is reachable via ping =====
    $PingResponse = if (Test-Connection -TargetName $ConnectionTarget -Quiet -Count 1 -TimeoutSeconds 1 -ErrorAction SilentlyContinue) {$true} else {$false}

    # ===== Check if $ConnectionTarget is reachable via WSMan/WinRM =====
    $WsManWinRM = if (Test-WSMan -ComputerName $ConnectionTarget -ErrorAction SilentlyContinue) {$true} else {$false}

    # ===== Define ports based on OS (fallback to a list) =====
    $PortList = if ($OperatingSystem -match 'Linux|Ubuntu|Debian|Red Hat|CentOS|SUSE|macOS|OS X|Mac') {
        @(22)
    }
    elseif ($OperatingSystem -like '*Windows*') {
        @(5985, 445, 3389)
    }
    else {
        @(5985, 445, 22, 3389)
    }

    # ===== Check $PortList with Test-TCPPortAvailability to check if the computer is manageable =====
    $TCPConnection = $false
    $OpenPort = $null
    foreach ($Port in $PortList) {
        if (Test-TCPPortAvailability -DNSHostName $ConnectionTarget -Port $Port -Language $Language) {
            $TCPConnection = $true
            $OpenPort = $Port
            break
        }
    }

    # ===== Define the availability of the computer =====
    $AvailabilityStatus = if ($PingResponse -or $WsManWinRM -or $TCPConnection) {'Online'} else {'Offline'}

    # ===== Define the availability message =====
    $AvailabilityMessage = if (-not $DNSResolve -or -not $PingResponse -or -not $WsManWinRM -or -not $TCPConnection) {
        $Messages = @()
        $RefValue = Get-RefValue -DomainName $DomainName -ComputerName $ComputerName -Language $Language
        if ($DNSResolve) {
            $Message = Get-ErrorMessages -ErrorCode 'COx0000001' -RefValue $RefValue -Language $Language
            $Messages += $Message
        }
        if ($PingResponse) {
            $Message = Get-ErrorMessages -ErrorCode 'COx0000004' -RefValue $RefValue -Language $Language
            $Messages += $Message
        }
        if ($WsManWinRM) {
            $Message = Get-ErrorMessages -ErrorCode 'COx0000002' -RefValue $RefValue -Language $Language
            $Messages += $Message
        }
        if ($TCPConnection) {
            $RefValue = Get-RefValue -DomainName $DomainName -ComputerName $ComputerName -AdditionalRef "$OpenPort" -Language $Language
            $Message = Get-ErrorMessages -ErrorCode 'COx0000003' -RefValue $RefValue -Language $Language
            $Messages += $Message
        }
        $Messages -join '; '
    }
    else {
        $RefValue = Get-RefValue -DomainName $DomainName -ComputerName $ComputerName -Language $Language
        $Message = 'Connection and DNS resolve was successful'
        "$Message | Ref=$RefValue"
    }

    # ===== Write logging message for produktive computers =====
    if (-not $PingResponse -and -not $WsManWinRM -and -not $TCPConnection) {
        if ($SystemEnvironmentTag -eq "PRD") {Write-AppLogging -LoggingMessage $AvailabilityMessage -LoggingLevel 'Error' -Language $Language}
    }

    return [pscustomobject]@{
        ConnectionTarget = $ConnectionTarget
        AvailabilityStatus = $AvailabilityStatus
        AvailabilityMessage = $AvailabilityMessage
        DNSResolve = $DNSResolve
        PingResponse = $PingResponse
        WsManWinRM = $WsManWinRM
        TCPConnection = $TCPConnection
    }
}