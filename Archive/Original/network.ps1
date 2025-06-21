# Network Administration Script
# Author: System Administrator
# Date: June 2025
# Description: Comprehensive network administration tool for company networks

param(
    [Parameter(Mandatory=$false)]
    [ValidatePattern('^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$Domain,
    
    [Parameter(Mandatory=$false)]
    [PSCredential]$Credential,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$PSScriptRoot\NetworkAdminLog.txt",
    
    [Parameter(Mandatory=$false)]
    [switch]$NoLog
)

# Script configuration and initialization
$script:Config = @{
    MaxRetries = 3
    TimeoutSeconds = 30
    DefaultDays = 30
    LogRetentionDays = 90
    PageSize = 1000
    LargeQueryThreshold = 5000
    NetworkTimeout = 10
    ADQueryTimeout = 60
    PingCount = 4
    ExportFormats = @("CSV", "JSON", "XML")
    DefaultExportFormat = "CSV"
    EnableProgressBars = $true
    ColorScheme = @{
        Success = "Green"
        Warning = "Yellow"
        Error = "Red"
        Info = "Cyan"
        Header = "Cyan"
    }
    Features = @{
        EnableExport = $true
        EnableLogging = $true
        EnableProgressBars = $true
        EnableInputValidation = $true
        EnableRetryMechanism = $true
        EnableDetailedErrorMessages = $true
    }
    Performance = @{
        UseParallelProcessing = $false
        MaxConcurrentOperations = 5
        CacheResults = $true
        CacheExpirationMinutes = 15
    }
}

# Load configuration file if it exists
$ConfigPath = Join-Path $PSScriptRoot "..\config.json"
if (Test-Path $ConfigPath) {
    try {
        $configData = Get-Content $ConfigPath | ConvertFrom-Json
        
        # Merge configuration settings properly
        foreach ($property in $configData.PSObject.Properties) {
            if ($property.Value -is [PSCustomObject]) {
                # Handle nested objects (like ColorScheme, Features, Performance)
                if (-not $script:Config.ContainsKey($property.Name)) {
                    $script:Config[$property.Name] = @{}
                }
                foreach ($nestedProperty in $property.Value.PSObject.Properties) {
                    $script:Config[$property.Name][$nestedProperty.Name] = $nestedProperty.Value
                }
            } else {
                # Handle simple properties
                $script:Config[$property.Name] = $property.Value
            }
        }
        
        Write-ConfigHost "Configuration loaded from $ConfigPath" -ColorType "Success"
    } catch {
        Write-Warning "Failed to load configuration file. Using defaults."
    }
}

# PowerShell classes for better object-oriented design
class ADQueryResult {
    [object[]]$Data
    [int]$TotalCount
    [bool]$IsTruncated
    [string]$ErrorMessage
    
    ADQueryResult([object[]]$data, [int]$totalCount, [bool]$isTruncated) {
        $this.Data = $data
        $this.TotalCount = $totalCount
        $this.IsTruncated = $isTruncated
        $this.ErrorMessage = ""
    }
}

class RetryOperation {
    static [object] Execute([scriptblock]$operation, [int]$maxRetries = 3, [int]$delaySeconds = 2) {
        $attempt = 0
        do {
            $attempt++
            try {
                return & $operation
            }            catch {
                Write-Verbose "Attempt $attempt failed: $($_.Exception.Message)"
                if ($attempt -ge $maxRetries) {
                    throw $_
                }
                Start-Sleep -Seconds $delaySeconds
            }
        } while ($attempt -lt $maxRetries)
        
        # This should never be reached due to the throw above, but satisfies compiler
        return $null
    }
}

# Enhanced AD query function with paging and timeout
function Invoke-ADQueryWithPaging {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Filter,
        [Parameter(Mandatory=$false)]
        [string[]]$Properties = @(),
        [Parameter(Mandatory=$false)]
        [string]$SearchBase = "",
        [Parameter(Mandatory=$false)]
        [ValidateSet("User", "Computer", "Group")]
        [string]$ObjectType = "User",
        [Parameter(Mandatory=$false)]
        [int]$PageSize = $script:Config.PageSize,
        [Parameter(Mandatory=$false)]
        [int]$MaxResults = 0
    )
    
    try {
        $params = @{
            Filter = $Filter
            Server = $script:Domain
            ResultPageSize = $PageSize
            ErrorAction = 'Stop'
        }
        
        if ($Properties.Count -gt 0) {
            $params.Properties = $Properties
        }
        
        if (-not [string]::IsNullOrEmpty($SearchBase)) {
            $params.SearchBase = $SearchBase
        }
        
        if ($Credential) {
            $params.Credential = $Credential
        }
        
        # Add timeout using job
        $job = Start-Job -ScriptBlock {
            param($ObjectType, $params)
            switch ($ObjectType) {
                "User" { Get-ADUser @params }
                "Computer" { Get-ADComputer @params }
                "Group" { Get-ADGroup @params }
            }
        } -ArgumentList $ObjectType, $params
        
        $result = $job | Wait-Job -Timeout $script:Config.ADQueryTimeout | Receive-Job
        Remove-Job $job -Force
        
        if ($null -eq $result) {
            throw "AD query timed out after $($script:Config.ADQueryTimeout) seconds"
        }
        
        $totalCount = ($result | Measure-Object).Count
        $isTruncated = $MaxResults -gt 0 -and $totalCount -ge $MaxResults
        
        if ($MaxResults -gt 0 -and $totalCount -gt $MaxResults) {
            $result = $result | Select-Object -First $MaxResults
        }
        
        return [ADQueryResult]::new($result, $totalCount, $isTruncated)
    }
    catch {
        $errorResult = [ADQueryResult]::new(@(), 0, $false)
        $errorResult.ErrorMessage = $_.Exception.Message
        return $errorResult
    }
}

# Enhanced network operation with timeout
function Invoke-NetworkOperationWithTimeout {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = $script:Config.NetworkTimeout,
        [Parameter(Mandatory=$false)]
        [string]$OperationName = "Network Operation"
    )
    
    try {
        $job = Start-Job -ScriptBlock $Operation
        $result = $job | Wait-Job -Timeout $TimeoutSeconds | Receive-Job
        Remove-Job $job -Force
        
        if ($null -eq $result -and $job.State -eq "Running") {
            throw "Operation '$OperationName' timed out after $TimeoutSeconds seconds"
        }
        
        return $result
    }    catch {
        Write-Error "Failed to execute $OperationName : $($_.Exception.Message)"
        return $null
    }
}

# Enhanced error handling class
class ErrorHandler {
    static [void] HandleADError([System.Management.Automation.ErrorRecord]$errorRecord, [string]$operation, [string]$target = "") {        $errorMessage = switch -Regex ($errorRecord.Exception.Message) {
            ".*not found.*|.*does not exist.*" { "Object '$target' not found in Active Directory" }
            ".*access.*denied.*|.*unauthorized.*" { "Access denied. Insufficient permissions for '$operation'" }
            ".*timeout.*|.*time.*out.*" { "Operation '$operation' timed out. The domain controller may be busy or unreachable" }
            ".*network.*|.*connection.*" { "Network connectivity issue. Unable to reach domain controller" }
            ".*invalid.*filter.*" { "Invalid search filter specified for '$operation'" }
            ".*quota.*exceeded.*" { "AD query quota exceeded. Try using more specific filters" }
            default { "AD operation '$operation' failed: $($errorRecord.Exception.Message)" }
        }
        
        Write-ConfigHost "✗ $errorMessage" -ColorType "Error"
        Write-AuditLog -Action $operation -Target $target -Result "Failed" -Details $errorMessage
    }
    
    static [void] HandleNetworkError([System.Management.Automation.ErrorRecord]$errorRecord, [string]$operation, [string]$target = "") {        $errorMessage = switch -Regex ($errorRecord.Exception.Message) {
            ".*timeout.*|.*time.*out.*" { "Network timeout while connecting to '$target'" }
            ".*unreachable.*|.*not.*reachable.*" { "Host '$target' is unreachable" }
            ".*refused.*|.*connection.*refused.*" { "Connection refused by '$target'" }
            ".*resolution.*failed.*|.*name.*not.*resolved.*" { "DNS resolution failed for '$target'" }
            default { "Network operation '$operation' failed: $($errorRecord.Exception.Message)" }
        }
        
        Write-ConfigHost "✗ $errorMessage" -ColorType "Error"
        Write-AuditLog -Action $operation -Target $target -Result "Failed" -Details $errorMessage
    }
    
    static [object] ExecuteWithRetry([scriptblock]$operation, [string]$operationName, [string]$target = "", [int]$maxRetries = 3) {
        $attempt = 0
        $lastError = $null
        
        do {
            $attempt++
            try {
                Show-Progress -Activity $operationName -Status "Attempt $attempt of $maxRetries..." -PercentComplete (($attempt - 1) * 100 / $maxRetries)
                $result = & $operation
                Write-Progress -Activity $operationName -Completed
                return $result
            }
            catch {
                $lastError = $_
                Write-Verbose "Attempt $attempt failed for '$operationName': $($_.Exception.Message)"
                
                if ($attempt -lt $maxRetries) {
                    $delay = [math]::Min(2 * $attempt, 10) # Exponential backoff with max 10 seconds
                    Write-ConfigHost "Retrying in $delay seconds..." -ColorType "Warning"
                    Start-Sleep -Seconds $delay
                }
            }
        } while ($attempt -lt $maxRetries)
        
        # All retries failed
        Write-Progress -Activity $operationName -Completed
        if ($target -and ($lastError.Exception.Message -match "Active Directory|AD|LDAP")) {
            [ErrorHandler]::HandleADError($lastError, $operationName, $target)
        } elseif ($target -and ($lastError.Exception.Message -match "network|connection|ping|resolve")) {
            [ErrorHandler]::HandleNetworkError($lastError, $operationName, $target)
        } else {
            Write-ConfigHost "✗ Operation '$operationName' failed after $maxRetries attempts: $($lastError.Exception.Message)" -ColorType "Error"
            Write-AuditLog -Action $operationName -Target $target -Result "Failed" -Details "Failed after $maxRetries attempts: $($lastError.Exception.Message)"
        }
        
        return $null
    }
}

# Simple caching mechanism
$script:Cache = @{}

function Get-CachedResult {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,
        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,
        [Parameter(Mandatory=$false)]
        [int]$ExpirationMinutes = $script:Config.Performance.CacheExpirationMinutes
    )
    
    if (-not $script:Config.Performance.CacheResults) {
        return & $Operation
    }
    
    $now = Get-Date
    
    # Check if we have a cached result that's still valid
    if ($script:Cache.ContainsKey($Key)) {
        $cachedItem = $script:Cache[$Key]
        $expirationTime = $cachedItem.Timestamp.AddMinutes($ExpirationMinutes)
        
        if ($now -lt $expirationTime) {
            Write-Verbose "Using cached result for: $Key"
            return $cachedItem.Data
        } else {
            Write-Verbose "Cache expired for: $Key"
            $script:Cache.Remove($Key)
        }
    }
    
    # Execute operation and cache result
    Write-Verbose "Executing and caching result for: $Key"
    $result = & $Operation
    $script:Cache[$Key] = @{
        Data = $result
        Timestamp = $now
    }
    
    return $result
}

# Initialize logging
if (-not $NoLog) {
    try {
        if (-not (Test-Path (Split-Path $LogPath -Parent))) {
            New-Item -ItemType Directory -Path (Split-Path $LogPath -Parent) -Force | Out-Null
        }
        
        # Clean old log entries if needed
        if (Test-Path $LogPath) {
            $cutoffDate = (Get-Date).AddDays(-$script:Config.LogRetentionDays)
            $logContent = Get-Content $LogPath | Where-Object {
                $line = $_
                if ($line -match '^(\d{4}-\d{2}-\d{2})') {
                    [DateTime]::Parse($matches[1]) -gt $cutoffDate
                } else {
                    $true
                }
            }
            $logContent | Set-Content $LogPath
        }
        
        Write-AuditLog -Action "Script Started" -Details "Version: June 2025"
    }
    catch {
        Write-Warning "Failed to initialize logging: $($_.Exception.Message)"
    }
}

# Clear screen and show banner
Clear-Host
Write-ConfigHost "================================================" -ColorType "Header"
Write-ConfigHost "    Company Network Administration Tool" -ColorType "Info"
Write-ConfigHost "================================================" -ColorType "Header"
Write-Host ""

# Function to get domain name from user if not provided
function Get-DomainName {
    if (-not $Domain) {
        do {
            $script:Domain = Read-Host "Please enter the domain name (e.g., company.local)"
            if ([string]::IsNullOrWhiteSpace($script:Domain)) {
                Write-Host "Domain name cannot be empty. Please try again." -ForegroundColor Red
            } elseif (-not (Test-ValidInput -Input $script:Domain -Type "Domain")) {
                Write-Host "Invalid domain format. Please enter a valid domain name (e.g., company.local)" -ForegroundColor Red
                $script:Domain = ""
            }
        } while ([string]::IsNullOrWhiteSpace($script:Domain))
    } else {
        if (-not (Test-ValidInput -Input $Domain -Type "Domain")) {
            Write-Host "Warning: Domain parameter may not be in valid format" -ForegroundColor Yellow
        }
        $script:Domain = $Domain
    }
    Write-Host "Working with domain: $script:Domain" -ForegroundColor Green
    Write-Host ""
}

# Function to test domain connectivity
function Test-DomainConnectivity {
    Write-Host "Testing connectivity to domain: $script:Domain" -ForegroundColor Yellow
    Show-Progress -Activity "Domain Connectivity" -Status "Testing connection..."
    
    try {
        $params = @{
            Domain = $script:Domain
            ErrorAction = 'Stop'
        }
        if ($Credential) {
            $params.Credential = $Credential
        }
        
        $domainController = (Get-ADDomainController @params).HostName
        Write-ConfigHost "✓ Successfully connected to domain controller: $domainController" -ColorType "Success"
        Write-AuditLog -Action "Domain Connection Test" -Target $script:Domain -Result "Success" -Details "DC: $domainController"
        Write-Progress -Activity "Domain Connectivity" -Completed
        return $true
    }
    catch {
        Write-ConfigHost "✗ Unable to connect to domain: $($_.Exception.Message)" -ColorType "Error"
        Write-AuditLog -Action "Domain Connection Test" -Target $script:Domain -Result "Failed" -Details $_.Exception.Message
        Write-Progress -Activity "Domain Connectivity" -Completed
        return $false
    }
}

# Function to display main menu
function Show-MainMenu {
    Write-ConfigHost "==================== MAIN MENU ====================" -ColorType "Header"
    Write-Host "1.  User Management" -ForegroundColor White
    Write-Host "2.  Computer Management" -ForegroundColor White
    Write-Host "3.  Group Management" -ForegroundColor White
    Write-Host "4.  Network Diagnostics" -ForegroundColor White
    Write-Host "5.  DNS Management" -ForegroundColor White
    Write-Host "6.  DHCP Information" -ForegroundColor White
    Write-Host "7.  Domain Controller Info" -ForegroundColor White
    Write-Host "8.  Security & Audit" -ForegroundColor White
    Write-Host "9.  System Health Check" -ForegroundColor White
    Write-Host "10. Change Domain" -ForegroundColor White
    Write-ConfigHost "H.  Help" -ColorType "Info"
    Write-ConfigHost "Q.  Quit" -ColorType "Error"
    Write-ConfigHost "===================================================" -ColorType "Header"
}

# Function for User Management
function Invoke-UserManagement {
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
                    $queryResult = Invoke-ADQueryWithPaging -Filter "*" -ObjectType "User" -Properties @("Name", "SamAccountName", "Enabled") -MaxResults $script:Config.LargeQueryThreshold
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [ErrorHandler]::ExecuteWithRetry($operation, "List All Users", "", $script:Config.MaxRetries)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Users found: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.IsTruncated) {
                        Write-Host "⚠️  Results truncated to $($script:Config.LargeQueryThreshold) users for performance. Use search for specific queries." -ForegroundColor Yellow
                    }
                    
                    if ($result.Data.Count -gt 0) {
                        Export-Results -Data $result.Data -Title "AllUsers"
                    }
                    Write-AuditLog -Action "List All Users" -Details "Count: $($result.Data.Count), Truncated: $($result.IsTruncated)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "2" {
                $searchTerm = Read-Host "Enter username or part of name to search"
                if (-not (Test-ValidInput -Input $searchTerm -Type "UserName") -and $searchTerm.Length -lt 2) {
                    Write-Host "Please enter at least 2 characters for search" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    $filter = "Name -like '*$searchTerm*' -or SamAccountName -like '*$searchTerm*'"
                    $queryResult = Invoke-ADQueryWithPaging -Filter $filter -ObjectType "User" -Properties @("Name", "SamAccountName", "Enabled")
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [ErrorHandler]::ExecuteWithRetry($operation, "Search Users", $searchTerm, $script:Config.MaxRetries)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Users found: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.Data.Count -gt 0) {
                        Export-Results -Data $result.Data -Title "UserSearch_$searchTerm"
                    }
                    Write-AuditLog -Action "Search Users" -Target $searchTerm -Details "Results: $($result.Data.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }            "3" {
                $username = Read-Host "Enter username"
                if ([string]::IsNullOrWhiteSpace($username)) {
                    Write-Host "Username cannot be empty" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    $params = @{
                        Identity = $username
                        Properties = "*"
                        Server = $script:Domain
                        ErrorAction = 'Stop'
                    }
                    if ($Credential) { $params.Credential = $Credential }
                    
                    Get-ADUser @params | Select-Object Name, SamAccountName, EmailAddress, Department, Title, LastLogonDate, PasswordLastSet, Enabled
                }
                
                $result = [ErrorHandler]::ExecuteWithRetry($operation, "Get User Details", $username, $script:Config.MaxRetries)
                
                if ($null -ne $result) {
                    $result | Format-List
                    Write-AuditLog -Action "Get User Details" -Target $username -Details "Success"
                }
                
                Read-Host "Press Enter to continue"
            }
            "4" {
                Write-Host "Retrieving disabled users..." -ForegroundColor Yellow
                
                $operation = {
                    $queryResult = Invoke-ADQueryWithPaging -Filter "Enabled -eq `$false" -ObjectType "User" -Properties @("Name", "SamAccountName", "LastLogonDate")
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [ErrorHandler]::ExecuteWithRetry($operation, "List Disabled Users", "", $script:Config.MaxRetries)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Disabled users found: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.Data.Count -gt 0) {
                        Export-Results -Data $result.Data -Title "DisabledUsers"
                    }
                    Write-AuditLog -Action "List Disabled Users" -Details "Count: $($result.Data.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "5" {
                Write-Host "Users with password never expires..." -ForegroundColor Yellow
                
                $operation = {
                    $queryResult = Invoke-ADQueryWithPaging -Filter "PasswordNeverExpires -eq `$true" -ObjectType "User" -Properties @("Name", "SamAccountName", "PasswordLastSet")
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [ErrorHandler]::ExecuteWithRetry($operation, "List Users with Non-Expiring Passwords", "", $script:Config.MaxRetries)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Users with non-expiring passwords: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.Data.Count -gt 0) {
                        Export-Results -Data $result.Data -Title "NonExpiringPasswordUsers"
                    }
                    Write-AuditLog -Action "List Non-Expiring Password Users" -Details "Count: $($result.Data.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }            "6" {
                $groupName = Read-Host "Enter group name"
                if ([string]::IsNullOrWhiteSpace($groupName)) {
                    Write-Host "Group name cannot be empty" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    $params = @{
                        Identity = $groupName
                        Server = $script:Domain
                        ErrorAction = 'Stop'
                    }
                    if ($Credential) { $params.Credential = $Credential }
                    
                    $members = Get-ADGroupMember @params
                    $userMembers = $members | Where-Object { $_.objectClass -eq 'user' }
                    
                    if ($userMembers.Count -gt 0) {
                        $userDetails = $userMembers | ForEach-Object {
                            Get-ADUser -Identity $_.SamAccountName -Properties Department -Server $script:Domain
                        }
                        return $userDetails | Select-Object Name, SamAccountName, Department
                    }
                    return @()
                }
                
                $result = [ErrorHandler]::ExecuteWithRetry($operation, "List Group Members", $groupName, $script:Config.MaxRetries)
                
                if ($null -ne $result) {
                    if ($result.Count -gt 0) {
                        Write-Host "User members of group '$groupName':" -ForegroundColor Yellow
                        $result | Format-Table -AutoSize
                        Export-Results -Data $result -Title "GroupMembers_$groupName"
                    } else {
                        Write-Host "No user members found in group '$groupName'" -ForegroundColor Yellow
                    }
                    Write-AuditLog -Action "List Group Members" -Target $groupName -Details "Count: $($result.Count)"
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
                        Server = $script:Domain
                        ErrorAction = 'Stop'
                    }
                    if ($Credential) { $params.Credential = $Credential }
                    
                    return Get-ADUser @params
                }
                
                $result = [ErrorHandler]::ExecuteWithRetry($operation, "Check User Last Logon", $username, $script:Config.MaxRetries)
                
                if ($null -ne $result) {
                    Write-Host "User: $($result.Name)" -ForegroundColor Green
                    Write-Host "Last Logon Date: $($result.LastLogonDate)" -ForegroundColor Yellow
                    if ($result.LastLogonTimestamp) {
                        $lastLogon = [DateTime]::FromFileTime($result.LastLogonTimestamp)
                        Write-Host "Last Logon Timestamp: $lastLogon" -ForegroundColor Yellow
                    }
                    Write-AuditLog -Action "Check User Last Logon" -Target $username -Details "LastLogon: $($result.LastLogonDate)"
                }
                
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}

# Function for Computer Management
function Invoke-ComputerManagement {
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
                    $queryResult = Invoke-ADQueryWithPaging -Filter "*" -ObjectType "Computer" -Properties @("Name", "DNSHostName", "Enabled", "OperatingSystem") -MaxResults $script:Config.LargeQueryThreshold
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [ErrorHandler]::ExecuteWithRetry($operation, "List All Computers", "", $script:Config.MaxRetries)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Computers found: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.IsTruncated) {
                        Write-Host "⚠️  Results truncated to $($script:Config.LargeQueryThreshold) computers for performance. Use search for specific queries." -ForegroundColor Yellow
                    }
                    
                    if ($result.Data.Count -gt 0) {
                        Export-Results -Data $result.Data -Title "AllComputers"
                    }
                    Write-AuditLog -Action "List All Computers" -Details "Count: $($result.Data.Count), Truncated: $($result.IsTruncated)"
                }
                
                Read-Host "Press Enter to continue"
            }            "2" {
                $searchTerm = Read-Host "Enter computer name or part of name"
                if ([string]::IsNullOrWhiteSpace($searchTerm) -or $searchTerm.Length -lt 2) {
                    Write-Host "Please enter at least 2 characters for search" -ForegroundColor Red
                    continue
                }
                
                $operation = {
                    $filter = "Name -like '*$searchTerm*'"
                    $queryResult = Invoke-ADQueryWithPaging -Filter $filter -ObjectType "Computer" -Properties @("Name", "DNSHostName", "OperatingSystem", "LastLogonDate", "Enabled")
                    
                    if (-not [string]::IsNullOrEmpty($queryResult.ErrorMessage)) {
                        throw $queryResult.ErrorMessage
                    }
                    
                    return $queryResult
                }
                
                $result = [ErrorHandler]::ExecuteWithRetry($operation, "Search Computers", $searchTerm, $script:Config.MaxRetries)
                
                if ($null -ne $result) {
                    $result.Data | Format-Table -AutoSize
                    Write-Host "Computers found: $($result.Data.Count)" -ForegroundColor Cyan
                    
                    if ($result.Data.Count -gt 0) {
                        Export-Results -Data $result.Data -Title "ComputerSearch_$searchTerm"
                    }
                    Write-AuditLog -Action "Search Computers" -Target $searchTerm -Details "Results: $($result.Data.Count)"
                }
                
                Read-Host "Press Enter to continue"
            }
            "3" {
                $computerName = Read-Host "Enter computer name"
                try {
                    Get-ADComputer -Identity $computerName -Properties * -Server $script:Domain |
                    Select-Object Name, DNSHostName, OperatingSystem, OperatingSystemVersion, LastLogonDate, Created | Format-List
                }
                catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red }
                Read-Host "Press Enter to continue"
            }
            "4" {
                Write-Host "Computers by Operating System:" -ForegroundColor Yellow
                try {
                    Get-ADComputer -Filter * -Properties OperatingSystem -Server $script:Domain |
                    Group-Object OperatingSystem | Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize                }
                catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red }
                Read-Host "Press Enter to continue"
            }            "5" {
                $computerName = Read-Host "Enter computer name to ping"
                if (-not (Test-ValidInput -Input $computerName -Type "ComputerName")) {
                    Write-Host "Invalid computer name format" -ForegroundColor Red
                    continue
                }
                
                Write-Host "Testing connectivity to $computerName..." -ForegroundColor Yellow
                
                $pingOperation = {
                    $pingParams = @{
                        ComputerName = $computerName
                        Count = $script:Config.PingCount
                        Quiet = $true
                        ErrorAction = 'Stop'
                    }
                    Test-Connection @pingParams
                }
                
                $result = Invoke-NetworkOperationWithTimeout -Operation $pingOperation -TimeoutSeconds $script:Config.NetworkTimeout -OperationName "Ping Test"
                
                if ($null -ne $result) {
                    if ($result) {
                        Write-Host "✓ $computerName is online" -ForegroundColor Green
                        Write-AuditLog -Action "Ping Test" -Target $computerName -Result "Online"
                        
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
                        Write-AuditLog -Action "Ping Test" -Target $computerName -Result "Offline"
                    }
                } else {
                    Write-AuditLog -Action "Ping Test" -Target $computerName -Result "Failed" -Details "Operation timed out"
                }
                
                Read-Host "Press Enter to continue"
            }"6" {
                $days = Read-Host "Show computers inactive for how many days? (default: 30)"
                if ([string]::IsNullOrWhiteSpace($days)) { 
                    $days = 30 
                } elseif (-not (Test-ValidInput -Input $days -Type "Number")) {
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
                Show-Progress -Activity "Computer Management" -Status "Finding inactive computers..."
                
                try {
                    $inactiveComputers = Get-ADComputer -Filter * -Properties LastLogonDate -Server $script:Domain |
                        Where-Object { $_.LastLogonDate -lt $cutoffDate -or $null -eq $_.LastLogonDate } |
                        Select-Object Name, LastLogonDate, Enabled | Sort-Object LastLogonDate
                    
                    $inactiveComputers | Format-Table -AutoSize
                    Write-Host "Inactive computers found: $($inactiveComputers.Count)" -ForegroundColor Cyan
                    
                    if ($inactiveComputers.Count -gt 0) {
                        Export-Results -Data $inactiveComputers -Title "InactiveComputers_$($days)days"
                    }
                    Write-AuditLog -Action "Find Inactive Computers" -Details "Days: $days, Count: $($inactiveComputers.Count)"
                }
                catch { 
                    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red 
                    Write-AuditLog -Action "Find Inactive Computers" -Result "Failed" -Details $_.Exception.Message
                }
                finally { Write-Progress -Activity "Computer Management" -Completed }
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}

# Function for Group Management
function Invoke-GroupManagement {
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
                    Get-ADGroup -Filter * -Server $script:Domain | 
                    Select-Object Name, GroupCategory, GroupScope | Format-Table -AutoSize
                }
                $result = Invoke-ADOperationWithFailover -Operation $operation -OperationName "List All Groups"
                if ($null -eq $result) {
                    Write-ConfigHost "Failed to retrieve groups. Please check domain connectivity." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "2" {
                $searchTerm = Read-Host "Enter group name or part of name"
                if (-not [string]::IsNullOrWhiteSpace($searchTerm)) {
                    $operation = {
                        Get-ADGroup -Filter "Name -like '*$searchTerm*'" -Server $script:Domain |
                        Select-Object Name, GroupCategory, GroupScope, Description | Format-Table -AutoSize
                    }
                    $result = Invoke-ADOperationWithFailover -Operation $operation -OperationName "Search Groups"
                    if ($null -eq $result) {
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
                        Get-ADGroupMember -Identity $groupName -Server $script:Domain |
                        Select-Object Name, ObjectClass | Format-Table -AutoSize
                    }
                    $result = Invoke-ADOperationWithFailover -Operation $operation -OperationName "Get Group Members"
                    if ($null -eq $result) {
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
                    $groups = Get-ADGroup -Filter * -Server $script:Domain
                    $emptyGroups = @()
                    foreach ($group in $groups) {
                        try {
                            $members = Get-ADGroupMember -Identity $group -Server $script:Domain -ErrorAction SilentlyContinue
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
                $result = Invoke-ADOperationWithFailover -Operation $operation -OperationName "Find Empty Groups"
                if ($null -eq $result) {
                    Write-ConfigHost "Failed to analyze groups. Please check domain connectivity." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "5" {
                Write-ConfigHost "Groups by type:" -ColorType "Info"
                $operation = {
                    Get-ADGroup -Filter * -Server $script:Domain |
                    Group-Object GroupCategory | Select-Object Name, Count | Format-Table -AutoSize
                }
                $result = Invoke-ADOperationWithFailover -Operation $operation -OperationName "Group Types Analysis"
                if ($null -eq $result) {
                    Write-ConfigHost "Failed to analyze group types. Please check domain connectivity." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}

# Function for Network Diagnostics
function Invoke-NetworkDiagnostics {
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
                
                $count = Read-Host "Number of pings (default: $($script:Config.PingCount))"
                if ([string]::IsNullOrWhiteSpace($count)) { 
                    $count = $script:Config.PingCount 
                } elseif (-not (Test-ValidInput -Input $count -Type "Number")) {
                    Write-Host "Invalid number. Using default." -ForegroundColor Yellow
                    $count = $script:Config.PingCount
                }
                
                $pingOperation = {
                    Test-Connection -ComputerName $target -Count $count -ErrorAction Stop
                }
                
                $result = Invoke-NetworkOperationWithTimeout -Operation $pingOperation -TimeoutSeconds ($script:Config.NetworkTimeout * 2) -OperationName "Ping Test"
                
                if ($null -ne $result) {
                    $result | Format-Table -AutoSize
                    Write-AuditLog -Action "Ping Test" -Target $target -Details "Count: $count, Success: $($result.Count)"
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
                
                if (-not (Test-ValidInput -Input $port -Type "Number")) {
                    Write-Host "Invalid port number" -ForegroundColor Red
                    continue
                }
                
                $portTestOperation = {
                    $result = Test-NetConnection -ComputerName $target -Port $port -ErrorAction Stop
                    return $result
                }
                
                $result = Invoke-NetworkOperationWithTimeout -Operation $portTestOperation -TimeoutSeconds $script:Config.NetworkTimeout -OperationName "Port Connectivity Test"
                
                if ($null -ne $result) {
                    if ($result.TcpTestSucceeded) {
                        Write-Host "✓ Port $port is open on $target" -ForegroundColor Green
                        Write-Host "  Remote Address: $($result.RemoteAddress)" -ForegroundColor Cyan
                        Write-Host "  Source Address: $($result.SourceAddress.IPAddress)" -ForegroundColor Cyan
                    } else {
                        Write-Host "✗ Port $port is closed on $target" -ForegroundColor Red
                    }
                    Write-AuditLog -Action "Port Test" -Target "$target`:$port" -Result $(if ($result.TcpTestSucceeded) { "Open" } else { "Closed" })
                }
                
                Read-Host "Press Enter to continue"
            }
            "3" {
                $hostname = Read-Host "Enter hostname to resolve"
                try {
                    Resolve-DnsName -Name $hostname | Format-Table
                }
                catch { Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red }
                Read-Host "Press Enter to continue"
            }
            "4" {
                Write-Host "Network adapter information:" -ForegroundColor Yellow
                Get-NetAdapter | Select-Object Name, InterfaceDescription, LinkSpeed, Status | Format-Table -AutoSize
                Read-Host "Press Enter to continue"
            }
            "5" {
                Write-Host "Route table:" -ForegroundColor Yellow
                Get-NetRoute | Where-Object {$_.RouteMetric -ne 256} | 
                Select-Object DestinationPrefix, NextHop, RouteMetric, ifIndex | Format-Table -AutoSize
                Read-Host "Press Enter to continue"
            }
            "6" {
                Write-Host "ARP table:" -ForegroundColor Yellow
                Get-NetNeighbor | Where-Object {$_.State -ne "Unreachable"} |
                Select-Object IPAddress, LinkLayerAddress, State | Format-Table -AutoSize
                Read-Host "Press Enter to continue"
            }
            "7" {
                Write-Host "Network statistics:" -ForegroundColor Yellow
                Get-NetAdapterStatistics | Select-Object Name, BytesReceived, BytesSent, PacketsReceived, PacketsSent | Format-Table -AutoSize
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}

# Function for DNS Management
function Invoke-DNSManagement {
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
                            return Resolve-DnsName -Name $hostname | Format-Table
                        } else {
                            return Resolve-DnsName -Name $hostname -Type $recordType | Format-Table
                        }
                    }
                    
                    # Fallback with different DNS servers
                    $fallbackOperations = @(
                        { 
                            Write-Verbose "Trying with Google DNS (8.8.8.8)"
                            if ([string]::IsNullOrWhiteSpace($recordType)) {
                                return Resolve-DnsName -Name $hostname -Server "8.8.8.8" | Format-Table
                            } else {
                                return Resolve-DnsName -Name $hostname -Type $recordType -Server "8.8.8.8" | Format-Table
                            }
                        },
                        { 
                            Write-Verbose "Trying with Cloudflare DNS (1.1.1.1)"
                            if ([string]::IsNullOrWhiteSpace($recordType)) {
                                return Resolve-DnsName -Name $hostname -Server "1.1.1.1" | Format-Table
                            } else {
                                return Resolve-DnsName -Name $hostname -Type $recordType -Server "1.1.1.1" | Format-Table
                            }
                        }
                    )
                    
                    $result = Invoke-NetworkOperationWithFallback -PrimaryOperation $primaryOperation -FallbackOperations $fallbackOperations -OperationName "DNS Query for $hostname"
                    if ($null -eq $result) {
                        Write-ConfigHost "Failed to resolve $hostname using all available DNS servers." -ColorType "Error"
                    }
                } else {
                    Write-ConfigHost "Hostname cannot be empty." -ColorType "Warning"
                }
                Read-Host "Press Enter to continue"
            }
            "2" {
                Write-ConfigHost "DNS Server Configuration:" -ColorType "Info"
                $operation = {
                    return Get-DnsClientServerAddress | Format-Table
                }
                $result = Invoke-NetworkOperationWithFallback -PrimaryOperation $operation -OperationName "Get DNS Server Configuration"
                if ($null -eq $result) {
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
                $result = Invoke-NetworkOperationWithFallback -PrimaryOperation $operation -OperationName "Flush DNS Cache"
                if ($null -ne $result) {
                    Write-ConfigHost "✓ $result" -ColorType "Success"
                } else {
                    Write-ConfigHost "Failed to flush DNS cache." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "4" {
                $operation = {
                    Import-Module DnsServer -ErrorAction Stop
                    Write-ConfigHost "DNS Zones:" -ColorType "Info"
                    return Get-DnsServerZone | Select-Object ZoneName, ZoneType, DynamicUpdate | Format-Table -AutoSize
                }
                
                $fallbackOperation = {
                    # Fallback: try to get zone info via WMI if available
                    try {
                        $zones = Get-CimInstance -ClassName MicrosoftDNS_Zone -Namespace "root\MicrosoftDNS" -ErrorAction SilentlyContinue
                        if ($zones) {
                            Write-ConfigHost "DNS Zones (via WMI):" -ColorType "Info"
                            return $zones | Select-Object Name, ZoneType | Format-Table -AutoSize
                        }
                    }
                    catch {
                        throw "DNS Server module and WMI access not available"
                    }
                }
                
                $result = Invoke-NetworkOperationWithFallback -PrimaryOperation $operation -FallbackOperations @($fallbackOperation) -OperationName "Get DNS Zones"
                if ($null -eq $result) {
                    Write-ConfigHost "DNS Server module not available and no alternative access method found. This feature requires DNS Server role or WMI access." -ColorType "Warning"
                }
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}

# Function for DHCP Information
function Invoke-DHCPInfo {
    Clear-Host
    Write-ConfigHost "================ DHCP INFORMATION ===============" -ColorType "Success"
    
    # Primary operation for IP configuration
    $ipConfigOperation = {
        Write-ConfigHost "Current IP Configuration:" -ColorType "Info"
        return Get-NetIPConfiguration | Where-Object {$_.NetAdapter.Status -eq "Up"} |
        Select-Object InterfaceAlias, IPv4Address, IPv4DefaultGateway, DNSServer | Format-List
    }
    
    $result = Invoke-NetworkOperationWithFallback -PrimaryOperation $ipConfigOperation -OperationName "Get IP Configuration"
    if ($null -eq $result) {
        Write-ConfigHost "Failed to retrieve IP configuration." -ColorType "Error"
    }
    
    # DHCP interface information
    $dhcpInterfaceOperation = {
        Write-ConfigHost "`nDHCP Client Information:" -ColorType "Info"
        return Get-NetIPInterface | Where-Object {$_.Dhcp -eq "Enabled"} |
        Select-Object InterfaceAlias, AddressFamily, Dhcp | Format-Table
    }
    
    $result = Invoke-NetworkOperationWithFallback -PrimaryOperation $dhcpInterfaceOperation -OperationName "Get DHCP Interface Information"
    if ($null -eq $result) {
        Write-ConfigHost "Failed to retrieve DHCP interface information." -ColorType "Error"
    }
    
    # DHCP lease information with fallback methods
    Write-ConfigHost "`nTrying to get DHCP lease information..." -ColorType "Info"
    
    $primaryLeaseOperation = {
        $dhcpInfo = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object {$_.DHCPEnabled -eq $true}
        $results = @()
        foreach ($adapter in $dhcpInfo) {
            $results += @{
                Interface = $adapter.Description
                DHCPServer = $adapter.DHCPServer
                LeaseObtained = $adapter.DHCPLeaseObtained
                LeaseExpires = $adapter.DHCPLeaseExpires
            }
            Write-ConfigHost "Interface: $($adapter.Description)" -ColorType "Info"
            Write-Host "  DHCP Server: $($adapter.DHCPServer)"
            Write-Host "  Lease Obtained: $($adapter.DHCPLeaseObtained)"
            Write-Host "  Lease Expires: $($adapter.DHCPLeaseExpires)"
            Write-Host ""
        }
        return $results
    }
    
    $fallbackLeaseOperations = @(
        {
            # Fallback: Try using ipconfig if available
            Write-Verbose "Trying ipconfig /all as fallback"
            $ipconfig = & ipconfig /all 2>$null
            if ($ipconfig) {
                Write-ConfigHost "DHCP Information (from ipconfig):" -ColorType "Info"
                $ipconfig | Where-Object { $_ -match "DHCP|Lease" } | ForEach-Object { Write-Host $_.Trim() }
                return "DHCP info retrieved via ipconfig"
            } else {
                throw "ipconfig not available"
            }
        },
        {
            # Fallback: Basic network adapter info
            Write-Verbose "Getting basic network adapter information"
            $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
            Write-ConfigHost "Available Network Adapters:" -ColorType "Info"
            foreach ($adapter in $adapters) {
                Write-Host "  $($adapter.Name) - $($adapter.InterfaceDescription)"
            }
            return "Basic adapter info retrieved"
        }
    )
    
    $result = Invoke-NetworkOperationWithFallback -PrimaryOperation $primaryLeaseOperation -FallbackOperations $fallbackLeaseOperations -OperationName "Get DHCP Lease Information"
    if ($null -eq $result) {
        Write-ConfigHost "Unable to retrieve DHCP lease details. This may require administrative privileges or the system may not be using DHCP." -ColorType "Warning"
    }
    
    Read-Host "Press Enter to continue"
}

# Function for Domain Controller Information
function Invoke-DomainControllerInfo {
    Clear-Host
    Write-ConfigHost "============= DOMAIN CONTROLLER INFO =============" -ColorType "Success"
    
    # Enhanced operation to get domain controllers with failover
    $dcInfoOperation = {
        Write-ConfigHost "Domain Controllers for $script:Domain:" -ColorType "Info"
        $domainControllers = Get-ADDomainController -Filter * -Server $script:Domain
        
        if ($domainControllers) {
            foreach ($dc in $domainControllers) {
                Write-ConfigHost "`nDomain Controller: $($dc.Name)" -ColorType "Info"
                Write-Host "  Hostname: $($dc.HostName)"
                Write-Host "  Site: $($dc.Site)"
                Write-Host "  Operating System: $($dc.OperatingSystem)"
                Write-Host "  IP Address: $($dc.IPv4Address)"
                Write-Host "  Global Catalog: $($dc.IsGlobalCatalog)"
                Write-Host "  Read Only: $($dc.IsReadOnly)"
                
                # Test connectivity with timeout
                $connectivityOperation = {
                    if (Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet -TimeoutSeconds 3) {
                        return "Online"
                    } else {
                        return "Offline"
                    }
                }
                
                $status = Invoke-NetworkOperationWithFallback -PrimaryOperation $connectivityOperation -OperationName "Test DC Connectivity" -TimeoutSeconds 5
                if ($status -eq "Online") {
                    Write-ConfigHost "  Status: Online" -ColorType "Success"
                } elseif ($status -eq "Offline") {
                    Write-ConfigHost "  Status: Offline" -ColorType "Error"
                } else {
                    Write-ConfigHost "  Status: Unknown (Connection test failed)" -ColorType "Warning"
                }
            }
            return $domainControllers
        } else {
            throw "No domain controllers found"
        }
    }
    
    $result = Invoke-ADOperationWithFailover -Operation $dcInfoOperation -OperationName "Get Domain Controller Information"
    
    if ($null -ne $result) {
        # Get domain information with enhanced error handling
        $domainInfoOperation = {
            Write-ConfigHost "`nDomain Information:" -ColorType "Info"
            $domain = Get-ADDomain -Server $script:Domain
            Write-Host "Domain Name: $($domain.DNSRoot)"
            Write-Host "Domain Functional Level: $($domain.DomainMode)"
            Write-Host "Forest Functional Level: $($domain.Forest)"
            Write-Host "Domain SID: $($domain.DomainSID)"
            Write-Host "PDC Emulator: $($domain.PDCEmulator)"
            return $domain
        }
        
        $domainResult = Invoke-ADOperationWithFailover -Operation $domainInfoOperation -OperationName "Get Domain Information"
        if ($null -eq $domainResult) {
            Write-ConfigHost "Could not retrieve detailed domain information." -ColorType "Warning"
        }
    } else {
        Write-ConfigHost "Failed to retrieve domain controller information. Please verify domain connectivity and credentials." -ColorType "Error"
        
        # Fallback: Try basic connectivity test
        Write-ConfigHost "`nAttempting basic domain connectivity test..." -ColorType "Info"
        $basicTestOperation = {
            $testResult = Test-ComputerSecureChannel -Verbose
            if ($testResult) {
                Write-ConfigHost "✓ Secure channel to domain is working" -ColorType "Success"
            } else {
                Write-ConfigHost "✗ Secure channel to domain is broken" -ColorType "Error"
            }
            return $testResult
        }
        
        Invoke-NetworkOperationWithFallback -PrimaryOperation $basicTestOperation -OperationName "Test Domain Secure Channel"
    }
    
    Read-Host "Press Enter to continue"
}

# Function for Security & Audit
function Invoke-SecurityAudit {
    do {
        Clear-Host
        Write-ConfigHost "============== SECURITY & AUDIT ================" -ColorType "Success"
        Write-Host "1. List privileged groups"
        Write-Host "2. Find admin accounts"
        Write-Host "3. Password policy information"
        Write-Host "4. Account lockout policy"
        Write-Host "5. Check for accounts with old passwords"
        Write-Host "6. List service accounts"
        Write-Host "B. Back to main menu"
        
        $choice = Read-Host "Select an option"
        
        switch ($choice) {
            "1" {
                Write-ConfigHost "Privileged Groups:" -ColorType "Info"
                $privilegedGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators", "Account Operators", "Backup Operators", "Server Operators")
                foreach ($group in $privilegedGroups) {
                    $groupOperation = {
                        Write-ConfigHost "`n$group members:" -ColorType "Info"
                        $members = Get-ADGroupMember -Identity $group -Server $script:Domain
                        if ($members) {
                            return $members | Select-Object Name, ObjectClass | Format-Table -AutoSize
                        } else {
                            Write-ConfigHost "  No members found in $group" -ColorType "Warning"
                            return "No members"
                        }
                    }
                    
                    $result = Invoke-ADOperationWithFailover -Operation $groupOperation -OperationName "Get $group Members"
                    if ($null -eq $result) {
                        Write-ConfigHost "  Group '$group' not found or accessible" -ColorType "Warning"
                    }
                }
                Read-Host "Press Enter to continue"
            }
            "2" {
                Write-ConfigHost "Finding admin accounts..." -ColorType "Info"
                $adminOperation = {
                    return Get-ADUser -Filter * -Properties AdminCount -Server $script:Domain |
                    Where-Object {$_.AdminCount -eq 1} |
                    Select-Object Name, SamAccountName, Enabled, LastLogonDate | Format-Table -AutoSize
                }
                
                $result = Invoke-ADOperationWithFailover -Operation $adminOperation -OperationName "Find Admin Accounts"
                if ($null -eq $result) {
                    Write-ConfigHost "Failed to retrieve admin accounts." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "3" {
                Write-ConfigHost "Password Policy Information:" -ColorType "Info"
                $passwordPolicyOperation = {
                    return Get-ADDefaultDomainPasswordPolicy -Server $script:Domain | Format-List
                }
                
                $result = Invoke-ADOperationWithFailover -Operation $passwordPolicyOperation -OperationName "Get Password Policy"
                if ($null -eq $result) {
                    Write-ConfigHost "Failed to retrieve password policy." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "4" {
                Write-ConfigHost "Account Lockout Policy:" -ColorType "Info"
                $lockoutPolicyOperation = {
                    return Get-ADDefaultDomainPasswordPolicy -Server $script:Domain |
                    Select-Object LockoutDuration, LockoutObservationWindow, LockoutThreshold | Format-List
                }
                
                $result = Invoke-ADOperationWithFailover -Operation $lockoutPolicyOperation -OperationName "Get Lockout Policy"
                if ($null -eq $result) {
                    Write-ConfigHost "Failed to retrieve lockout policy." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "5" {
                $days = Read-Host "Show accounts with passwords older than how many days? (default: 90)"
                if ([string]::IsNullOrWhiteSpace($days) -or -not (Test-ValidInput -Input $days -Type "Number")) { 
                    $days = 90 
                    Write-ConfigHost "Using default value: 90 days" -ColorType "Info"
                }
                $cutoffDate = (Get-Date).AddDays(-$days)
                
                $oldPasswordOperation = {
                    Write-ConfigHost "Searching for accounts with passwords older than $days days..." -ColorType "Info"
                    $users = Get-ADUser -Filter * -Properties PasswordLastSet -Server $script:Domain |
                    Where-Object { $_.PasswordLastSet -lt $cutoffDate -and $_.Enabled -eq $true }
                    
                    if ($users) {
                        return $users | Select-Object Name, SamAccountName, PasswordLastSet | Sort-Object PasswordLastSet | Format-Table -AutoSize
                    } else {
                        Write-ConfigHost "No accounts found with passwords older than $days days." -ColorType "Success"
                        return "No old passwords found"
                    }
                }
                
                $result = Invoke-ADOperationWithFailover -Operation $oldPasswordOperation -OperationName "Find Old Passwords"
                if ($null -eq $result) {
                    Write-ConfigHost "Failed to check password ages." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
            "6" {
                Write-ConfigHost "Service Accounts:" -ColorType "Info"
                $serviceAccountOperation = {
                    $serviceAccounts = Get-ADUser -Filter {ServicePrincipalName -like "*"} -Properties ServicePrincipalName, LastLogonDate -Server $script:Domain
                    if ($serviceAccounts) {
                        return $serviceAccounts | Select-Object Name, SamAccountName, LastLogonDate, @{Name="SPNs";Expression={$_.ServicePrincipalName -join "; "}} | Format-Table -AutoSize
                    } else {
                        Write-ConfigHost "No service accounts found." -ColorType "Info"
                        return "No service accounts"
                    }
                }
                
                $result = Invoke-ADOperationWithFailover -Operation $serviceAccountOperation -OperationName "Get Service Accounts"
                if ($null -eq $result) {
                    Write-ConfigHost "Failed to retrieve service accounts." -ColorType "Error"
                }
                Read-Host "Press Enter to continue"
            }
        }
    } while ($choice -ne "B" -and $choice -ne "b")
}

# Function for System Health Check
function Invoke-SystemHealthCheck {
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
    
    Read-Host "Press Enter to continue"
}

# Function to write audit log
function Write-AuditLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Action,
        [Parameter(Mandatory=$false)]
        [string]$Target = "N/A",
        [Parameter(Mandatory=$false)]
        [string]$Result = "Success",
        [Parameter(Mandatory=$false)]
        [string]$Details = ""
    )
    
    if ($NoLog) { return }
    
    try {
        $logEntry = "{0:yyyy-MM-dd HH:mm:ss} - User: {1} - Domain: {2} - Action: {3} - Target: {4} - Result: {5} - Details: {6}" -f 
            (Get-Date), $env:USERNAME, $script:Domain, $Action, $Target, $Result, $Details
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
}

# Function to validate input
function Test-ValidInput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Input,
        [Parameter(Mandatory=$true)]
        [ValidateSet("ComputerName", "UserName", "GroupName", "Number", "Domain")]
        [string]$Type
    )
    
    switch ($Type) {
        "ComputerName" { return $Input -match '^[a-zA-Z0-9-]+$' }
        "UserName" { return $Input -match '^[a-zA-Z0-9._-]+$' }
        "GroupName" { return $Input -match '^[a-zA-Z0-9 ._-]+$' }
        "Number" { return $Input -match '^\d+$' }
        "Domain" { return $Input -match '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' }
        default { return $false }
    }
}

# Function to show progress
function Show-Progress {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Activity,
        [Parameter(Mandatory=$false)]
        [string]$Status = "Processing...",
        [Parameter(Mandatory=$false)]
        [int]$PercentComplete = -1
    )
    
    if (-not $script:Config.Features.EnableProgressBars) {
        return
    }
    
    if ($PercentComplete -ge 0) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    } else {
        Write-Progress -Activity $Activity -Status $Status
    }
}

# Function to export results
function Export-Results {
    param(
        [Parameter(Mandatory=$true)]
        $Data,
        [Parameter(Mandatory=$true)]
        [string]$Title,
        [Parameter(Mandatory=$false)]
        [ValidateSet("CSV", "JSON", "XML")]
        [string]$Format = $script:Config.DefaultExportFormat
    )
    
    if (-not $script:Config.Features.EnableExport) {
        Write-ConfigHost "Export functionality is disabled in configuration" -ColorType "Warning"
        return
    }
    
    # Validate data
    if ($null -eq $Data -or ($Data -is [array] -and $Data.Count -eq 0)) {
        Write-ConfigHost "No data available to export" -ColorType "Warning"
        return
    }
    
    $exportChoice = Read-Host "Export results? (Y/N)"
    if ($exportChoice -eq "Y" -or $exportChoice -eq "y") {
        # Allow user to choose format if multiple formats are enabled
        if ($script:Config.ExportFormats.Count -gt 1) {
            Write-ConfigHost "Available formats: $($script:Config.ExportFormats -join ', ')" -ColorType "Info"
            $userFormat = Read-Host "Select format (or press Enter for $Format)"
            if (-not [string]::IsNullOrWhiteSpace($userFormat) -and $script:Config.ExportFormats -contains $userFormat.ToUpper()) {
                $Format = $userFormat.ToUpper()
            }
        }
        
        # Sanitize title for filename
        $safeTitle = $Title -replace '[^\w\-_\.]', '_'
        $fileName = "{0}_{1}_{2:yyyyMMdd_HHmmss}.{3}" -f $safeTitle, $script:Domain, (Get-Date), $Format.ToLower()
        $exportPath = Join-Path $PSScriptRoot $fileName
        
        $exportOperation = {
            switch ($Format) {
                "CSV" { $Data | Export-Csv -Path $exportPath -NoTypeInformation -ErrorAction Stop }
                "JSON" { $Data | ConvertTo-Json -Depth 3 | Out-File -FilePath $exportPath -Encoding UTF8 -ErrorAction Stop }
                "XML" { $Data | Export-Clixml -Path $exportPath -ErrorAction Stop }
            }
        }
        
        $result = [ErrorHandler]::ExecuteWithRetry($exportOperation, "Export Data", $exportPath, 2)
        
        if ($null -ne $result -or (Test-Path $exportPath)) {
            Write-ConfigHost "✓ Results exported to: $exportPath" -ColorType "Success"
            $recordCount = if ($Data -is [array]) { $Data.Count } else { 1 }
            Write-AuditLog -Action "Export" -Target $Title -Details "Format: $Format, Path: $exportPath, Records: $recordCount"
        } else {
            Write-ConfigHost "✗ Export failed. Please check file permissions and disk space." -ColorType "Error"
            Write-AuditLog -Action "Export" -Target $Title -Result "Failed" -Details "Format: $Format, Path: $exportPath"
        }
    }
}

# Function to get configured colors
function Get-ConfigColor {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Success", "Warning", "Error", "Info", "Header")]
        [string]$ColorType
    )
    
    if ($script:Config.ColorScheme -and $script:Config.ColorScheme.$ColorType) {
        return $script:Config.ColorScheme.$ColorType
    } else {
        # Fallback to defaults if config is missing
        switch ($ColorType) {
            "Success" { return "Green" }
            "Warning" { return "Yellow" }
            "Error" { return "Red" }
            "Info" { return "Cyan" }
            "Header" { return "Cyan" }
            default { return "White" }
        }
    }
}

# Function to write colored output using configuration
function Write-ConfigHost {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$true)]
        [ValidateSet("Success", "Warning", "Error", "Info", "Header")]
        [string]$ColorType,
        [switch]$NoNewline
    )
    
    $color = Get-ConfigColor -ColorType $ColorType
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $color
    }
}

# Function to show help
function Show-Help {
    Clear-Host
    Write-Host "=================== HELP SYSTEM ===================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "OVERVIEW:" -ForegroundColor Yellow
    Write-Host "This network administration tool provides comprehensive management"
    Write-Host "capabilities for Active Directory environments."
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Yellow
    Write-Host "  -Domain       : Specify domain name (e.g., company.local)"
    Write-Host "  -Credential   : Use alternate credentials"
    Write-Host "  -LogPath      : Custom log file path"
    Write-Host "  -NoLog        : Disable logging"
    Write-Host ""
    Write-Host "FEATURES:" -ForegroundColor Yellow
    Write-Host "  • User Management    - Search, list, and audit users"
    Write-Host "  • Computer Mgmt      - Manage and monitor computers"
    Write-Host "  • Group Management   - Handle AD groups and memberships"
    Write-Host "  • Network Diagnostics- Network troubleshooting tools"
    Write-Host "  • DNS Management     - DNS query and management"
    Write-Host "  • DHCP Information   - View DHCP configuration"
    Write-Host "  • Domain Controller  - DC status and information"
    Write-Host "  • Security Audit     - Security and compliance checks"
    Write-Host "  • System Health      - Overall system health monitoring"
    Write-Host ""
    Write-Host "TIPS:" -ForegroundColor Yellow
    Write-Host "  • Use 'B' to go back to previous menus"
    Write-Host "  • Results can be exported to CSV, JSON, or XML"
    Write-Host "  • All actions are logged (unless -NoLog is used)"
    Write-Host "  • Input validation helps prevent errors"
    Write-Host ""
    Write-Host "REQUIREMENTS:" -ForegroundColor Yellow
    Write-Host "  • PowerShell 5.1 or later"
    Write-Host "  • Active Directory PowerShell module"
    Write-Host "  • Appropriate domain permissions"
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Cyan
    Read-Host "Press Enter to continue"
}

# Function to execute operations with parallel processing support
function Invoke-ConfigurableOperation {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock[]]$Operations,
        [Parameter(Mandatory=$false)]
        [string]$OperationName = "Operation",
        [Parameter(Mandatory=$false)]
        [int]$ThrottleLimit = $script:Config.Performance.MaxConcurrentOperations
    )
    
    if ($script:Config.Performance.UseParallelProcessing -and $Operations.Count -gt 1) {
        Write-Verbose "Using parallel processing for $OperationName with throttle limit $ThrottleLimit"
        
        $jobs = @()
        foreach ($operation in $Operations) {
            $jobs += Start-Job -ScriptBlock $operation
            
            # Throttle job creation
            while ((Get-Job -State Running).Count -ge $ThrottleLimit) {
                Start-Sleep -Milliseconds 100
            }
        }
        
        # Wait for all jobs to complete and collect results
        $results = @()
        foreach ($job in $jobs) {
            $results += $job | Wait-Job | Receive-Job
            Remove-Job $job -Force
        }
        
        return $results
    } else {
        # Sequential processing
        Write-Verbose "Using sequential processing for $OperationName"
        $results = @()
        foreach ($operation in $Operations) {
            $results += & $operation
        }
        return $results
    }
}

# Enhanced network recovery functions
function Invoke-NetworkOperationWithFallback {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$PrimaryOperation,
        [Parameter(Mandatory=$false)]
        [scriptblock[]]$FallbackOperations = @(),
        [Parameter(Mandatory=$false)]
        [string]$OperationName = "Network Operation",
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = $script:Config.NetworkTimeout
    )
    
    # Try primary operation first
    Write-Verbose "Attempting primary operation: $OperationName"
    try {
        $result = Invoke-NetworkOperationWithTimeout -Operation $PrimaryOperation -TimeoutSeconds $TimeoutSeconds -OperationName $OperationName
        if ($null -ne $result) {
            return $result
        }
    }
    catch {
        Write-Verbose "Primary operation failed: $($_.Exception.Message)"
    }
    
    # Try fallback operations
    for ($i = 0; $i -lt $FallbackOperations.Count; $i++) {
        Write-Verbose "Attempting fallback operation $(i + 1) for: $OperationName"
        try {
            $result = Invoke-NetworkOperationWithTimeout -Operation $FallbackOperations[$i] -TimeoutSeconds $TimeoutSeconds -OperationName "$OperationName (Fallback $(i + 1))"
            if ($null -ne $result) {
                Write-ConfigHost "✓ $OperationName succeeded using fallback method $(i + 1)" -ColorType "Warning"
                return $result
            }
        }
        catch {
            Write-Verbose "Fallback operation $(i + 1) failed: $($_.Exception.Message)"
        }
    }
    
    Write-ConfigHost "✗ All attempts failed for $OperationName" -ColorType "Error"
    return $null
}

# Function to get multiple domain controllers for fallback
function Get-AvailableDomainControllers {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Domain = $script:Domain
    )
    
    try {
        $domainControllers = @()
        
        # Try to get all domain controllers
        $allDCs = Get-ADDomainController -Filter * -Server $Domain -ErrorAction SilentlyContinue
        
        if ($allDCs) {
            # Test connectivity to each DC and prioritize by response time
            foreach ($dc in $allDCs) {
                try {
                    $pingResult = Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue
                    if ($pingResult) {
                        $domainControllers += @{
                            HostName = $dc.HostName
                            Name = $dc.Name
                            Site = $dc.Site
                            IsResponding = $true
                        }
                    }
                }
                catch {
                    Write-Verbose "DC $($dc.HostName) is not responding"
                }
            }
        }
        
        # If no DCs found through AD, try DNS resolution
        if ($domainControllers.Count -eq 0) {
            try {
                $dnsResults = Resolve-DnsName -Name "_ldap._tcp.$Domain" -Type SRV -ErrorAction SilentlyContinue
                foreach ($result in $dnsResults) {
                    if ($result.Type -eq "SRV") {
                        $domainControllers += @{
                            HostName = $result.NameTarget
                            Name = $result.NameTarget
                            Site = "Unknown"
                            IsResponding = $true
                        }
                    }
                }
            }
            catch {
                Write-Verbose "DNS SRV lookup failed for domain $Domain"
            }
        }
        
        return $domainControllers
    }
    catch {
        Write-Verbose "Failed to get domain controllers: $($_.Exception.Message)"
        return @()
    }
}

# Enhanced AD operation with DC failover
function Invoke-ADOperationWithFailover {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,
        [Parameter(Mandatory=$false)]
        [string]$OperationName = "AD Operation",
        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = $script:Config.MaxRetries
    )
    
    $domainControllers = Get-AvailableDomainControllers
    
    if ($domainControllers.Count -eq 0) {
        Write-ConfigHost "✗ No available domain controllers found for $OperationName" -ColorType "Error"
        return $null
    }
    
    foreach ($dc in $domainControllers) {
        Write-Verbose "Attempting $OperationName against DC: $($dc.HostName)"
        
        try {
            # Modify the operation to use this specific DC
            $dcOperation = {
                $originalServer = $script:Domain
                $script:Domain = $dc.HostName
                try {
                    return & $Operation
                }
                finally {
                    $script:Domain = $originalServer
                }
            }
            
            $result = [ErrorHandler]::ExecuteWithRetry($dcOperation, $OperationName, $dc.HostName, $MaxRetries)
            
            if ($null -ne $result) {
                if ($dc.HostName -ne $script:Domain) {
                    Write-ConfigHost "✓ $OperationName succeeded using DC: $($dc.HostName)" -ColorType "Warning"
                }
                return $result
            }
        }
        catch {
            Write-Verbose "$OperationName failed against DC $($dc.HostName): $($_.Exception.Message)"
            continue
        }
    }
    
    Write-ConfigHost "✗ $OperationName failed against all available domain controllers" -ColorType "Error"
    return $null
}

# Main script execution
try {
    # Get domain name
    Get-DomainName
    
    # Test domain connectivity
    if (-not (Test-DomainConnectivity)) {
        Write-Host "Warning: Unable to connect to domain. Some features may not work properly." -ForegroundColor Yellow
        $continue = Read-Host "Do you want to continue anyway? (Y/N)"
        if ($continue -ne "Y" -and $continue -ne "y") {
            exit
        }
    }
    
    # Main program loop
    do {
        Clear-Host
        Write-Host "Current Domain: $script:Domain" -ForegroundColor Green
        Write-Host ""
        Show-MainMenu
        $choice = Read-Host "Select an option"
          switch ($choice) {
            "1" { Invoke-UserManagement }
            "2" { Invoke-ComputerManagement }
            "3" { Invoke-GroupManagement }
            "4" { Invoke-NetworkDiagnostics }
            "5" { Invoke-DNSManagement }
            "6" { Invoke-DHCPInfo }
            "7" { Invoke-DomainControllerInfo }
            "8" { Invoke-SecurityAudit }
            "9" { Invoke-SystemHealthCheck }
            "10" { 
                $script:Domain = ""
                Get-DomainName 
                Test-DomainConnectivity | Out-Null
            }
            {$_ -eq "H" -or $_ -eq "h"} { Show-Help }
            {$_ -eq "Q" -or $_ -eq "q"} { 
                Write-Host "Exiting Network Administration Tool..." -ForegroundColor Yellow
                Write-AuditLog -Action "Script Ended"
                break
            }
            default { 
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($choice -ne "Q" -and $choice -ne "q")
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}

Write-Host "Thank you for using the Network Administration Tool!" -ForegroundColor Green