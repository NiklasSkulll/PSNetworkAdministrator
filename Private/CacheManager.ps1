# Cache management for NetworkAdmin module

function Get-NetworkAdminCachedResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,
        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,
        [Parameter(Mandatory=$false)]
        [int]$ExpirationMinutes = 15
    )
    
    $config = Get-NetworkAdminConfig
    
    if (-not $config.Performance.CacheResults) {
        return & $Operation
    }
    
    $now = Get-Date
    
    # Check if we have a cached result that's still valid
    if ($script:ModuleCache.ContainsKey($Key)) {
        $cachedItem = $script:ModuleCache[$Key]
        $expirationTime = $cachedItem.Timestamp.AddMinutes($ExpirationMinutes)
        
        if ($now -lt $expirationTime) {
            Write-Verbose "Using cached result for: $Key"
            return $cachedItem.Data
        } else {
            Write-Verbose "Cache expired for: $Key"
            $script:ModuleCache.Remove($Key)
        }
    }
    
    # Execute operation and cache result
    Write-Verbose "Executing and caching result for: $Key"
    $result = & $Operation
    $script:ModuleCache[$Key] = @{
        Data = $result
        Timestamp = $now
    }
    
    return $result
}

function Clear-NetworkAdminCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Key
    )
    
    if ($Key) {
        if ($script:ModuleCache.ContainsKey($Key)) {
            $script:ModuleCache.Remove($Key)
            Write-Verbose "Cleared cache for key: $Key"
        }
    } else {
        $script:ModuleCache.Clear()
        Write-Verbose "Cleared entire cache"
    }
}

function Get-NetworkAdminCacheInfo {
    [CmdletBinding()]
    param()
    
    $cacheInfo = @{
        TotalItems = $script:ModuleCache.Count
        Items = @()
    }
    
    foreach ($key in $script:ModuleCache.Keys) {
        $item = $script:ModuleCache[$key]
        $cacheInfo.Items += [PSCustomObject]@{
            Key = $key
            Timestamp = $item.Timestamp
            Age = (Get-Date) - $item.Timestamp
            DataType = $item.Data.GetType().Name
        }
    }
    
    return $cacheInfo
}
