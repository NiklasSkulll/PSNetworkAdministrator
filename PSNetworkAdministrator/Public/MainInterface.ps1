# Main interface for NetworkAdmin module

function Start-NetworkAdminTool {
    <#
    .SYNOPSIS
        Starts the Network Administration Tool with interactive menu
    
    .DESCRIPTION
        Launches the comprehensive network administration tool with a menu-driven interface
        for managing Active Directory users, computers, groups, and network diagnostics.
    
    .PARAMETER Domain
        The domain name to connect to (e.g., company.local)
    
    .PARAMETER Credential
        Alternative credentials to use for domain operations
    
    .PARAMETER LogPath
        Custom path for the audit log file
    
    .PARAMETER NoLog
        Disable audit logging
    
    .EXAMPLE
        Start-NetworkAdminTool -Domain "company.local"
        
    .EXAMPLE
        Start-NetworkAdminTool -Domain "company.local" -Credential (Get-Credential)
    #>
    [CmdletBinding()]
    [Alias('netadmin')]
    param(
        [Parameter(Mandatory = $false)]
        [ValidatePattern('^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
        [string]$Domain,
        
        [Parameter(Mandatory = $false)]
        [PSCredential]$Credential,
          [Parameter(Mandatory = $false)]
        [string]$LogPath = "$PSScriptRoot\..\..\NetworkAdminLog.txt",
        
        [Parameter(Mandatory = $false)]
        [switch]$NoLog
    )
    
    begin {
        # Initialize configuration
        Initialize-NetworkAdminConfig
          # Load external config if exists
        $configPath = Join-Path $PSScriptRoot "..\..\config.json"
        if (Test-Path $configPath) {
            Import-NetworkAdminConfig -ConfigPath $configPath
        }
        
        # Initialize logging
        if (-not $NoLog) {
            Initialize-NetworkAdminLogging -LogPath $LogPath
        }
        
        # Set module-level variables
        $script:CurrentDomain = $Domain
        $script:CurrentCredential = $Credential
        $script:LoggingEnabled = -not $NoLog
    }
    
    process {
        try {
            # Display banner
            Show-NetworkAdminBanner
            
            # Get domain if not provided
            if (-not $script:CurrentDomain) {
                $script:CurrentDomain = Get-NetworkAdminDomainName
            }
            
            # Test connectivity
            if (-not (Test-NetworkAdminDomainConnectivity)) {
                Write-Warning "Domain connectivity test failed. Some features may not work properly."
            }
            
            # Main menu loop
            do {
                Show-NetworkAdminMainMenu
                $choice = Read-Host "Select an option"
                
                switch ($choice) {
                    "1" { Invoke-NetworkAdminUserManagement }
                    "2" { Invoke-NetworkAdminComputerManagement }
                    "3" { Invoke-NetworkAdminGroupManagement }
                    "4" { Invoke-NetworkAdminNetworkDiagnostics }
                    "5" { Invoke-NetworkAdminDNSManagement }
                    "6" { Invoke-NetworkAdminDHCPInfo }
                    "7" { Invoke-NetworkAdminDomainControllerInfo }
                    "8" { Invoke-NetworkAdminSecurityAudit }
                    "9" { Invoke-NetworkAdminSystemHealthCheck }
                    "10" { $script:CurrentDomain = Get-NetworkAdminDomainName }
                    "H" { Show-NetworkAdminHelp }
                    "h" { Show-NetworkAdminHelp }
                    "Q" { break }
                    "q" { break }
                    default { Write-Host "Invalid selection. Please try again." -ForegroundColor Red }
                }
            } while ($choice -notin @("Q", "q"))
            
            Write-Host "Thank you for using the Network Administration Tool!" -ForegroundColor Green
        }
        catch {
            Write-Error "An error occurred in the Network Administration Tool: $($_.Exception.Message)"
        }
    }
}

function Show-NetworkAdminBanner {
    [CmdletBinding()]
    param()
    
    Clear-Host
    Write-ConfigHost "================================================" -ColorType "Header"
    Write-ConfigHost "    Company Network Administration Tool" -ColorType "Info"
    Write-ConfigHost "================================================" -ColorType "Header"
    Write-Host ""
}

function Show-NetworkAdminMainMenu {
    [CmdletBinding()]
    param()
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
    Write-Host "11. Change Credentials" -ForegroundColor White
    Write-ConfigHost "H.  Help" -ColorType "Info"
    Write-ConfigHost "Q.  Quit" -ColorType "Error"
    Write-ConfigHost "===================================================" -ColorType "Header"
}

function Show-NetworkAdminHelp {
    [CmdletBinding()]
    param()
    
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

function Get-DomainName {
    <#
    .SYNOPSIS
    Prompts user for domain name or validates provided domain

    .DESCRIPTION
    Interactive function to get domain name from user input or validate existing parameter

    .EXAMPLE
    Get-DomainName
    #>
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

function Test-DomainConnectivity {
    <#
    .SYNOPSIS
    Tests connectivity to the specified domain

    .DESCRIPTION
    Verifies that the system can connect to the Active Directory domain and locate domain controllers

    .EXAMPLE
    Test-DomainConnectivity
    #>
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
