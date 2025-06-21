# PowerShell classes for NetworkAdmin module

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
            }
            catch {
                Write-Verbose "Attempt $attempt failed: $($_.Exception.Message)"
                if ($attempt -ge $maxRetries) {
                    throw $_
                }
                Start-Sleep -Seconds $delaySeconds
            }
        } while ($attempt -lt $maxRetries)
        
        return $null
    }
}

class NetworkAdminErrorHandler {
    static [void] HandleADError([System.Management.Automation.ErrorRecord]$errorRecord, [string]$operation, [string]$target = "") {
        $errorMessage = switch -Regex ($errorRecord.Exception.Message) {
            ".*not found.*|.*does not exist.*" { "Object '$target' not found in Active Directory" }
            ".*access.*denied.*|.*unauthorized.*" { "Access denied. Insufficient permissions for '$operation'" }
            ".*timeout.*|.*time.*out.*" { "Operation '$operation' timed out. The domain controller may be busy or unreachable" }
            ".*network.*|.*connection.*" { "Network connectivity issue. Unable to reach domain controller" }
            ".*invalid.*filter.*" { "Invalid search filter specified for '$operation'" }
            ".*quota.*exceeded.*" { "AD query quota exceeded. Try using more specific filters" }
            default { "AD operation '$operation' failed: $($errorRecord.Exception.Message)" }
        }
        
        Write-ConfigHost "✗ $errorMessage" -ColorType "Error"
        Write-NetworkAdminAuditLog -Action $operation -Target $target -Result "Failed" -Details $errorMessage
    }
    
    static [void] HandleNetworkError([System.Management.Automation.ErrorRecord]$errorRecord, [string]$operation, [string]$target = "") {
        $errorMessage = switch -Regex ($errorRecord.Exception.Message) {
            ".*timeout.*|.*time.*out.*" { "Network timeout while connecting to '$target'" }
            ".*unreachable.*|.*not.*reachable.*" { "Host '$target' is unreachable" }
            ".*refused.*|.*connection.*refused.*" { "Connection refused by '$target'" }
            ".*resolution.*failed.*|.*name.*not.*resolved.*" { "DNS resolution failed for '$target'" }
            default { "Network operation '$operation' failed: $($errorRecord.Exception.Message)" }
        }
        
        Write-ConfigHost "✗ $errorMessage" -ColorType "Error"
        Write-NetworkAdminAuditLog -Action $operation -Target $target -Result "Failed" -Details $errorMessage
    }
    
    static [object] ExecuteWithRetry([scriptblock]$operation, [string]$operationName, [string]$target = "", [int]$maxRetries = 3) {
        $attempt = 0
        $lastError = $null
        
        do {
            $attempt++
            try {
                Show-NetworkAdminProgress -Activity $operationName -Status "Attempt $attempt of $maxRetries..." -PercentComplete (($attempt - 1) * 100 / $maxRetries)
                $result = & $operation
                Write-Progress -Activity $operationName -Completed
                return $result
            }
            catch {
                $lastError = $_
                Write-Verbose "Attempt $attempt failed for '$operationName': $($_.Exception.Message)"
                
                if ($attempt -lt $maxRetries) {
                    $delay = [math]::Min(2 * $attempt, 10)
                    Write-ConfigHost "Retrying in $delay seconds..." -ColorType "Warning"
                    Start-Sleep -Seconds $delay
                }
            }
        } while ($attempt -lt $maxRetries)
        
        Write-Progress -Activity $operationName -Completed
        if ($target -and ($lastError.Exception.Message -match "Active Directory|AD|LDAP")) {
            [NetworkAdminErrorHandler]::HandleADError($lastError, $operationName, $target)
        } elseif ($target -and ($lastError.Exception.Message -match "network|connection|ping|resolve")) {
            [NetworkAdminErrorHandler]::HandleNetworkError($lastError, $operationName, $target)
        } else {
            Write-ConfigHost "✗ Operation '$operationName' failed after $maxRetries attempts: $($lastError.Exception.Message)" -ColorType "Error"
            Write-NetworkAdminAuditLog -Action $operationName -Target $target -Result "Failed" -Details "Failed after $maxRetries attempts: $($lastError.Exception.Message)"
        }
        
        return $null
    }
}
