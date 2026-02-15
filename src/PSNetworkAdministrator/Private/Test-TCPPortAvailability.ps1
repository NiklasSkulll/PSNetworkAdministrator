function Test-TCPPortAvailability {
    <#
    
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
