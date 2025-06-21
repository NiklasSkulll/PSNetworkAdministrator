# Computer Management functions for NetworkAdmin module

function Invoke-NetworkAdminComputerManagement {
    [CmdletBinding()]
    param()
    
    do {
        Clear-Host
        Write-Host "============== COMPUTER MANAGEMENT ==============" -ForegroundColor Green
        Write-Host "1. List all computers"
        Write-Host "2. Search for specific computer"
        Write-Host "3. Get computer details"
        Write-Host "4. List computers by operating system"
        Write-Host "5. Check computer online status"
        Write-Host "6. List inactive computers"
        Write-Host "B. Back to main menu"
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" {
                Write-Host "Retrieving all computers..." -ForegroundColor Yellow
                
                $operation = {
                    $config = Get-NetworkAdminConfig
                    $queryResult = Invoke-NetworkAdminADQueryWithPaging -Filter "*" -ObjectType "Computer" -Properties @("Name", "DNSHostName", "Enabled", "OperatingSystem") -MaxResults $config.LargeQueryThreshold
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "List All Computers", "", 3)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Computers found: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.IsTruncated) {
                        $config = Get-NetworkAdminConfig
                        Write-Host "⚠️  Results truncated to $($config.LargeQueryThreshold) computers for performance. Use search for specific queries." -ForegroundColor Yellow
                    }
                    
                    if ($result.Data.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result.Data -Title "AllComputers"
                    }
                    Write-NetworkAdminAuditLog -Action "List All Computers" -Details "Count: $($result.Data.Count), Truncated: $($result.IsTruncated)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "2" {
                $searchTerm = Read-Host "Enter computer name or part of name"
                if ([string]::IsNullOrWhiteSpace($searchTerm) -or $searchTerm.Length -lt 2) {
                    Write-Host "Please enter at least 2 characters for search" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    $filter = "Name -like '*$searchTerm*'"
                    $queryResult = Invoke-NetworkAdminADQueryWithPaging -Filter $filter -ObjectType "Computer" -Properties @("Name", "DNSHostName", "OperatingSystem", "LastLogonDate", "Enabled")
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "Search Computers", $searchTerm, 3)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Computers found: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.Data.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result.Data -Title "ComputerSearch_$searchTerm"
                    }
                    Write-NetworkAdminAuditLog -Action "Search Computers" -Target $searchTerm -Details "Results: $($result.Data.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "3" {
                $computerName = Read-Host "Enter computer name"
                if ([string]::IsNullOrWhiteSpace($computerName)) {
                    Write-Host "Computer name cannot be empty" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    $params = @{
                        Identity = $computerName
                        Properties = "*"
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    Get-ADComputer @params | Select-Object Name, DNSHostName, OperatingSystem, OperatingSystemVersion, LastLogonDate, Created
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "Get Computer Details", $computerName, 3)
                
                if ($null -ne $result) {
                    $result | Format-List
                    Write-NetworkAdminAuditLog -Action "Get Computer Details" -Target $computerName -Details "Success"
                }
                
                Read-Host "Press Enter to continue"
            }
            "4" {
                Write-Host "Computers by Operating System:" -ForegroundColor Yellow
                
                $operation = {
                    $params = @{
                        Filter = "*"
                        Properties = "OperatingSystem"
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    Get-ADComputer @params |
                    Group-Object OperatingSystem | Select-Object Name, Count | Sort-Object Count -Descending
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "List Computers by OS", "", 3)
                
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-NetworkAdminAuditLog -Action "List Computers by OS" -Details "OS Types: $($result.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "5" {
                $computerName = Read-Host "Enter computer name to ping"
                if ([string]::IsNullOrWhiteSpace($computerName)) {
                    Write-Host "Computer name cannot be empty" -ForegroundColor Red
                    continue
                }
                
                if (-not (Test-NetworkAdminValidInput -Input $computerName -Type "ComputerName")) {
                    Write-Host "Invalid computer name format" -ForegroundColor Red
                    continue
                }
                
                Write-Host "Testing connectivity to $computerName..." -ForegroundColor Yellow
                
                $config = Get-NetworkAdminConfig
                $result = Test-NetworkAdminPing -Target $computerName -Count $config.PingCount -TimeoutSeconds $config.NetworkTimeout
                
                if ($null -ne $result) {
                    if ($result) {
                        Write-Host "✓ $computerName is online" -ForegroundColor Green
                        Write-NetworkAdminAuditLog -Action "Ping Test" -Target $computerName -Result "Online"
                        
                        # Additional network details
                        try {
                            $detailedPing = Test-Connection -ComputerName $computerName -Count 1 -ErrorAction SilentlyContinue
                            if ($detailedPing) {
                                Write-Host "  Response Time: $($detailedPing.ResponseTime)ms" -ForegroundColor Cyan
                                Write-Host "  IPv4 Address: $($detailedPing.IPv4Address)" -ForegroundColor Cyan
                            }
                        }
                        catch {
                            # Ignore detailed ping errors
                        }
                    } else {
                        Write-Host "✗ $computerName is offline or unreachable" -ForegroundColor Red
                        Write-NetworkAdminAuditLog -Action "Ping Test" -Target $computerName -Result "Offline"
                    }
                } else {
                    Write-NetworkAdminAuditLog -Action "Ping Test" -Target $computerName -Result "Failed" -Details "Operation timed out"
                }
                
                Read-Host "Press Enter to continue"
            }
            "6" {
                $days = Read-Host "Show computers inactive for how many days? (default: 30)"
                if ([string]::IsNullOrWhiteSpace($days)) { 
                    $days = 30 
                } elseif (-not (Test-NetworkAdminValidInput -Input $days -Type "Number")) {
                    Write-Host "Invalid number format. Using default value of 30 days." -ForegroundColor Yellow
                    $days = 30
                } else {
                    $days = [int]$days
                    if ($days -lt 1 -or $days -gt 365) {
                        Write-Host "Days must be between 1 and 365. Using default value of 30 days." -ForegroundColor Yellow
                        $days = 30
                    }
                }
                
                $cutoffDate = (Get-Date).AddDays(-$days)
                Show-NetworkAdminProgress -Activity "Computer Management" -Status "Finding inactive computers..."
                
                $operation = {
                    $params = @{
                        Filter = "*"
                        Properties = "LastLogonDate"
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    Get-ADComputer @params |
                        Where-Object { $_.LastLogonDate -lt $cutoffDate -or $null -eq $_.LastLogonDate } |
                        Select-Object Name, LastLogonDate, Enabled | Sort-Object LastLogonDate
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "Find Inactive Computers", "", 3)
                
                Write-Progress -Activity "Computer Management" -Completed
                
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-Host "Inactive computers found: $($result.Count)" -ForegroundColor Cyan
                    
                    if ($result.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result -Title "InactiveComputers_$($days)days"
                    }
                    Write-NetworkAdminAuditLog -Action "Find Inactive Computers" -Details "Days: $days, Count: $($result.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}
