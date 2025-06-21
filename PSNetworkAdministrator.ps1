# Enhanced Network Administration Tool Entry Point
# Using the NetworkAdmin PowerShell Module
# Author: System Administrator
# Date: June 2025
# Description: Modular entry point for the comprehensive network administration tool

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

# Set error action preference
$ErrorActionPreference = "Continue"

# Store parameters for module access
$script:Domain = $Domain
$script:Credential = $Credential
$script:LogPath = $LogPath
$script:NoLog = $NoLog

try {
    # Import the PSNetworkAdministrator module
    $modulePath = Join-Path $PSScriptRoot "PSNetworkAdministrator\PSNetworkAdministrator.psd1"
    if (-not (Test-Path $modulePath)) {
        Write-Error "PSNetworkAdministrator module not found at: $modulePath"
        Write-Host "Please ensure the module files are present in the PSNetworkAdministrator directory." -ForegroundColor Red
        exit 1
    }
    
    Import-Module $modulePath -Force -Scope Global
    
    # Initialize logging if not disabled
    if (-not $NoLog) {
        try {
            if (-not (Test-Path (Split-Path $LogPath -Parent))) {
                New-Item -ItemType Directory -Path (Split-Path $LogPath -Parent) -Force | Out-Null
            }
            
            # Load configuration and clean old log entries
            Initialize-LoggingSystem
            Write-AuditLog -Action "Script Started" -Details "Version: June 2025 (Modular)"
        }
        catch {
            Write-Warning "Failed to initialize logging: $($_.Exception.Message)"
        }
    }
    
    # Security validation checks
    Write-Host "Performing security validation..." -ForegroundColor Yellow
    
    # Check if running with appropriate privileges
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Write-Host "✓ Running with administrative privileges" -ForegroundColor Green
        Write-AuditLog -Action "Security Check" -Details "Script started with administrative privileges"
    } else {
        Write-Host "ⓘ Running with user-level privileges" -ForegroundColor Cyan
        Write-AuditLog -Action "Security Check" -Details "Script started with user-level privileges"
    }
      # Validate module file integrity (basic check)
    $criticalFiles = @("PSNetworkAdministrator\PSNetworkAdministrator.psd1", "PSNetworkAdministrator\PSNetworkAdministrator.psm1", "PSNetworkAdministrator\Classes\NetworkAdminClasses.ps1")
    foreach ($file in $criticalFiles) {
        $filePath = Join-Path $PSScriptRoot $file
        if (Test-Path $filePath) {
            Write-Host "✓ Core file validated: $file" -ForegroundColor Green
        } else {
            Write-Warning "⚠ Missing critical file: $file"
            Write-AuditLog -Action "Security Check" -Details "Missing critical file: $file" -Result "Warning"
        }
    }
    
    # Clear screen and show banner
    Clear-Host
    Write-ConfigHost "================================================" -ColorType "Header"
    Write-ConfigHost "    Company Network Administration Tool" -ColorType "Info"
    Write-ConfigHost "           (Modular Architecture)" -ColorType "Info"
    Write-ConfigHost "================================================" -ColorType "Header"
    Write-Host ""
    
    # Check if we need alternate credentials for domain operations
    if (-not $Credential -and $Domain) {
        try {
            # Test if current user has sufficient permissions
            $testAD = Get-ADDomain -Server $Domain -ErrorAction Stop
            Write-Host "✓ Using current user credentials for domain operations" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠ Current user may not have sufficient permissions for all operations." -ForegroundColor Yellow
            Write-Host "Active Directory Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host ""
            
            $useAltCreds = Read-Host "Would you like to provide alternate credentials? (Y/N)"
            if ($useAltCreds -eq "Y" -or $useAltCreds -eq "y") {
                Write-Host "Please provide your domain administrator credentials:" -ForegroundColor Cyan
                $script:Credential = Get-Credential -Message "Enter Domain Administrator Credentials"
                if ($script:Credential) {
                    Write-Host "✓ Alternate credentials provided" -ForegroundColor Green
                }
            }
        }
    }

    # Get domain name from user if not provided
    Get-DomainName
    
    # Test domain connectivity
    if (-not (Test-DomainConnectivity)) {
        Write-Host "Warning: Unable to connect to domain. Some features may not work properly." -ForegroundColor Yellow
        $continue = Read-Host "Do you want to continue anyway? (Y/N)"
        if ($continue -ne "Y" -and $continue -ne "y") {
            Write-AuditLog -Action "Script Terminated" -Details "User chose to exit due to domain connectivity issues"
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
                Write-Host "Changing domain..." -ForegroundColor Yellow
                $script:Domain = ""
                $script:Credential = $null
                # Re-run credential detection for new domain
                if ($script:Domain) {
                    try {
                        $testAD = Get-ADDomain -Server $script:Domain -ErrorAction Stop
                    }
                    catch {
                        $useAltCreds = Read-Host "Would you like to provide alternate credentials for the new domain? (Y/N)"
                        if ($useAltCreds -eq "Y" -or $useAltCreds -eq "y") {
                            $script:Credential = Get-Credential -Message "Enter Domain Administrator Credentials"
                        }
                    }
                }
                Get-DomainName
                if (-not (Test-DomainConnectivity)) {
                    Write-Host "Warning: Unable to connect to new domain." -ForegroundColor Yellow
                }
            }
            "11" {
                Write-Host "Changing credentials..." -ForegroundColor Yellow
                Write-Host "Please provide new domain administrator credentials:" -ForegroundColor Cyan
                $newCred = Get-Credential -Message "Enter Domain Administrator Credentials"
                if ($newCred) {
                    $script:Credential = $newCred
                    Write-Host "✓ Credentials updated successfully" -ForegroundColor Green
                } else {
                    Write-Host "⚠ Credential change cancelled" -ForegroundColor Yellow
                }
                Start-Sleep -Seconds 2
            }
            "H" { Show-Help }
            "h" { Show-Help }
            "Q" { 
                Write-Host "Thank you for using the Network Administration Tool!" -ForegroundColor Green
                Write-AuditLog -Action "Script Completed" -Details "User initiated exit"
                break 
            }
            "q" { 
                Write-Host "Thank you for using the Network Administration Tool!" -ForegroundColor Green
                Write-AuditLog -Action "Script Completed" -Details "User initiated exit"
                break 
            }
            default { 
                Write-Host "Invalid option. Please try again." -ForegroundColor Red 
                Start-Sleep -Seconds 1
            }
        }
    } while ($choice -ne "Q" -and $choice -ne "q")
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    Write-Host "Stack Trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    
    if (-not $NoLog) {
        Write-AuditLog -Action "Script Error" -Result "Failed" -Details "Error: $($_.Exception.Message)"
    }
    
    Read-Host "Press Enter to exit"
    exit 1
}
finally {
    # Security cleanup - Clear sensitive data from memory
    if ($script:Credential) {
        Write-Host "Clearing credentials from memory..." -ForegroundColor Yellow
        $script:Credential = $null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Write-AuditLog -Action "Security Cleanup" -Details "Credentials cleared from memory"
    }
    
    # Clean up any remaining jobs or resources
    Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
    
    if (-not $NoLog) {
        Write-AuditLog -Action "Script Ended" -Details "Cleanup completed"
    }
}
