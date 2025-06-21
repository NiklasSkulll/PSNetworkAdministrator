# Utility functions for NetworkAdmin module

function Write-AuditLog {
    <#
    .SYNOPSIS
    Writes an audit log entry

    .DESCRIPTION
    Creates a standardized audit log entry with user, domain, action, target, result, and details

    .PARAMETER Action
    The action being performed

    .PARAMETER Target
    The target of the action

    .PARAMETER Result
    The result of the action

    .PARAMETER Details
    Additional details about the action

    .EXAMPLE
    Write-AuditLog -Action "UserQuery" -Target "john.doe" -Details "Retrieved user information"
    #>
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

function Test-ValidInput {
    <#
    .SYNOPSIS
    Validates input based on type

    .DESCRIPTION
    Validates user input against predefined patterns for different data types

    .PARAMETER Input
    The input string to validate

    .PARAMETER Type
    The type of validation to perform

    .EXAMPLE
    Test-ValidInput -Input "COMPUTER01" -Type "ComputerName"
    #>
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

function Show-Progress {
    <#
    .SYNOPSIS
    Shows progress bar if enabled

    .DESCRIPTION
    Displays a progress bar for long-running operations if progress bars are enabled in configuration

    .PARAMETER Activity
    The activity being performed

    .PARAMETER Status
    The current status message

    .PARAMETER PercentComplete
    The percentage complete (0-100)

    .EXAMPLE
    Show-Progress -Activity "Processing Users" -Status "Processing user 5 of 10" -PercentComplete 50
    #>
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

function Export-Results {
    <#
    .SYNOPSIS
    Exports data to various formats

    .DESCRIPTION
    Exports data to CSV, JSON, or XML format with user choice and validation

    .PARAMETER Data
    The data to export

    .PARAMETER Title
    The title for the export file

    .PARAMETER Format
    The export format (CSV, JSON, XML)

    .EXAMPLE
    Export-Results -Data $users -Title "UserReport"
    #>
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
            }        }
        
        # Sanitize title for filename
        $safeTitle = $Title -replace '[^\w\-_\.]', '_'
        $fileName = "{0}_{1}_{2:yyyyMMdd_HHmmss}.{3}" -f $safeTitle, $script:Domain, (Get-Date), $Format.ToLower()
        $exportPath = Join-Path $PSScriptRoot "..\.." $fileName
        
        $exportOperation = {
            switch ($Format) {
                "CSV" { $Data | Export-Csv -Path $exportPath -NoTypeInformation -ErrorAction Stop }
                "JSON" { $Data | ConvertTo-Json -Depth 3 | Out-File -FilePath $exportPath -Encoding UTF8 -ErrorAction Stop }
                "XML" { $Data | Export-Clixml -Path $exportPath -ErrorAction Stop }
            }
        }
        
        $result = [NetworkAdminErrorHandler]::ExecuteWithRetry($exportOperation, "Export Data", $exportPath, 2)
        
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

function Get-ConfigColor {
    <#
    .SYNOPSIS
    Gets the configured color for a specific type

    .DESCRIPTION
    Retrieves the color configuration for different message types with fallback defaults

    .PARAMETER ColorType
    The type of color to retrieve

    .EXAMPLE
    Get-ConfigColor -ColorType "Success"
    #>
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

function Write-ConfigHost {
    <#
    .SYNOPSIS
    Writes colored output using configuration

    .DESCRIPTION
    Writes text output with colors defined in the configuration file

    .PARAMETER Message
    The message to display

    .PARAMETER ColorType
    The type of color to use

    .PARAMETER NoNewline
    Whether to suppress the newline

    .EXAMPLE
    Write-ConfigHost "Operation successful" -ColorType "Success"
    #>
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

function Show-Help {
    <#
    .SYNOPSIS
    Displays help information

    .DESCRIPTION
    Shows comprehensive help information about the tool's features and usage

    .EXAMPLE
    Show-Help
    #>
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
