# Verify-TestEnvironment.ps1
# This script verifies that the test environment is properly set up

param (
    [switch]$Initialize
)

# Import the test setup and environment scripts
. "$PSScriptRoot\TestSetup.ps1"
. "$PSScriptRoot\TestEnvironment.ps1"

# Initialize the test environment if requested
if ($Initialize) {
    Write-Host "Initializing test environment..." -ForegroundColor Cyan
    $testDataDir = Initialize-TestEnvironment -Verbose
    Write-Host "Test data directory: $testDataDir" -ForegroundColor Green
}

# Verify the module can be imported
try {
    Import-ModuleForTest
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Verify test data exists
$testDataDir = Join-Path -Path $PSScriptRoot -ChildPath "TestData"
if (Test-Path -Path $testDataDir) {
    Write-Host "✓ Test data directory exists: $testDataDir" -ForegroundColor Green
    
    # Check for expected test data files
    $expectedFiles = @(
        "TestUsers.csv",
        "TestComputers.csv",
        "MockUsers.json",
        "MockComputers.json",
        "MockGroups.json",
        "SecurityEvents.csv",
        "SystemHealth.csv"
    )
    
    $missingFiles = $expectedFiles | Where-Object { -not (Test-Path -Path (Join-Path -Path $testDataDir -ChildPath $_)) }
    
    if ($missingFiles.Count -eq 0) {
        Write-Host "✓ All expected test data files exist" -ForegroundColor Green
    } else {
        Write-Host "✗ Missing test data files: $($missingFiles -join ', ')" -ForegroundColor Yellow
        Write-Host "  Run with -Initialize to create test data files" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Test data directory does not exist: $testDataDir" -ForegroundColor Yellow
    Write-Host "  Run with -Initialize to create test data directory" -ForegroundColor Yellow
}

# Verify log directory exists
if (Test-Path -Path $script:TestLogDirectory) {
    Write-Host "✓ Test log directory exists: $script:TestLogDirectory" -ForegroundColor Green
} else {
    Write-Host "✗ Test log directory does not exist: $script:TestLogDirectory" -ForegroundColor Yellow
    Write-Host "  Creating test log directory..." -ForegroundColor Yellow
    New-Item -Path $script:TestLogDirectory -ItemType Directory -Force | Out-Null
}

# Try to create a test log file
try {
    $logFile = New-TestLogFile
    Write-Host "✓ Test log file created: $logFile" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to create test log file: $_" -ForegroundColor Red
}

# Overall verification result
Write-Host "`nTest Environment Verification Summary:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Module Path: $script:ModulePath" -ForegroundColor White
Write-Host "Module Name: $script:ModuleName" -ForegroundColor White
Write-Host "Test Domain: $script:TestDomain" -ForegroundColor White
Write-Host "Test DC: $script:TestDC" -ForegroundColor White
Write-Host "Test Log Directory: $script:TestLogDirectory" -ForegroundColor White

if (Test-Path -Path "$script:ModulePath\$script:ModuleName.psd1") {
    Write-Host "`n✓ Module manifest exists" -ForegroundColor Green
    Write-Host "`nTest environment is properly set up!" -ForegroundColor Green
} else {
    Write-Host "`n✗ Module manifest does not exist: $script:ModulePath\$script:ModuleName.psd1" -ForegroundColor Red
    Write-Host "`nTest environment setup is incomplete." -ForegroundColor Red
}
