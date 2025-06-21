# Network Diagnostics functions for NetworkAdmin module

function Invoke-NetworkAdminNetworkDiagnostics {
    [CmdletBinding()]
    param()
    
    do {
        Clear-Host
        Write-Host "============== NETWORK DIAGNOSTICS ==============" -ForegroundColor Green
        Write-Host "1. Ping test"
        Write-Host "2. Port connectivity test"
        Write-Host "3. DNS resolution test"
        Write-Host "4. Network adapter information"
        Write-Host "5. Route table"
        Write-Host "6. ARP table"
        Write-Host "7. Network statistics"
        Write-Host "B. Back to main menu"
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" {
                $target = Read-Host "Enter hostname/IP to ping"
                if ([string]::IsNullOrWhiteSpace($target)) {
                    Write-Host "Target cannot be empty" -ForegroundColor Red
                    continue
                }
                
                $count = Read-Host "Number of pings (default: 4)"
                if ([string]::IsNullOrWhiteSpace($count)) { 
                    $count = 4 
                } elseif (-not (Test-NetworkAdminValidInput -Input $count -Type "Number")) {
                    Write-Host "Invalid number. Using default." -ForegroundColor Yellow
                    $count = 4
                }
                
                $config = Get-NetworkAdminConfig
                $result = Test-NetworkAdminPing -Target $target -Count $count -TimeoutSeconds ($config.NetworkTimeout * 2)
                
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-NetworkAdminAuditLog -Action "Ping Test" -Target $target -Details "Count: $count, Success: $($result.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "2" {
                $target = Read-Host "Enter hostname/IP"
                $port = Read-Host "Enter port number"
                
                if ([string]::IsNullOrWhiteSpace($target) -or [string]::IsNullOrWhiteSpace($port)) {
                    Write-Host "Target and port cannot be empty" -ForegroundColor Red
                    continue
                }
                
                if (-not (Test-NetworkAdminValidInput -Input $port -Type "Number")) {
                    Write-Host "Invalid port number" -ForegroundColor Red
                    continue
                }
                
                $config = Get-NetworkAdminConfig
                $result = Test-NetworkAdminPortConnectivity -Target $target -Port ([int]$port) -TimeoutSeconds $config.NetworkTimeout
                
                if ($null -ne $result) {
                    if ($result.TcpTestSucceeded) {
                        Write-Host "✓ Port $port is open on $target" -ForegroundColor Green
                        Write-Host "  Remote Address: $($result.RemoteAddress)" -ForegroundColor Cyan
                        Write-Host "  Source Address: $($result.SourceAddress.IPAddress)" -ForegroundColor Cyan
                    } else {
                        Write-Host "✗ Port $port is closed on $target" -ForegroundColor Red
                    }
                    Write-NetworkAdminAuditLog -Action "Port Test" -Target "$target`:$port" -Result $(if ($result.TcpTestSucceeded) { "Open" } else { "Closed" })
                }
                
                Read-Host "Press Enter to continue"
            }
            "3" {
                $hostname = Read-Host "Enter hostname to resolve"
                if ([string]::IsNullOrWhiteSpace($hostname)) {
                    Write-Host "Hostname cannot be empty" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    Resolve-DnsName -Name $hostname -ErrorAction Stop
                }
                
                $result = Invoke-NetworkAdminNetworkOperationWithTimeout -Operation $operation -TimeoutSeconds 30 -OperationName "DNS Resolution"
                
                if ($null -ne $result) {
                    $result | Format-Table
                    Write-NetworkAdminAuditLog -Action "DNS Resolution" -Target $hostname -Details "Records: $($result.Count)"
                } else {
                    Write-Host "DNS resolution failed or timed out" -ForegroundColor Red
                }
                
                Read-Host "Press Enter to continue"
            }
            "4" {
                Write-Host "Network adapter information:" -ForegroundColor Yellow
                
                $operation = {
                    Get-NetAdapter | Select-Object Name, InterfaceDescription, LinkSpeed, Status
                }
                
                $result = Invoke-NetworkAdminNetworkOperationWithTimeout -Operation $operation -TimeoutSeconds 30 -OperationName "Get Network Adapters"
                
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-NetworkAdminAuditLog -Action "Get Network Adapters" -Details "Adapters: $($result.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "5" {
                Write-Host "Route table:" -ForegroundColor Yellow
                
                $operation = {
                    Get-NetRoute | Where-Object {$_.RouteMetric -ne 256} | 
                    Select-Object DestinationPrefix, NextHop, RouteMetric, ifIndex
                }
                
                $result = Invoke-NetworkAdminNetworkOperationWithTimeout -Operation $operation -TimeoutSeconds 30 -OperationName "Get Route Table"
                
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-NetworkAdminAuditLog -Action "Get Route Table" -Details "Routes: $($result.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "6" {
                Write-Host "ARP table:" -ForegroundColor Yellow
                
                $operation = {
                    Get-NetNeighbor | Where-Object {$_.State -ne "Unreachable"} |
                    Select-Object IPAddress, LinkLayerAddress, State
                }
                
                $result = Invoke-NetworkAdminNetworkOperationWithTimeout -Operation $operation -TimeoutSeconds 30 -OperationName "Get ARP Table"
                
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-NetworkAdminAuditLog -Action "Get ARP Table" -Details "Entries: $($result.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "7" {
                Write-Host "Network statistics:" -ForegroundColor Yellow
                
                $operation = {
                    Get-NetAdapterStatistics | Select-Object Name, BytesReceived, BytesSent, PacketsReceived, PacketsSent
                }
                
                $result = Invoke-NetworkAdminNetworkOperationWithTimeout -Operation $operation -TimeoutSeconds 30 -OperationName "Get Network Statistics"
                
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-NetworkAdminAuditLog -Action "Get Network Statistics" -Details "Adapters: $($result.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}
