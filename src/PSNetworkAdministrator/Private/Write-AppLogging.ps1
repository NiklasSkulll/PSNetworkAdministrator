function Write-AppLogging {
    <#
    .SYNOPSIS
        Writes formatted log entries to a log file with automatic rotation based on size limits.
    
    .DESCRIPTION
        The Write-AppLogging function creates standardized log entries with timestamps and severity levels,
        implementing automatic log rotation based on configured file size limits. When a log file exceeds
        the maximum size defined in the module configuration (MaxLoggingSizeMB), the function automatically
        creates a new dated log file. The function checks all existing log files in the directory and writes
        to the first file that hasn't exceeded the size limit or creates a new file if all are full.

        Log files are automatically named with date suffixes (e.g. PSNetAdmin.2026-02-14.log) when rotation occurs.
        The function automatically creates the log directory if it doesn't exist and supports three logging
        levels: Info, Warning, and Error.
    
    .PARAMETER LoggingMessage
        The message to be logged. This is a mandatory parameter containing the actual log content.
    
    .PARAMETER LoggingLevel
        The severity level of the log entry. Valid values are 'Info', 'Warning', and 'Error'.
        Defaults to 'Info' if not specified.
    
    .PARAMETER LoggingPath
        The full path to the log file. If not specified, uses the script-scoped $LoggingPath variable.
        The function will create the directory structure if it doesn't exist.
        Actual log files may have date suffixes appended when rotation occurs.

    .EXAMPLE
        Write-AppLogging -LoggingMessage "Application started successfully" -LoggingLevel "Info"
    
        Writes an informational log entry to the default log file.
    
    .EXAMPLE
        Write-AppLogging -LoggingMessage "Failed to connect to domain" -LoggingLevel "Error" -LoggingPath "C:\Logs\PSNetAdmin.log"
    
        Writes an error log entry to a custom log file location.
    
    .INPUTS
        None. This function does not accept pipeline input.
    
    .OUTPUTS
        None. This function writes to a file and does not return output.
        Throws an exception if writing to the log file fails.

    .NOTES
        Author: Niklas Schneider
        Version: 1.0.0
        Requires: PowerShell 7.0+
    
        This function is intended for internal use only (Private function).

        Log File Rotation:
        - Maximum log file size is defined by $script:ModuleConfig.Logging.MaxLoggingSizeMB (loaded from module configuration)
        - When a log file exceeds the size limit, a new file is created with date suffix
        - File naming pattern: basename.yyyy-MM-dd.extension (e.g. PSNetAdmin.2026-02-14.log)
        - Function checks all existing log files and uses the first one under the size limit
        - Multiple dated log files can coexist in the same directory

        Log format: [yyyy-MM-dd][HH:mm:ss][Level]: Message

        Dependencies:
        - Requires $script:LoggingPath to be initialized (set in PSNetworkAdministrator.psm1)
        - Requires $script:ModuleConfig to be initialized (set in PSNetworkAdministrator.psm1)
        - These variables are populated from Initialize-Configuration during module load
    #>

    param(
        [Parameter(Mandatory)]
        [string]$LoggingMessage,
        
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$LoggingLevel = 'Info',
        
        [string]$LoggingPath = $script:LoggingPath,

        [ValidateSet('de', 'en')]
        [string]$Language = $script:ModuleConfig.Language
    )
    
    # ===== Get current date and time =====
    $LoggingTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $CurrentDate = $LoggingTimestamp.Split(' ')[0]
    $CurrentTime = $LoggingTimestamp.Split(' ')[1]

    # ===== Extract directory and file name (with/without extension) =====
    $LoggingDirectory = Split-Path -Parent $LoggingPath
    $LogFileName = Split-Path -Leaf $LoggingPath
    $LogFileNameNoExt = [System.IO.Path]::GetFileNameWithoutExtension($LogFileName)
    $LogFileNameJustExt = [System.IO.Path]::GetExtension($LogFileName)

    # ===== Create log directory, if it doesn't exist =====
    Initialize-FilePath -FilePath $LoggingPath -Language $Language

    # ===== Create variable for target log file =====
    $TargetLoggingPath = $null

    # ===== Check for existing log files =====
    $ExistingLogFiles = Get-ChildItem -Path $LoggingDirectory -Filter "$LogFileNameNoExt*$LogFileNameJustExt" -ErrorAction SilentlyContinue
    
    # ===== Search log file that hasn't exceeded the size limit =====
    if ($ExistingLogFiles) {
        foreach ($LoggingFile in $ExistingLogFiles) {
            $FileSizeMB = [math]::Round($LoggingFile.length / 1MB, 2)
            if ($FileSizeMB -lt $script:ModuleConfig.Logging.MaxLoggingSizeMB) {
                $TargetLoggingPath = $LoggingFile.FullName
                break
            }
        }
    }

    # ===== Create a new log file (if none is found) =====
    if (-not $TargetLoggingPath) {
        $TargetLoggingPath = Join-Path $LoggingDirectory "$LogFileNameNoExt.$CurrentDate$LogFileNameJustExt"
    }

    # ===== Format and write log entry =====
    $LoggingEntry = "[$CurrentDate][$CurrentTime][$LoggingLevel]: $LoggingMessage"
    try {
        Add-Content -Path $TargetLoggingPath -Value $LoggingEntry
    }
    catch {
        $RefValue = Get-RefValue -VariableName '$TargetLoggingPath' -Value $TargetLoggingPath -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'IOx0000003' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }
}