# Write-Log.ps1
# Central logging function for PSNetworkAdministrator

<#
.SYNOPSIS
    Writes log entries for PSNetworkAdministrator operations.

.DESCRIPTION
    Provides centralized logging functionality for the PSNetworkAdministrator module.
    Logs include timestamps, severity levels, and detailed messages.
    All module functions should use this for consistent logging.

.PARAMETER Message
    The log message to write.

.PARAMETER Level
    The severity level of the log entry. Valid values are:
    - Info: Normal operational messages (default)
    - Warning: Potential issues that don't prevent operation
    - Error: Problems that prevent operation
    - Debug: Detailed information for troubleshooting

.PARAMETER LogPath
    Path to the log file. If not specified, uses the module's default log path.
    Default format: Logs\PSNetworkAdmin_YYYYMMDD.log

.EXAMPLE
    Write-Log -Message "User account created: jdoe" -Level Info

.EXAMPLE
    Write-Log -Message "Failed to connect to domain controller" -Level Error -LogPath "C:\Logs\ADFailures.log"

.NOTES
    Logs are automatically rotated daily based on the date in the filename.
    For security reasons, sensitive information should not be logged.
#>
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        
        [Parameter(Position = 1)]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',
        
        [Parameter(Position = 2)]
        [string]$LogPath
    )
    
    # Get the current date for log rotation and timestamps
    $currentDate = Get-Date
    $timestamp = $currentDate.ToString('yyyy-MM-dd HH:mm:ss')
    
    # If no log path specified, use the default path with date-based filename
    if (-not $LogPath) {
        $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $logFolder = Join-Path -Path $moduleRoot -ChildPath 'Logs'
        
        # Create log directory if it doesn't exist
        if (-not (Test-Path -Path $logFolder)) {
            # Use try/catch for error handling around directory creation
            try {
                $null = New-Item -Path $logFolder -ItemType Directory -Force
            }
            catch {
                # If we can't create the log directory, fall back to temp folder
                # This is important for non-admin users who might not have write access
                $logFolder = [System.IO.Path]::GetTempPath()
            }
        }
        
        $LogPath = Join-Path -Path $logFolder -ChildPath "PSNetworkAdmin_$($currentDate.ToString('yyyyMMdd')).log"
    }
    
    # Format log entry with timestamp and level
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Use try/catch for error handling when writing to the log file
    try {
        # Append to log file
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction Stop
        
        # For Error and Warning levels, also output to console for immediate visibility
        if ($Level -eq 'Error') {
            Write-Error $Message
        }
        elseif ($Level -eq 'Warning') {
            Write-Warning $Message
        }
        elseif ($Level -eq 'Debug' -and $VerbosePreference -eq 'Continue') {
            # Only show debug messages when verbose output is enabled
            Write-Verbose $Message
        }
    }
    catch {
        # If we can't write to the log file, at least output to console
        # This prevents silent failures in the logging system
        Write-Warning "Failed to write to log file '$LogPath': $_"
        Write-Warning "Original log message: [$Level] $Message"
    }
}
