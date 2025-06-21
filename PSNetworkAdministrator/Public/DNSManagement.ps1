# DNS Management functions for NetworkAdmin module

function Invoke-NetworkAdminDNSManagement {
    [CmdletBinding()]
    param()
    
    do {
        Clear-Host
        Write-ConfigHost "================ DNS MANAGEMENT =================" -ColorType "Success"
        Write-Host "1. Query DNS record"
        Write-Host "2. List DNS servers"
        Write-Host "3. Flush DNS cache"
        Write-Host "4. Check DNS zones (requires DNS module)"
        Write-Host "B. Back to main menu"
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" {
                $hostname = Read-Host "Enter hostname to query"
                if (-not [string]::IsNullOrWhiteSpace($hostname)) {
                    $recordType = Read-Host "Enter record type (A, AAAA, MX, NS, TXT) or press Enter for all"
                    
                    # Create primary and fallback DNS query operations
                    $primaryOperation = {
                        if ([string]::IsNullOrWhiteSpace($recordType)) {
                            return Resolve-DnsName -Name $hostname -ErrorAction Stop
                        } else {
                            return Resolve-DnsName -Name $hostname -Type $recordType -ErrorAction Stop
                        }
                    }
                    
                    # Fallback with different DNS servers
                    $fallbackOperations = @(
                        {
                            # Fallback with Google DNS
                            if ([string]::IsNullOrWhiteSpace($recordType)) {
                                return Resolve-DnsName -Name $hostname -Server "8.8.8.8" -ErrorAction Stop
                            } else {
                                return Resolve-DnsName -Name $hostname -Type $recordType -Server "8.8.8.8" -ErrorAction Stop
                            }
                        },
                        {
                            # Fallback with Cloudflare DNS
                            if ([string]::IsNullOrWhiteSpace($recordType)) {
                                return Resolve-DnsName -Name $hostname -Server "1.1.1.1" -ErrorAction Stop
                            } else {
                                return Resolve-DnsName -Name $hostname -Type $recordType -Server "1.1.1.1" -ErrorAction Stop
                            }
                        }
                    )
                    
                    $result = Invoke-NetworkAdminNetworkOperationWithFallback -PrimaryOperation $primaryOperation -FallbackOperations $fallbackOperations -OperationName "DNS Query for $hostname"
                    if ($null -ne $result) {
                        $result | Format-Table
                        Write-NetworkAdminAuditLog -Action "DNS Query" -Target $hostname -Details "Type: $recordType, Records: $($result.Count)"
                    } else {
                        Write-ConfigHost "DNS query failed for $hostname" -ColorType "Error"
                    }
                } else {
                    Write-ConfigHost "Hostname cannot be empty." -ColorType "Warning"
                }
                Read-Host "Press Enter to continue"
            }
            "2" {
                Write-ConfigHost "DNS Server Configuration:" -ColorType "Info"
                $operation = {
                    return Get-DnsClientServerAddress
                }
                $result = Invoke-NetworkAdminNetworkOperationWithFallback -PrimaryOperation $operation -OperationName "Get DNS Server Configuration"
                if ($null -ne $result) {
                    $result | Format-Table
                    Write-NetworkAdminAuditLog -Action "Get DNS Server Configuration" -Details "Interfaces: $($result.Count)"
                } else {
                    Write-ConfigHost "Failed to retrieve DNS server configuration." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "3" {
                Write-ConfigHost "Flushing DNS cache..." -ColorType "Info"
                $operation = {
                    Clear-DnsClientCache
                    return "DNS cache cleared successfully"
                }
                $result = Invoke-NetworkAdminNetworkOperationWithFallback -PrimaryOperation $operation -OperationName "Flush DNS Cache"
                if ($null -ne $result) {
                    Write-ConfigHost "✓ $result" -ColorType "Success"
                    Write-NetworkAdminAuditLog -Action "Flush DNS Cache" -Details "Success"
                } else {
                    Write-ConfigHost "Failed to flush DNS cache." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "4" {
                $operation = {
                    # Try to get DNS zones if DNS module is available
                    try {
                        Import-Module DnsServer -ErrorAction Stop
                        return Get-DnsServerZone -ComputerName $script:CurrentDomain
                    }
                    catch {
                        throw "DNS Server module not available or insufficient permissions"
                    }
                }
                
                $fallbackOperation = {
                    # Fallback: Try to query some common DNS records
                    Write-ConfigHost "DNS Server module not available. Trying basic zone information..." -ColorType "Warning"
                    $commonRecords = @("_ldap._tcp", "_kerberos._tcp", "_gc._tcp")
                    $results = @()
                    foreach ($record in $commonRecords) {
                        try {
                            $srvRecord = "$record.$script:CurrentDomain"
                            $result = Resolve-DnsName -Name $srvRecord -Type SRV -ErrorAction SilentlyContinue
                            if ($result) {
                                $results += [PSCustomObject]@{
                                    RecordType = "SRV"
                                    Name = $srvRecord
                                    Target = $result.NameTarget
                                    Port = $result.Port
                                    Priority = $result.Priority
                                }
                            }
                        }
                        catch {
                            # Ignore individual record failures
                        }
                    }
                    return $results
                }
                
                $result = Invoke-NetworkAdminNetworkOperationWithFallback -PrimaryOperation $operation -FallbackOperations @($fallbackOperation) -OperationName "Get DNS Zones"
                if ($null -ne $result) {
                    $result | Format-Table
                    Write-NetworkAdminAuditLog -Action "Get DNS Zones" -Details "Zones/Records: $($result.Count)"
                } else {
                    Write-ConfigHost "Failed to retrieve DNS zone information." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}
