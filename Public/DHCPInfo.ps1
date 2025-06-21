# DHCP Information functions for NetworkAdmin module

function Invoke-NetworkAdminDHCPInfo {
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-ConfigHost "================ DHCP INFORMATION ===============" -ColorType "Success"
    
    # Primary operation for IP configuration
    $ipConfigOperation = {
        Write-ConfigHost "Current IP Configuration:" -ColorType "Info"
        return Get-NetIPConfiguration | Where-Object {$_.NetAdapter.Status -eq "Up"} |
        Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer
    }
    
    $result = Invoke-NetworkAdminNetworkOperationWithFallback -PrimaryOperation $ipConfigOperation -OperationName "Get IP Configuration"
    if ($null -ne $result) {
        $result | Format-List
        Write-NetworkAdminAuditLog -Action "Get IP Configuration" -Details "Interfaces: $($result.Count)"
    } else {
        Write-ConfigHost "Failed to retrieve IP configuration." -ColorType "Error"
    }
    
    # DHCP interface information
    $dhcpInterfaceOperation = {
        Write-ConfigHost "`nDHCP Client Information:" -ColorType "Info"
        return Get-NetIPInterface | Where-Object {$_.Dhcp -eq "Enabled"} |
        Select-Object InterfaceAlias, AddressFamily, Dhcp
    }
    
    $result = Invoke-NetworkAdminNetworkOperationWithFallback -PrimaryOperation $dhcpInterfaceOperation -OperationName "Get DHCP Interface Information"
    if ($null -ne $result) {
        $result | Format-Table
        Write-NetworkAdminAuditLog -Action "Get DHCP Interface Information" -Details "DHCP Interfaces: $($result.Count)"
    } else {
        Write-ConfigHost "Failed to retrieve DHCP interface information." -ColorType "Error"
    }
    
    # DHCP lease information with fallback methods
    Write-ConfigHost "`nTrying to get DHCP lease information..." -ColorType "Info"
    
    $primaryLeaseOperation = {
        $dhcpInfo = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object {$_.DHCPEnabled -eq $true}
        $results = @()
        foreach ($adapter in $dhcpInfo) {
            $leaseInfo = [PSCustomObject]@{
                Interface = $adapter.Description
                DHCPServer = $adapter.DHCPServer
                LeaseObtained = $adapter.DHCPLeaseObtained
                LeaseExpires = $adapter.DHCPLeaseExpires
                IPAddress = $adapter.IPAddress -join ", "
                SubnetMask = $adapter.IPSubnet -join ", "
                DefaultGateway = $adapter.DefaultIPGateway -join ", "
            }
            $results += $leaseInfo
            
            Write-ConfigHost "Interface: $($adapter.Description)" -ColorType "Info"
            Write-Host "  DHCP Server: $($adapter.DHCPServer)"
            Write-Host "  Lease Obtained: $($adapter.DHCPLeaseObtained)"
            Write-Host "  Lease Expires: $($adapter.DHCPLeaseExpires)"
            Write-Host "  IP Address: $($adapter.IPAddress -join ', ')"
            Write-Host ""
        }
        return $results
    }
    
    $fallbackLeaseOperations = @(
        {
            # Fallback: Try using ipconfig if available
            Write-Verbose "Trying ipconfig /all as fallback"
            try {
                $ipconfig = & ipconfig /all 2>$null
                if ($ipconfig) {
                    Write-ConfigHost "DHCP lease information (via ipconfig):" -ColorType "Info"
                    $ipconfig | Where-Object { $_ -match "DHCP|Lease" } | ForEach-Object { Write-Host "  $_" }
                    return "DHCP info retrieved via ipconfig"
                } else {
                    throw "ipconfig command failed"
                }
            }
            catch {
                throw "ipconfig fallback failed: $($_.Exception.Message)"
            }
        },
        {
            # Fallback: Basic network adapter info
            Write-Verbose "Getting basic network adapter information"
            $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
            Write-ConfigHost "Available Network Adapters:" -ColorType "Info"
            foreach ($adapter in $adapters) {
                Write-Host "  Name: $($adapter.Name)"
                Write-Host "  Description: $($adapter.InterfaceDescription)"
                Write-Host "  Status: $($adapter.Status)"
                Write-Host "  Link Speed: $($adapter.LinkSpeed)"
                Write-Host ""
            }
            return "Basic adapter info retrieved"
        }
    )
    
    $result = Invoke-NetworkAdminNetworkOperationWithFallback -PrimaryOperation $primaryLeaseOperation -FallbackOperations $fallbackLeaseOperations -OperationName "Get DHCP Lease Information"
    if ($null -ne $result) {
        if ($result -is [array] -and $result.Count -gt 0 -and $result[0] -is [PSCustomObject]) {
            # We got structured DHCP data
            Write-NetworkAdminAuditLog -Action "Get DHCP Lease Information" -Details "DHCP Adapters: $($result.Count)"
        } else {
            # We got fallback data
            Write-NetworkAdminAuditLog -Action "Get DHCP Lease Information" -Details "Fallback method used"
        }
    } else {
        Write-ConfigHost "Unable to retrieve DHCP lease details. This may require administrative privileges or the system may not be using DHCP." -ColorType "Warning"
        Write-NetworkAdminAuditLog -Action "Get DHCP Lease Information" -Result "Failed" -Details "All methods failed"
    }
    
    Read-Host "Press Enter to continue"
}
