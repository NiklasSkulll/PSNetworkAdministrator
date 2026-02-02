function Write-AppLogging {
    <#
    .SYNOPSIS
        Writes log entries to file and console
    #>

    param(
        [Parameter(Mandatory)]
        [string]$LoggingMessage,
        
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
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
        Write-Host "Failed to write log into file: $($_.Exception.Message)." -ForegroundColor Red
    }
    
    # write to console with color
    $MessageColor = switch ($LoggingLevel) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }
    Write-Host $LoggingEntry -ForegroundColor $MessageColor
}