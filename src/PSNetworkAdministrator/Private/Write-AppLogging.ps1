function Write-AppLogging {
    <#
    .SYNOPSIS
        Writes log entries to file and console
    #>

    param(
        [Parameter(Mandatory)]
        [string]$LoggingMessage,
        
        [ValidateSet('Info', 'Passed', 'Warning', 'Error')]
        [string]$LoggingLevel = 'Info',
        
        [string]$LoggingPath
    )
    
    # create log directory, if it doesn't exist
    $LoggingDir = Split-Path -Parent $LoggingPath
    if ($LoggingDir -and -not (Test-Path $LoggingDir)) {
        New-Item -Path $LoggingDir -ItemType Directory -Force | Out-Null
    }
    
    # format log entry
    $LoggingTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LoggingEntry = "[$($LoggingTimestamp.Split(' ')[0])][$($LoggingTimestamp.Split(' ')[1])][$LoggingLevel]: $LoggingMessage"
    
    # write to file
    try {
        Add-Content -Path $LoggingPath -Value $LoggingEntry
    }
    catch {
        throw "Failed to write log into file in '$LoggingPath': $($_.Exception.Message)."
    }
}