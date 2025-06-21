# Domain Controller Information functions for NetworkAdmin module

function Invoke-NetworkAdminDomainControllerInfo {
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-ConfigHost "============= DOMAIN CONTROLLER INFO =============" -ColorType "Success"
    
    # Enhanced operation to get domain controllers with failover
    $dcInfoOperation = {
        Write-ConfigHost "Domain Controllers for $script:CurrentDomain:" -ColorType "Info"
        
        $params = @{
            Filter = "*"
            Server = $script:CurrentDomain
            ErrorAction = 'Stop'
        }
        if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
        
        $domainControllers = Get-ADDomainController @params
        
        if ($domainControllers) {
            foreach ($dc in $domainControllers) {
                Write-ConfigHost "DC: $($dc.Name)" -ColorType "Success"
                Write-Host "  Hostname: $($dc.HostName)"
                Write-Host "  Site: $($dc.Site)"
                Write-Host "  OS: $($dc.OperatingSystem)"
                Write-Host "  IP Address: $($dc.IPv4Address)"
                Write-Host "  Roles: $($dc.OperationMasterRoles -join ', ')"
                
                # Test connectivity to this DC
                $pingResult = Test-NetworkAdminConnectivity -Target $dc.HostName -Type "Ping"
                $status = if ($pingResult) { "Online" } else { "Offline" }
                Write-Host "  Status: $status" -ForegroundColor $(if ($pingResult) { "Green" } else { "Red" })
                Write-Host ""
            }
            return $domainControllers
        } else {
            throw "No domain controllers found for domain $script:CurrentDomain"
        }
    }
    
    $result = Invoke-NetworkAdminADOperationWithFailover -Operation $dcInfoOperation -OperationName "Get Domain Controller Information"
    
    if ($null -ne $result) {
        Write-NetworkAdminAuditLog -Action "Get Domain Controller Information" -Target $script:CurrentDomain -Details "DCs Found: $($result.Count)"
        
        # Get domain information with enhanced error handling
        $domainInfoOperation = {
            Write-ConfigHost "`nDomain Information:" -ColorType "Info"
            
            $params = @{
                Identity = $script:CurrentDomain
                ErrorAction = 'Stop'
            }
            if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
            
            $domain = Get-ADDomain @params
            
            Write-Host "Domain Name: $($domain.Name)"
            Write-Host "Domain SID: $($domain.DomainSID)"
            Write-Host "Forest: $($domain.Forest)"
            Write-Host "Functional Level: $($domain.DomainMode)"
            Write-Host "PDC Emulator: $($domain.PDCEmulator)"
            Write-Host "RID Master: $($domain.RIDMaster)"
            Write-Host "Infrastructure Master: $($domain.InfrastructureMaster)"
            Write-Host ""
            
            return $domain
        }
        
        $domainResult = Invoke-NetworkAdminADOperationWithFailover -Operation $domainInfoOperation -OperationName "Get Domain Information"
        if ($null -ne $domainResult) {
            Write-NetworkAdminAuditLog -Action "Get Domain Information" -Target $script:CurrentDomain -Details "Success"
        } else {
            Write-ConfigHost "Failed to retrieve detailed domain information." -ColorType "Warning"
        }
        
        # Forest information
        $forestInfoOperation = {
            Write-ConfigHost "`nForest Information:" -ColorType "Info"
            
            $params = @{
                Identity = $script:CurrentDomain
                ErrorAction = 'Stop'
            }
            if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
            
            $forest = Get-ADForest @params
            
            Write-Host "Forest Name: $($forest.Name)"
            Write-Host "Forest Mode: $($forest.ForestMode)"
            Write-Host "Schema Master: $($forest.SchemaMaster)"
            Write-Host "Domain Naming Master: $($forest.DomainNamingMaster)"
            Write-Host "Domains: $($forest.Domains -join ', ')"
            Write-Host "Sites: $($forest.Sites -join ', ')"
            Write-Host ""
            
            return $forest
        }
        
        $forestResult = Invoke-NetworkAdminADOperationWithFailover -Operation $forestInfoOperation -OperationName "Get Forest Information"
        if ($null -ne $forestResult) {
            Write-NetworkAdminAuditLog -Action "Get Forest Information" -Target $script:CurrentDomain -Details "Success"
        } else {
            Write-ConfigHost "Failed to retrieve forest information." -ColorType "Warning"
        }
    } else {
        Write-ConfigHost "Failed to retrieve domain controller information. Please verify domain connectivity and credentials." -ColorType "Error"
        
        # Fallback: Try basic connectivity test
        Write-ConfigHost "`nAttempting basic domain connectivity test..." -ColorType "Info"
        $basicTestOperation = {
            # Test if we can resolve the domain name
            $dnsResult = Test-NetworkAdminConnectivity -Target $script:CurrentDomain -Type "Ping"
            if ($dnsResult) {
                Write-ConfigHost "✓ Domain $script:CurrentDomain is reachable via ping" -ColorType "Success"
            } else {
                Write-ConfigHost "✗ Domain $script:CurrentDomain is not reachable via ping" -ColorType "Error"
            }
            
            # Try to test secure channel
            try {
                $testResult = Test-ComputerSecureChannel -ErrorAction Stop
                if ($testResult) {
                    Write-ConfigHost "✓ Secure channel to domain is working" -ColorType "Success"
                } else {
                    Write-ConfigHost "✗ Secure channel to domain has issues" -ColorType "Warning"
                }
            }
            catch {
                Write-ConfigHost "Could not test secure channel: $($_.Exception.Message)" -ColorType "Warning"
            }
            
            return "Basic connectivity test completed"
        }
        
        Invoke-NetworkAdminNetworkOperationWithFallback -PrimaryOperation $basicTestOperation -OperationName "Test Domain Secure Channel"
    }
    
    Read-Host "Press Enter to continue"
}
