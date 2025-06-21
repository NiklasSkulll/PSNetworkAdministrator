# Group Management functions for NetworkAdmin module

function Invoke-NetworkAdminGroupManagement {
    [CmdletBinding()]
    param()
    
    do {
        Clear-Host
        Write-ConfigHost "=============== GROUP MANAGEMENT ===============" -ColorType "Success"
        Write-Host "1. List all groups"
        Write-Host "2. Search for specific group"
        Write-Host "3. Get group members"
        Write-Host "4. List empty groups"
        Write-Host "5. List groups by type"
        Write-Host "B. Back to main menu"
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" {
                Write-ConfigHost "Retrieving all groups..." -ColorType "Info"
                $operation = {
                    $params = @{
                        Filter = "*"
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    Get-ADGroup @params | Select-Object Name, GroupCategory, GroupScope
                }
                $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "List All Groups"
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-NetworkAdminAuditLog -Action "List All Groups" -Details "Count: $($result.Count)"
                } else {
                    Write-ConfigHost "Failed to retrieve groups. Please check domain connectivity." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "2" {
                $searchTerm = Read-Host "Enter group name or part of name"
                if (-not [string]::IsNullOrWhiteSpace($searchTerm)) {
                    $operation = {
                        $params = @{
                            Filter = "Name -like '*$searchTerm*'"
                            Server = $script:CurrentDomain
                            ErrorAction = 'Stop'
                        }
                        if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                        
                        Get-ADGroup @params | Select-Object Name, GroupCategory, GroupScope, Description
                    }
                    $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "Search Groups"
                    if ($null -ne $result) {
                        $result | Format-Table -AutoSize
                        Write-NetworkAdminAuditLog -Action "Search Groups" -Target $searchTerm -Details "Results: $($result.Count)"
                    } else {
                        Write-ConfigHost "Failed to search groups. Please check domain connectivity." -ColorType "Error"
                    }
                } else {
                    Write-ConfigHost "Search term cannot be empty." -ColorType "Warning"
                }
                Read-Host "Press Enter to continue"
            }
            "3" {
                $groupName = Read-Host "Enter group name"
                if (-not [string]::IsNullOrWhiteSpace($groupName)) {
                    Write-ConfigHost "Members of group: $groupName" -ColorType "Info"
                    $operation = {
                        $params = @{
                            Identity = $groupName
                            Server = $script:CurrentDomain
                            ErrorAction = 'Stop'
                        }
                        if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                        
                        Get-ADGroupMember @params | Select-Object Name, ObjectClass
                    }
                    $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "Get Group Members"
                    if ($null -ne $result) {
                        $result | Format-Table -AutoSize
                        Write-NetworkAdminAuditLog -Action "Get Group Members" -Target $groupName -Details "Members: $($result.Count)"
                    } else {
                        Write-ConfigHost "Failed to retrieve group members. Please verify the group name and domain connectivity." -ColorType "Error"
                    }
                } else {
                    Write-ConfigHost "Group name cannot be empty." -ColorType "Warning"
                }
                Read-Host "Press Enter to continue"
            }
            "4" {
                Write-ConfigHost "Finding empty groups..." -ColorType "Info"
                $operation = {
                    $params = @{
                        Filter = "*"
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    $groups = Get-ADGroup @params
                    $emptyGroups = @()
                    foreach ($group in $groups) {
                        try {
                            $memberParams = @{
                                Identity = $group
                                Server = $script:CurrentDomain
                                ErrorAction = 'SilentlyContinue'
                            }
                            if ($script:CurrentCredential) { $memberParams.Credential = $script:CurrentCredential }
                            
                            $members = Get-ADGroupMember @memberParams
                            if ($null -eq $members -or $members.Count -eq 0) {
                                $emptyGroups += $group.Name
                                Write-ConfigHost "Empty group: $($group.Name)" -ColorType "Warning"
                            }
                        }
                        catch {
                            Write-Verbose "Could not check members for group: $($group.Name)"
                        }
                    }
                    if ($emptyGroups.Count -eq 0) {
                        Write-ConfigHost "No empty groups found." -ColorType "Success"
                    } else {
                        Write-ConfigHost "Found $($emptyGroups.Count) empty groups." -ColorType "Info"
                    }
                    return $emptyGroups
                }
                $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "Find Empty Groups"
                if ($null -ne $result) {
                    Write-NetworkAdminAuditLog -Action "Find Empty Groups" -Details "Empty Groups: $($result.Count)"
                } else {
                    Write-ConfigHost "Failed to analyze groups. Please check domain connectivity." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "5" {
                Write-ConfigHost "Groups by type:" -ColorType "Info"
                $operation = {
                    $params = @{
                        Filter = "*"
                        Server = $script:CurrentDomain
                        ErrorAction = 'Stop'
                    }
                    if ($script:CurrentCredential) { $params.Credential = $script:CurrentCredential }
                    
                    Get-ADGroup @params | Group-Object GroupCategory | Select-Object Name, Count
                }
                $result = Invoke-NetworkAdminADOperationWithFailover -Operation $operation -OperationName "Group Types Analysis"
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-NetworkAdminAuditLog -Action "Group Types Analysis" -Details "Group Types: $($result.Count)"
                } else {
                    Write-ConfigHost "Failed to analyze group types. Please check domain connectivity." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}
