# TestEnvironment.ps1
# This script creates a basic test environment with mock objects
# without actually running any tests

# Load test setup and mock generator
. "$PSScriptRoot\TestSetup.ps1"
. "$PSScriptRoot\MockGenerator.ps1"

function Initialize-TestEnvironment {
    param (
        [Parameter()]
        [switch]$Verbose
    )
    
    # Create test data directory if it doesn't exist
    $testDataDir = Join-Path -Path $PSScriptRoot -ChildPath "TestData"
    if (-not (Test-Path -Path $testDataDir)) {
        New-Item -Path $testDataDir -ItemType Directory -Force | Out-Null
    }
    
    # Create sample test data files
    $userDataFile = Join-Path -Path $testDataDir -ChildPath "TestUsers.csv"
    if (-not (Test-Path -Path $userDataFile)) {
        @"
SamAccountName,DisplayName,Department,Title,Enabled
jsmith,John Smith,IT,Systems Administrator,TRUE
mwilson,Mary Wilson,HR,HR Manager,TRUE
rjones,Robert Jones,Finance,Accountant,TRUE
asmith,Alice Smith,IT,Developer,FALSE
"@ | Out-File -FilePath $userDataFile -Encoding utf8
        
        if ($Verbose) {
            Write-Host "Created test user data file at: $userDataFile" -ForegroundColor Cyan
        }
    }
    
    $computerDataFile = Join-Path -Path $testDataDir -ChildPath "TestComputers.csv"
    if (-not (Test-Path -Path $computerDataFile)) {
        @"
Name,OperatingSystem,IPAddress,Enabled
WS001,Windows 10,192.168.1.101,TRUE
WS002,Windows 11,192.168.1.102,TRUE
SRV001,Windows Server 2022,192.168.1.10,TRUE
SRV002,Windows Server 2019,192.168.1.11,FALSE
"@ | Out-File -FilePath $computerDataFile -Encoding utf8
        
        if ($Verbose) {
            Write-Host "Created test computer data file at: $computerDataFile" -ForegroundColor Cyan
        }
    }
    
    # Create mock objects
    $mockUsers = @(
        New-MockADUser -SamAccountName "jsmith" -DisplayName "John Smith" -Department "IT"
        New-MockADUser -SamAccountName "mwilson" -DisplayName "Mary Wilson" -Department "HR"
        New-MockADUser -SamAccountName "rjones" -DisplayName "Robert Jones" -Department "Finance"
    )
    
    $mockComputers = @(
        New-MockADComputer -Name "WS001" -OperatingSystem "Windows 10"
        New-MockADComputer -Name "SRV001" -OperatingSystem "Windows Server 2022"
    )
    
    $mockGroups = @(
        New-MockADGroup -Name "IT Staff" -GroupCategory "Security" -GroupScope "Global"
        New-MockADGroup -Name "HR Staff" -GroupCategory "Security" -GroupScope "Global"
        New-MockADGroup -Name "Domain Admins" -GroupCategory "Security" -GroupScope "Global"
    )
    
    # Save mock objects to files for test reference
    if ($Verbose) {
        Write-Host "Creating mock object data files..." -ForegroundColor Cyan
    }
    
    $mockUsers | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path -Path $testDataDir -ChildPath "MockUsers.json") -Encoding utf8
    $mockComputers | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path -Path $testDataDir -ChildPath "MockComputers.json") -Encoding utf8
    $mockGroups | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path -Path $testDataDir -ChildPath "MockGroups.json") -Encoding utf8
    
    # Create mock event logs for security audit testing
    $securityEventsFile = Join-Path -Path $testDataDir -ChildPath "SecurityEvents.csv"
    if (-not (Test-Path -Path $securityEventsFile)) {
        @"
EventID,TimeCreated,Message,Level
4624,$(Get-Date).AddDays(-1).ToString('yyyy-MM-dd HH:mm:ss'),An account was successfully logged on,Information
4625,$(Get-Date).AddDays(-1).AddHours(2).ToString('yyyy-MM-dd HH:mm:ss'),An account failed to log on,Warning
4634,$(Get-Date).AddDays(-1).AddHours(8).ToString('yyyy-MM-dd HH:mm:ss'),An account was logged off,Information
4740,$(Get-Date).AddDays(-1).AddHours(12).ToString('yyyy-MM-dd HH:mm:ss'),A user account was locked out,Warning
"@ | Out-File -FilePath $securityEventsFile -Encoding utf8
        
        if ($Verbose) {
            Write-Host "Created mock security events file at: $securityEventsFile" -ForegroundColor Cyan
        }
    }
    
    # Create mock system health data
    $systemHealthFile = Join-Path -Path $testDataDir -ChildPath "SystemHealth.csv"
    if (-not (Test-Path -Path $systemHealthFile)) {
        @"
ServerName,CPUUsage,MemoryUsage,DiskFree,Status
DC01,15,45,75,Healthy
SRV001,65,80,35,Warning
SRV002,25,40,85,Healthy
"@ | Out-File -FilePath $systemHealthFile -Encoding utf8
        
        if ($Verbose) {
            Write-Host "Created mock system health file at: $systemHealthFile" -ForegroundColor Cyan
        }
    }
    
    if ($Verbose) {
        Write-Host "Test environment initialized successfully!" -ForegroundColor Green
        Write-Host "Test data directory: $testDataDir" -ForegroundColor Gray
    }
    
    # Return the test data directory path
    return $testDataDir
}

# Export function
Export-ModuleMember -Function Initialize-TestEnvironment
