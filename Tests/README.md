# PSNetworkAdministrator Test Environment

This folder contains the test environment setup for the PSNetworkAdministrator module.

## Test Environment Components

- `pester.config.ps1` - Pester configuration settings for the test environment
- `TestSetup.ps1` - Core setup script with shared variables and functions
- `MockGenerator.ps1` - Functions to generate mock objects for testing
- `TestEnvironment.ps1` - Script to initialize a test environment with sample data
- `Start-Tests.ps1` - Script to start the test environment without running tests

## Setup Instructions

1. Open PowerShell as Administrator
2. Navigate to the Tests directory
3. Run the setup script:

```powershell
# Configure the test environment without running tests
.\Start-Tests.ps1 -ConfigureOnly
```

## Test Data

When you initialize the test environment, it creates a `TestData` directory with sample data files:

- `TestUsers.csv` - Sample user data for importing
- `TestComputers.csv` - Sample computer data for importing
- `MockUsers.json` - Mock AD user objects
- `MockComputers.json` - Mock AD computer objects
- `MockGroups.json` - Mock AD group objects
- `SecurityEvents.csv` - Sample security event log entries
- `SystemHealth.csv` - Sample system health metrics

## Mock Objects

The `MockGenerator.ps1` script provides functions to create mock objects for testing:

- `New-MockADUser` - Creates a mock AD user object
- `New-MockADComputer` - Creates a mock AD computer object
- `New-MockADGroup` - Creates a mock AD group object
- `New-MockDNSRecord` - Creates a mock DNS record
- `New-MockDHCPScope` - Creates a mock DHCP scope

## Initializing the Test Environment

To initialize the test environment with sample data:

```powershell
# First, import the test environment script
. .\TestEnvironment.ps1

# Then initialize the test environment
Initialize-TestEnvironment -Verbose
```

This will create the necessary test data files and mock objects for testing.

## Test Setup Functions

The `TestSetup.ps1` script provides several useful functions and variables:

- `Import-ModuleForTest` - Imports the module for testing
- `Test-MockADConnection` - Mock function for testing AD connectivity
- `New-TestLogFile` - Creates a new log file for testing

## Global Test Variables

- `$script:ProjectRoot` - Root directory of the project
- `$script:ModulePath` - Path to the module directory
- `$script:ModuleName` - Name of the module
- `$script:TestDomain` - Test domain name (contoso.test)
- `$script:TestDC` - Test domain controller name (DC01)
- `$script:TestLogDirectory` - Directory for test logs
