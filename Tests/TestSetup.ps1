<#
.SYNOPSIS
    Sets up the test environment for PSNetworkAdministrator.

.DESCRIPTION
    This script initializes the test environment for the PSNetworkAdministrator module.
    It defines global test variables, creates mock functions, and provides utilities
    for importing the module and creating test log files.

.EXAMPLE
    . .\TestSetup.ps1
    Import-ModuleForTest

.NOTES
    This script is meant to be dot-sourced by test scripts.
    It should be run from the Tests directory.
#>

# Import Pester if not already available
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installing Pester module for testing..."
    Install-Module -Name Pester -Force -SkipPublisherCheck -MinimumVersion 5.0.0
}

# Define global test variables
$script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$script:ModulePath = Join-Path -Path $script:ProjectRoot -ChildPath 'PSNetworkAdministrator'
$script:ModuleName = 'PSNetworkAdministrator'
$script:ModuleManifestPath = Join-Path -Path $script:ModulePath -ChildPath "$script:ModuleName.psd1"

# Create mock domain environment settings for testing
$script:TestDomain = 'contoso.test'
$script:TestDC = 'DC01'
$script:TestCredentials = [PSCredential]::new('administrator', (ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force))

# Mock functions that require AD connectivity
function Test-MockADConnection {
    param($Domain = $script:TestDomain)
    # Mock implementation for testing
    return $true
}

# Function to import the module under test
function Import-ModuleForTest {
    # Remove module if already loaded
    if (Get-Module -Name $script:ModuleName) {
        Remove-Module -Name $script:ModuleName -Force
    }
    
    # Import the module
    Import-Module -Name $script:ModuleManifestPath -Force
}

# Create a temporary log directory for test logs
$script:TestLogDirectory = Join-Path -Path $script:ProjectRoot -ChildPath 'Logs\TestLogs'
if (-not (Test-Path -Path $script:TestLogDirectory)) {
    New-Item -Path $script:TestLogDirectory -ItemType Directory -Force | Out-Null
}

# Function to create test log file
function New-TestLogFile {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $logFileName = "PSNetworkAdmin_Test_$timestamp.log"
    $logFilePath = Join-Path -Path $script:TestLogDirectory -ChildPath $logFileName
    return $logFilePath
}

# Export test setup functions and variables
Export-ModuleMember -Function Import-ModuleForTest, Test-MockADConnection, New-TestLogFile -Variable ProjectRoot, ModulePath, ModuleName, TestDomain, TestDC, TestCredentials, TestLogDirectory
