# User Management functions for NetworkAdmin module

function Invoke-NetworkAdminUserManagement {
    [CmdletBinding()]
    param()
    
    do {
        Clear-Host
        Write-Host "================ USER MANAGEMENT ================" -ForegroundColor Green
        Write-Host "1. List all users"
        Write-Host "2. Search for specific user"
        Write-Host "3. Get user details"
        Write-Host "4. List disabled users"
        Write-Host "5. List users with password never expires"
        Write-Host "6. List users by group membership"
        Write-Host "7. Check user last logon"
        Write-Host "B. Back to main menu"
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" {
                Write-Host "Retrieving all users..." -ForegroundColor Yellow
                
                $operation = {
                    $config = Get-NetworkAdminConfig
                    $queryResult = Invoke-NetworkAdminADQueryWithPaging -Filter "*" -ObjectType "User" -Properties @("Name", "SamAccountName", "Enabled") -MaxResults $config.LargeQueryThreshold
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "List All Users", "", 3)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Users found: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.IsTruncated) {
                        $config = Get-NetworkAdminConfig
                        Write-Host "⚠️  Results truncated to $($config.LargeQueryThreshold) users for performance. Use search for specific queries." -ForegroundColor Yellow
                    }
                    
                    if ($result.Data.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result.Data -Title "AllUsers"
                    }
                    Write-NetworkAdminAuditLog -Action "List All Users" -Details "Count: $($result.Data.Count), Truncated: $($result.IsTruncated)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "2" {
                $searchTerm = Read-Host "Enter username or part of name to search"
                if (-not (Test-NetworkAdminValidInput -Input $searchTerm -Type "UserName") -and $searchTerm.Length -lt 2) {
                    Write-Host "Please enter at least 2 characters for search" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    $filter = "Name -like '*$searchTerm*' -or SamAccountName -like '*$searchTerm*'"
                    $queryResult = Invoke-NetworkAdminADQueryWithPaging -Filter $filter -ObjectType "User" -Properties @("Name", "SamAccountName", "Enabled")
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "Search Users", $searchTerm, 3)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Users found: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.Data.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result.Data -Title "UserSearch_$searchTerm"
                    }
                    Write-NetworkAdminAuditLog -Action "Search Users" -Target $searchTerm -Details "Results: $($result.Data.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "3" {
                $username = Read-Host "Enter username"
                if ([string]::IsNullOrWhiteSpace($username)) {
                    Write-Host "Username cannot be empty" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    $params = @{
                        Identity = $username
                        Properties = "*"
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    Get-ADUser @params | Select-Object Name, SamAccountName, EmailAddress, Department, Title, LastLogonDate, PasswordLastSet, Enabled
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "Get User Details", $username, 3)
                
                if ($null -ne $result) {
                    $result | Format-List
                    Write-NetworkAdminAuditLog -Action "Get User Details" -Target $username -Details "Success"
                }
                
                Read-Host "Press Enter to continue"
            }
            "4" {
                Write-Host "Retrieving disabled users..." -ForegroundColor Yellow
                
                $operation = {
                    $queryResult = Invoke-NetworkAdminADQueryWithPaging -Filter "Enabled -eq `$false" -ObjectType "User" -Properties @("Name", "SamAccountName", "LastLogonDate")
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "List Disabled Users", "", 3)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Disabled users found: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.Data.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result.Data -Title "DisabledUsers"
                    }
                    Write-NetworkAdminAuditLog -Action "List Disabled Users" -Details "Count: $($result.Data.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "5" {
                Write-Host "Users with password never expires..." -ForegroundColor Yellow
                
                $operation = {
                    $queryResult = Invoke-NetworkAdminADQueryWithPaging -Filter "PasswordNeverExpires -eq `$true" -ObjectType "User" -Properties @("Name", "SamAccountName", "PasswordLastSet")
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "List Users with Non-Expiring Passwords", "", 3)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Users with non-expiring passwords: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.Data.Count -gt 0) {
                        Export-NetworkAdminResults -Data $result.Data -Title "NonExpiringPasswordUsers"
                    }
                    Write-NetworkAdminAuditLog -Action "List Non-Expiring Password Users" -Details "Count: $($result.Data.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "6" {
                $groupName = Read-Host "Enter group name"
                if ([string]::IsNullOrWhiteSpace($groupName)) {
                    Write-Host "Group name cannot be empty" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    $params = @{
                        Identity = $groupName
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    $members = Get-ADGroupMember @params
                    $userMembers = $members | Where-Object { $_.objectClass -eq 'user' }
                    
                    if ($userMembers.Count -gt 0) {
                        $userDetails = $userMembers | ForEach-Object {
                            Get-ADUser -Identity $_.SamAccountName -Properties Department -Server $script:CurrentDomain
                        }
                        return $userDetails | Select-Object Name, SamAccountName, Department
                    }
                    return @()
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "List Group Members", $groupName, 3)
                
                if ($null -ne $result) {
                    if ($result.Count -gt 0) {
                        Write-Host "User members of group '$groupName':" -ForegroundColor Yellow
                        $result | Format-Table -AutoSize
                        Export-NetworkAdminResults -Data $result -Title "GroupMembers_$groupName"
                    } else {
                        Write-Host "No user members found in group '$groupName'" -ForegroundColor Yellow
                    }
                    Write-NetworkAdminAuditLog -Action "List Group Members" -Target $groupName -Details "Count: $($result.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "7" {
                $username = Read-Host "Enter username"
                if ([string]::IsNullOrWhiteSpace($username)) {
                    Write-Host "Username cannot be empty" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    $params = @{
                        Identity = $username
                        Properties = @("LastLogonDate", "LastLogonTimestamp")
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    return Get-ADUser @params
                }
                
                $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($operation, "Check User Last Logon", $username, 3)
                
                if ($null -ne $result) {
                    Write-Host "User: $($result.Name)" -ForegroundColor Green
                    Write-Host "Last Logon Date: $($result.LastLogonDate)" -ForegroundColor Yellow
                    if ($result.LastLogonTimestamp) {
                        $lastLogon = [DateTime]::FromFileTime($result.LastLogonTimestamp)
                        Write-Host "Last Logon Timestamp: $lastLogon" -ForegroundColor Yellow
                    }
                    Write-NetworkAdminAuditLog -Action "Check User Last Logon" -Target $username -Details "LastLogon: $($result.LastLogonDate)"
                }
                
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}
