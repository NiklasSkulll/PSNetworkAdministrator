# Configuration management for NetworkAdmin module

function Initialize-NetworkAdminConfig {
    [CmdletBinding()]
    param()
    
    $script:ModuleConfig = @{
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
}

function Import-NetworkAdminConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )
    
    if (-not (Test-Path $ConfigPath)) {
        Write-Warning "Configuration file not found: $ConfigPath"
        return
    }
    
    try {
        $configData = Get-Content $ConfigPath | ConvertFrom-Json
        
        foreach ($property in $configData.PSObject.Properties) {
            if ($property.Value -is [PSCustomObject]) {
                if (-not $script:ModuleConfig.ContainsKey($property.Name)) {
                    $script:ModuleConfig[$property.Name] = @{}
                }
                foreach ($nestedProperty in $property.Value.PSObject.Properties) {
                    $script:ModuleConfig[$property.Name][$nestedProperty.Name] = $nestedProperty.Value
                }
            } else {
                $script:ModuleConfig[$property.Name] = $property.Value
            }
        }
        
        Write-Verbose "Configuration loaded from $ConfigPath"
    }
    catch {
        Write-Warning "Failed to load configuration file: $($_.Exception.Message)"
    }
}

function Get-NetworkAdminConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Key
    )
    
    if ($Key) {
        return $script:ModuleConfig[$Key]
    }
    
    return $script:ModuleConfig
}

function Set-NetworkAdminConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,
        
        [Parameter(Mandatory = $true)]
        [object]$Value
    )
    
    $script:ModuleConfig[$Key] = $Value
    Write-Verbose "Configuration updated: $Key = $Value"
}

function Initialize-LoggingSystem {
    <#
    .SYNOPSIS
    Initializes the logging system with log retention

    .DESCRIPTION
    Sets up logging and cleans old log entries based on retention policy

    .EXAMPLE
    Initialize-LoggingSystem
    #>
    if (Test-Path $script:LogPath) {
        $cutoffDate = (Get-Date).AddDays(-$script:Config.LogRetentionDays)
        $logContent = Get-Content $script:LogPath | Where-Object {
            $line = $_
            if ($line -match '^(\d{4}-\d{2}-\d{2})') {
                try {
                    [DateTime]::Parse($matches[1]) -gt $cutoffDate
                } catch {
                    $true  # Keep lines that can't be parsed
                }
            } else {
                $true  # Keep non-date lines
            }
        }
        $logContent | Set-Content $script:LogPath
        Write-Verbose "Log retention cleanup completed. Removed entries older than $($script:Config.LogRetentionDays) days."
    }
}
