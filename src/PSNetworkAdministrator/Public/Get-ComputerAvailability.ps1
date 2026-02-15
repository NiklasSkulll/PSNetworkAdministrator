function Get-ComputerAvailability {
    <#

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DNSHostName,
    
        [string]$IPv4Address,

        [string]$OperatingSystem
    )

    # checks if $DNSHostName is empty/null/whitespace, fallback to $IPv4Address
    $ConnectionTarget = if (-not [string]::IsNullOrWhiteSpace($DNSHostName)) {$DNSHostName} else {$IPv4Address}
    if ([string]::IsNullOrWhiteSpace($ConnectionTarget)) {
        return [PSCustomObject]@{
            ConnectionTarget = $ConnectionTarget
            Status = "Unknown"
            Reason = "Empty DNSHostName or IPv4 address"
            IPv4Ping = $false
            PortCheck = $false
        }
    }

    # ping the IPv4 address to check if the network is reachable
    try {
        $IPv4Ping = Test-Connection -TargetName $ConnectionTarget -Quiet -Count 1 -TimeoutSeconds 1 -ErrorAction Stop
    }
    catch {
        $IPv4Ping = $false
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
    $AvailabilityStatus = if ($IPv4Ping -or $PortCheck) {"Online"} else {"Offline"}
    $Reason = if ($IPv4Ping -and $PortCheck) {
        "Network is reachable and computer is manageable. ICMP reply and TCP port '$OpenPort' answered."
    }
    elseif ($IPv4Ping) {
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
        IPv4Ping = $IPv4Ping
        PortCheck = $PortCheck
    }
}