function Test-TCPPortAvailability {
    <#
    .SYNOPSIS
        Tests TCP port availability on a remote host.
    
    .DESCRIPTION
        The Test-TCPPortAvailability function performs a non-blocking TCP connection test to determine
        if a specific port is open and accepting connections on a target host. It uses asynchronous
        socket operations with a timeout (800ms) to quickly determine port accessibility without blocking
        the PowerShell pipeline.
        
        This function is particularly useful for checking service availability (RDP, WinRM, SSH, SMB)
        before attempting administrative operations on remote computers.
    
    .PARAMETER HostName
        The target hostname, fully qualified domain name (FQDN) or IP address to test.
        This parameter is mandatory.
    
    .PARAMETER Port
        The TCP port number to test (1-65535).
        This parameter is mandatory and validated to ensure it falls within the valid port range.
        
        Common ports:
        - 22   (SSH)
        - 445  (SMB/CIFS)
        - 3389 (RDP)
        - 5985 (WinRM HTTP)
        - 5986 (WinRM HTTPS)
    
    .EXAMPLE
        Test-TCPPortAvailability -HostName "server01.contoso.com" -Port 5985
        
        Tests if WinRM (port 5985) is accessible on server01.contoso.com.
        Returns $true if the port is open, $false otherwise.
    
    .INPUTS
        None. This function does not accept pipeline input.
    
    .OUTPUTS
        System.Boolean
        Returns $true if the TCP port is open and accepting connections.
        Returns $false if the port is closed, filtered, or unreachable within the timeout period.
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0
        Requires: PowerShell 7.0+
        
        This is a private function used internally by the PSNetworkAdministrator module.
        
        Technical Details:
        - Uses System.Net.Sockets.TcpClient for connection testing
        - Implements asynchronous BeginConnect/EndConnect pattern
        - Default timeout: 800 milliseconds
        - Properly disposes of TcpClient resources to prevent socket exhaustion
        - Does not require ICMP/ping to be enabled (works through firewalls that block ICMP)
        
        Performance Considerations:
        - Faster than Test-NetConnection for simple port checks
        - Non-blocking asynchronous operation
        - Suitable for testing multiple ports in rapid succession
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$HostName,

        [Parameter(Mandatory)]
        [ValidateRange(1,65535)]
        [int]$Port
    )

    # define a timeout variable for the port check
    $TimeoutMs = 800

    # check the port connection with a TCP client object and a in-progress connect operation
    try {
        $TCPClient = [System.Net.Sockets.TcpClient]::new()
        $InProgressConnection = $TCPClient.BeginConnect($HostName, $Port, $null, $null)

        # return $false by connection timeout
        if (-not $InProgressConnection.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
            $TCPClient.EndConnect($InProgressConnection)
            $TCPClient.Close()
            return $false
        }

        # connection was successfull, close connection and return $true
        $TCPClient.EndConnect($InProgressConnection)
        $TCPClient.Close()
        return $true
    }
    catch {
        return $false
    }
}
