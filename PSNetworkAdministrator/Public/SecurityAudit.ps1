# Security Audit functions for NetworkAdmin module

function Invoke-NetworkAdminSecurityAudit {
    [CmdletBinding()]
    param()
    
    do {
        Clear-Host
        Write-ConfigHost "============== SECURITY & AUDIT ================" -ColorType "Success"
        Write-Host "1. List privileged groups"
        Write-Host "2. Find admin accounts"
        Write-Host "3. Password policy information"
        Write-Host "4. Account lockout policy"
        Write-Host "5. Check for accounts with old passwords"
        Write-Host "6. List service accounts"
        Write-Host "7. Check for inactive privileged accounts"
        Write-Host "8. Review group membership changes"
        Write-Host "B. Back to main menu"
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" {
                Write-ConfigHost "Listing privileged groups..." -ColorType "Info"
                $operation = {
                    $privilegedGroups = @(
                        "Domain Admins", "Enterprise Admins", "Schema Admins", 
                        "Administrators", "Account Operators", "Backup Operators",
                        "Server Operators", "Print Operators"
                    )
                    
                    $results = @()
                    foreach ($groupName in $privilegedGroups) {
                        try {
                            $params = @{
                                Identity = $groupName
                                Server = $script:CurrentDomain
                                ErrorAction = 'SilentlyContinue'
                            }
                            if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                            
                            $group = Get-ADGroup @params
                            if ($group) {
                                $memberParams = @{
                                    Identity = $group
                                    Server = $script:CurrentDomain
                                    ErrorAction = 'SilentlyContinue'
                                }
                                if ($script:CurrentCredential) { $memberParams.Credential = $script:CurrentCredential }
                                
                                $members = Get-ADGroupMember @memberParams
                                $results += [PSCustomObject]@{
                                    GroupName = $group.Name
                                    MemberCount = $members.Count
                                    Members = ($members.Name -join ', ')
                                }
                            }
                        }
                        catch {
                            Write-Verbose "Could not query group: $groupName"
                        }
                    }
                    return $results
                }
                
                $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "List Privileged Groups"
                if ($null -ne $result) {
                    $result | Format-Table -Wrap
                    Write-NetworkAdminAuditLog -Action "List Privileged Groups" -Details "Groups: $($result.Count)"
                    
                    if ($result.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result -Title "PrivilegedGroups"
                    }
                } else {
                    Write-ConfigHost "Failed to retrieve privileged groups." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "2" {
                Write-ConfigHost "Finding admin accounts..." -ColorType "Info"
                $operation = {
                    $params = @{
                        Filter = "AdminCount -eq 1"
                        Properties = @("Name", "SamAccountName", "LastLogonDate", "PasswordLastSet", "Enabled")
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    Get-ADUser @params | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet, Enabled
                }
                
                $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "Find Admin Accounts"
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-Host "Admin accounts found: $($result.Count)" -ForegroundColor Cyan
                    Write-NetworkAdminAuditLog -Action "Find Admin Accounts" -Details "Accounts: $($result.Count)"
                    
                    if ($result.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result -Title "AdminAccounts"
                    }
                } else {
                    Write-ConfigHost "Failed to retrieve admin accounts." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "3" {
                Write-ConfigHost "Password policy information..." -ColorType "Info"
                $operation = {
                    $params = @{
                        Identity = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    $domain = Get-ADDomain @params
                    $defaultPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $domain
                    
                    return [PSCustomObject]@{
                        Domain = $domain.Name
                        MinPasswordLength = $defaultPolicy.MinPasswordLength
                        PasswordHistoryCount = $defaultPolicy.PasswordHistoryCount
                        MaxPasswordAge = $defaultPolicy.MaxPasswordAge
                        MinPasswordAge = $defaultPolicy.MinPasswordAge
                        LockoutDuration = $defaultPolicy.LockoutDuration
                        LockoutObservationWindow = $defaultPolicy.LockoutObservationWindow
                        LockoutThreshold = $defaultPolicy.LockoutThreshold
                        ComplexityEnabled = $defaultPolicy.ComplexityEnabled
                        ReversibleEncryptionEnabled = $defaultPolicy.ReversibleEncryptionEnabled
                    }
                }
                
                $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "Get Password Policy"
                if ($null -ne $result) {
                    $result | Format-List
                    Write-NetworkAdminAuditLog -Action "Get Password Policy" -Details "Domain: $($result.Domain)"
                } else {
                    Write-ConfigHost "Failed to retrieve password policy." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "4" {
                Write-ConfigHost "Account lockout policy..." -ColorType "Info"
                $operation = {
                    $params = @{
                        Identity = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    $domain = Get-ADDomain @params
                    $lockoutPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $domain
                    
                    Write-Host "Lockout Threshold: $($lockoutPolicy.LockoutThreshold) failed attempts"
                    Write-Host "Lockout Duration: $($lockoutPolicy.LockoutDuration)"
                    Write-Host "Lockout Observation Window: $($lockoutPolicy.LockoutObservationWindow)"
                    
                    # Find currently locked accounts
                    $lockedUsers = Search-ADAccount -LockedOut -Server $script:CurrentDomain
                    if ($lockedUsers) {
                        Write-Host "`nCurrently locked accounts:"
                        $lockedUsers | Select-Object Name, SamAccountName, LastLogonDate | Format-Table
                    } else {
                        Write-Host "`nNo accounts are currently locked out." -ForegroundColor Green
                    }
                    
                    return $lockoutPolicy
                }
                
                $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "Get Account Lockout Policy"
                if ($null -ne $result) {
                    Write-NetworkAdminAuditLog -Action "Get Account Lockout Policy" -Details "Success"
                } else {
                    Write-ConfigHost "Failed to retrieve account lockout policy." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "5" {
                $days = Read-Host "Find accounts with passwords older than how many days? (default: 90)"
                if ([string]::IsNullOrWhiteSpace($days)) { 
                    $days = 90 
                } elseif (-not (Test-NetworkAdminValidInput -Input $days -Type "Number")) {
                    Write-Host "Invalid number. Using default of 90 days." -ForegroundColor Yellow
                    $days = 90
                }
                
                Write-ConfigHost "Finding accounts with passwords older than $days days..." -ColorType "Info"
                $operation = {
                    $cutoffDate = (Get-Date).AddDays(-$days)
                    $params = @{
                        Filter = "PasswordLastSet -lt '$cutoffDate' -and Enabled -eq 'True'"
                        Properties = @("Name", "SamAccountName", "PasswordLastSet", "LastLogonDate")
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    Get-ADUser @params | Select-Object Name, SamAccountName, PasswordLastSet, LastLogonDate
                }
                
                $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "Find Old Password Accounts"
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-Host "Accounts with old passwords: $($result.Count)" -ForegroundColor Cyan
                    Write-NetworkAdminAuditLog -Action "Find Old Password Accounts" -Details "Days: $days, Accounts: $($result.Count)"
                    
                    if ($result.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result -Title "OldPasswordAccounts_$($days)days"
                    }
                } else {
                    Write-ConfigHost "Failed to find accounts with old passwords." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "6" {
                Write-ConfigHost "Finding service accounts..." -ColorType "Info"
                $operation = {
                    $params = @{
                        Filter = "ServicePrincipalName -like '*'"
                        Properties = @("Name", "SamAccountName", "ServicePrincipalNames", "LastLogonDate", "PasswordLastSet")
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    $serviceAccounts = Get-ADUser @params
                    $results = @()
                    foreach ($account in $serviceAccounts) {
                        $results += [PSCustomObject]@{
                            Name = $account.Name
                            SamAccountName = $account.SamAccountName
                            ServicePrincipalNames = ($account.ServicePrincipalNames -join '; ')
                            LastLogonDate = $account.LastLogonDate
                            PasswordLastSet = $account.PasswordLastSet
                        }
                    }
                    return $results
                }
                
                $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "Find Service Accounts"
                if ($null -ne $result) {
                    $result | Format-Table -Wrap
                    Write-Host "Service accounts found: $($result.Count)" -ForegroundColor Cyan
                    Write-NetworkAdminAuditLog -Action "Find Service Accounts" -Details "Accounts: $($result.Count)"
                    
                    if ($result.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result -Title "ServiceAccounts"
                    }
                } else {
                    Write-ConfigHost "Failed to find service accounts." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "7" {
                $days = Read-Host "Find privileged accounts inactive for how many days? (default: 30)"
                if ([string]::IsNullOrWhiteSpace($days)) { 
                    $days = 30 
                } elseif (-not (Test-NetworkAdminValidInput -Input $days -Type "Number")) {
                    Write-Host "Invalid number. Using default of 30 days." -ForegroundColor Yellow
                    $days = 30
                }
                
                Write-ConfigHost "Finding inactive privileged accounts (inactive for $days days)..." -ColorType "Info"
                $operation = {
                    $cutoffDate = (Get-Date).AddDays(-$days)
                    $params = @{
                        Filter = "AdminCount -eq 1 -and (LastLogonDate -lt '$cutoffDate' -or LastLogonDate -notlike '*') -and Enabled -eq 'True'"
                        Properties = @("Name", "SamAccountName", "LastLogonDate", "PasswordLastSet")
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    Get-ADUser @params | Select-Object Name, SamAccountName, LastLogonDate, PasswordLastSet
                }
                
                $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "Find Inactive Privileged Accounts"
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-Host "Inactive privileged accounts: $($result.Count)" -ForegroundColor Cyan
                    Write-NetworkAdminAuditLog -Action "Find Inactive Privileged Accounts" -Details "Days: $days, Accounts: $($result.Count)"
                    
                    if ($result.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result -Title "InactivePrivilegedAccounts_$($days)days"
                    }
                } else {
                    Write-ConfigHost "Failed to find inactive privileged accounts." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "8" {
                Write-ConfigHost "Group membership change review is a complex audit task." -ColorType "Info"
                Write-Host "For comprehensive group membership auditing, consider:"
                Write-Host "• Enabling advanced auditing in Group Policy"
                Write-Host "• Using Event Log analysis tools"
                Write-Host "• Implementing privileged access management (PAM) solutions"
                Write-Host "• Regular access reviews and attestation processes"
                Write-Host ""
                Write-Host "This feature would require access to domain controller event logs"
                Write-Host "and is typically implemented through dedicated security tools."
                Write-NetworkAdminAuditLog -Action "Group Membership Review" -Details "Information provided"
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}

function Invoke-SystemHealthCheck {
    <#
    .SYNOPSIS
    Performs comprehensive system health check

    .DESCRIPTION
    Checks disk space, memory usage, CPU usage, critical services, network connectivity, and recent system errors

    .EXAMPLE
    Invoke-SystemHealthCheck
    #>
    Clear-Host
    Write-Host "============== SYSTEM HEALTH CHECK ==============" -ForegroundColor Green
    
    Write-Host "Performing system health check..." -ForegroundColor Yellow
    
    # Check disk space
    Write-Host "`n1. Disk Space Check:" -ForegroundColor Cyan
    Get-CimInstance -ClassName Win32_LogicalDisk | 
    Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round($_.Size/1GB,2)}}, 
    @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace/1GB,2)}},
    @{Name="% Free";Expression={[math]::Round(($_.FreeSpace/$_.Size)*100,2)}} | Format-Table -AutoSize
    
    # Check memory usage
    Write-Host "2. Memory Usage:" -ForegroundColor Cyan
    $memory = Get-CimInstance -ClassName Win32_ComputerSystem
    $totalMemory = [math]::Round($memory.TotalPhysicalMemory/1GB, 2)
    $availableMemory = Get-Counter "\Memory\Available MBytes"
    $availableMemoryGB = [math]::Round($availableMemory.CounterSamples.CookedValue/1024, 2)
    $usedMemoryGB = $totalMemory - $availableMemoryGB
    $memoryUsagePercent = [math]::Round(($usedMemoryGB / $totalMemory) * 100, 2)
    
    Write-Host "Total Memory: $totalMemory GB"
    Write-Host "Used Memory: $usedMemoryGB GB ($memoryUsagePercent%)"
    Write-Host "Available Memory: $availableMemoryGB GB"
    
    # Check CPU usage
    Write-Host "`n3. CPU Usage:" -ForegroundColor Cyan
    $cpu = Get-Counter "\Processor(_Total)\% Processor Time"
    $cpuUsage = [math]::Round($cpu.CounterSamples.CookedValue, 2)
    Write-Host "Current CPU Usage: $cpuUsage%"
    
    # Check critical services
    Write-Host "`n4. Critical Services Status:" -ForegroundColor Cyan
    $criticalServices = @("DNS", "DHCP", "Netlogon", "ADWS", "KDC", "W32Time")
    foreach ($service in $criticalServices) {
        try {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc) {
                if ($svc.Status -eq "Running") {
                    Write-Host "✓ $service : Running" -ForegroundColor Green
                } else {
                    Write-Host "✗ $service : $($svc.Status)" -ForegroundColor Red
                }
            } else {
                Write-Host "- $service : Not installed" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "- $service : Unable to check" -ForegroundColor Yellow
        }
    }
    
    # Check network connectivity
    Write-Host "`n5. Network Connectivity:" -ForegroundColor Cyan
    $testSites = @("8.8.8.8", "1.1.1.1", $script:Domain)
    foreach ($site in $testSites) {
        if (Test-Connection -ComputerName $site -Count 1 -Quiet) {
            Write-Host "✓ $site : Reachable" -ForegroundColor Green
        } else {
            Write-Host "✗ $site : Unreachable" -ForegroundColor Red
        }
    }
    
    # Check Event Log for recent errors
    Write-Host "`n6. Recent System Errors (last 24 hours):" -ForegroundColor Cyan
    try {
        $errors = Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddDays(-1) -Newest 5 -ErrorAction SilentlyContinue
        if ($errors) {
            $errors | Select-Object TimeGenerated, Source, EventID, Message | Format-Table -Wrap
        } else {
            Write-Host "No recent system errors found" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Unable to check event logs" -ForegroundColor Yellow
    }
    
    Write-AuditLog -Action "SystemHealthCheck" -Details "Performed comprehensive system health check"
    Read-Host "Press Enter to continue"
}
