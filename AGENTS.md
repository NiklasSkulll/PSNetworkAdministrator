# AI Agent Setup Guide - PSNetworkAdministrator

This guide provides comprehensive instructions for AI agents (OpenAI Codex, GitHub Copilot, etc.) to install dependencies and set up the development environment for the PSNetworkAdministrator PowerShell module.

## Project Overview

PSNetworkAdministrator is a comprehensive PowerShell module for network and Active Directory administration. It follows standard PowerShell module conventions and GitHub project structure.

## System Requirements

### Operating System
- Windows 10/11 (recommended)
- Windows Server 2016/2019/2022
- PowerShell 5.1 or PowerShell 7+ (Core)

### Required Components
1. **PowerShell ExecutionPolicy**: Set to allow script execution
2. **Active Directory PowerShell Module** (for AD operations)
3. **RSAT Tools** (Remote Server Administration Tools)
4. **Network connectivity** to domain controllers (for testing)

## Installation Instructions

### 1. PowerShell Installation

#### Install PowerShell (if not already installed)

**Windows PowerShell 5.1** (comes with Windows 10/11 and Server 2016+):
```powershell
# Check if Windows PowerShell is available
$PSVersionTable.PSVersion

# Windows PowerShell 5.1 is pre-installed on modern Windows systems
# If missing, install via Windows Features or Windows Updates
```

**PowerShell 7+ (Cross-platform, recommended for new projects):**
```powershell
# Method 1: Install via Windows Package Manager (winget)
winget install Microsoft.PowerShell

# Method 2: Install via Chocolatey
choco install powershell-core

# Method 3: Install via Scoop
scoop install pwsh

# Method 4: Download and install manually
# Download from: https://github.com/PowerShell/PowerShell/releases
```

**Install via PowerShell Gallery (if PowerShell is already available):**
```powershell
# Install PowerShell 7+ via PowerShell Gallery
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"
```

**Verify PowerShell Installation:**
```powershell
# Check PowerShell version
$PSVersionTable

# Verify PowerShell executable paths
Get-Command powershell -ErrorAction SilentlyContinue
Get-Command pwsh -ErrorAction SilentlyContinue

# Test basic functionality
Write-Host "PowerShell is working!" -ForegroundColor Green
```

### 2. PowerShell Execution Policy
```powershell
# Check current execution policy
Get-ExecutionPolicy

# Set execution policy to allow script execution (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
# or for current user only:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. Active Directory PowerShell Module

#### Windows Server
```powershell
# Install AD PowerShell module on Windows Server
Install-WindowsFeature -Name RSAT-AD-PowerShell
```

#### Windows 10/11 Client
```powershell
# Enable RSAT features (run as Administrator)
Enable-WindowsOptionalFeature -Online -FeatureName RSATClient-Roles-AD-Powershell

# Alternative: Install via Windows Features
# Go to: Settings > Apps > Optional Features > Add Feature > RSAT: Active Directory Domain Services and Lightweight Directory Services Tools
```

#### Alternative Installation Methods
```powershell
# Method 1: Install via PowerShell Gallery (if available)
Install-Module -Name ActiveDirectory -Force -AllowClobber

# Method 2: Download RSAT for Windows 10
# Download from: https://www.microsoft.com/en-us/download/details.aspx?id=45520
```

### 4. Required PowerShell Modules
```powershell
# Install required modules from PowerShell Gallery
Install-Module -Name PowerShellGet -Force -AllowClobber
Install-Module -Name PackageManagement -Force -AllowClobber

# Optional: Install additional network tools
Install-Module -Name NetTCPIP -Force -AllowClobber
Install-Module -Name DnsClient -Force -AllowClobber
```

### 5. Verify Installation
```powershell
# Verify Active Directory module
Get-Module -ListAvailable -Name ActiveDirectory

# Verify PowerShell version
$PSVersionTable

# Test basic AD connectivity (requires domain environment)
try {
    Get-ADDomain -ErrorAction Stop
    Write-Host "✓ Active Directory module working" -ForegroundColor Green
} catch {
    Write-Host "⚠ AD module installed but no domain connectivity" -ForegroundColor Yellow
}
```

## Project Structure

```
PSNetworkAdministrator/
├── PSNetworkAdministrator.ps1          # Main entry script
├── PSNetworkAdministrator/              # Module directory
│   ├── PSNetworkAdministrator.psd1     # Module manifest
│   ├── PSNetworkAdministrator.psm1     # Main module file
│   ├── Classes/                        # PowerShell classes
│   │   └── NetworkAdminClasses.ps1
│   ├── Private/                        # Internal functions
│   │   ├── ADOperations.ps1
│   │   ├── CacheManager.ps1
│   │   ├── ConfigurationManager.ps1
│   │   ├── NetworkOperations.ps1
│   │   └── UtilityFunctions.ps1
│   └── Public/                         # Exported functions
│       ├── ComputerManagement.ps1
│       ├── DHCPInfo.ps1
│       ├── DNSManagement.ps1
│       ├── DomainControllerInfo.ps1
│       ├── GroupManagement.ps1
│       ├── MainInterface.ps1
│       ├── NetworkDiagnostics.ps1
│       ├── SecurityAudit.ps1
│       └── UserManagement.ps1
├── config.json                         # Configuration file
├── NetworkAdminLog.txt                 # Log file
├── README.md                           # Project documentation
└── AGENTS.md                           # This file
```

## Development Environment Setup

### 1. Clone and Setup
```powershell
# Navigate to project directory
cd "d:\gitProjekte\PSNetworkAdministrator"

# Verify all files are present
Get-ChildItem -Recurse -File | Select-Object Name, Directory
```

### 2. Test Module Loading
```powershell
# Test module import
try {
    Import-Module ".\PSNetworkAdministrator\PSNetworkAdministrator.psd1" -Force -Verbose
    Write-Host "✓ Module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Module loading failed: $($_.Exception.Message)" -ForegroundColor Red
}

# List exported functions
Get-Command -Module PSNetworkAdministrator
```

### 3. Test Basic Functionality
```powershell
# Test configuration loading
try {
    $config = Get-NetworkAdminConfig
    Write-Host "✓ Configuration loaded" -ForegroundColor Green
} catch {
    Write-Host "⚠ Configuration loading failed" -ForegroundColor Yellow
}

# Test main entry point
try {
    # Run with help parameter to test basic functionality
    .\PSNetworkAdministrator.ps1 -NoLog
} catch {
    Write-Host "✗ Main script failed: $($_.Exception.Message)" -ForegroundColor Red
}
```

## Testing Environment

### Mock Domain Environment (for testing without AD)
```powershell
# Create mock domain variables for testing
$script:Domain = "test.local"
$script:Credential = $null
$script:NoLog = $true

# Test network operations without AD dependency
Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
```

### Real Domain Environment
```powershell
# Set actual domain for testing
$script:Domain = "yourdomain.local"

# Test domain connectivity
Test-NetworkAdminConnectivity -Target $script:Domain -Type Domain
```

## Common Issues and Solutions

### Issue 1: Active Directory Module Not Found
```powershell
# Solution: Install RSAT or AD PowerShell module
# Windows Server:
Install-WindowsFeature -Name RSAT-AD-PowerShell

# Windows Client:
Enable-WindowsOptionalFeature -Online -FeatureName RSATClient-Roles-AD-Powershell
```

### Issue 2: Execution Policy Restrictions
```powershell
# Solution: Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue 3: Module Import Errors
```powershell
# Check for syntax errors in individual files
Get-ChildItem ".\PSNetworkAdministrator\Private\*.ps1" | ForEach-Object {
    try {
        . $_.FullName
        Write-Host "✓ $($_.Name)" -ForegroundColor Green
    } catch {
        Write-Host "✗ $($_.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}
```

### Issue 4: Missing Dependencies
```powershell
# Verify all required modules
$requiredModules = @('ActiveDirectory', 'DnsClient', 'NetTCPIP')
foreach ($module in $requiredModules) {
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host "✓ $module available" -ForegroundColor Green
    } else {
        Write-Host "✗ $module missing" -ForegroundColor Red
    }
}
```

## AI Agent Quick Start Commands

### Complete Environment Setup (Windows)
```powershell
# Step 1: Install PowerShell 7+ (if desired)
winget install Microsoft.PowerShell

# Step 2: Set execution policy and install dependencies
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Install-WindowsFeature -Name RSAT-AD-PowerShell -ErrorAction SilentlyContinue
Enable-WindowsOptionalFeature -Online -FeatureName RSATClient-Roles-AD-Powershell -All -ErrorAction SilentlyContinue

# Step 3: Navigate to project and test module
cd "d:\gitProjekte\PSNetworkAdministrator"
Import-Module ".\PSNetworkAdministrator\PSNetworkAdministrator.psd1" -Force
Get-Command -Module PSNetworkAdministrator
```

### Minimal Setup (Windows PowerShell 5.1)
```powershell
# Quick setup using built-in Windows PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Enable-WindowsOptionalFeature -Online -FeatureName RSATClient-Roles-AD-Powershell -All -ErrorAction SilentlyContinue
cd "d:\gitProjekte\PSNetworkAdministrator"
Import-Module ".\PSNetworkAdministrator\PSNetworkAdministrator.psd1" -Force
```

## Development Guidelines

### Code Style
- Follow PowerShell best practices
- Use approved verbs for function names
- Include proper comment-based help
- Use proper error handling with try/catch blocks

### Testing
- Test module loading before making changes
- Verify individual function files can be dot-sourced
- Test with and without Active Directory connectivity
- Validate configuration file loading

### Debugging
```powershell
# Enable verbose output
$VerbosePreference = "Continue"

# Enable debug output
$DebugPreference = "Continue"

# Test specific functions
Import-Module ".\PSNetworkAdministrator\PSNetworkAdministrator.psd1" -Force -Verbose
```

## Contact and Support

This module is designed for network administrators working with Active Directory environments. For AI agents working on this codebase:

1. Always test module loading after making changes
2. Verify syntax with PowerShell's parser before committing
3. Test both with and without AD connectivity
4. Follow PowerShell module development best practices

## Version Information

- PowerShell Module Version: 2.0
- Minimum PowerShell Version: 5.1
- Compatible with: Windows PowerShell 5.1, PowerShell 7+
- Last Updated: June 2025
