# Run-Tests.ps1
# Script to run all tests for PSNetworkAdministrator

[CmdletBinding()]
param(
    [switch]$SkipCodeCoverage,
    [switch]$GenerateReport,
    [switch]$Force,
    [switch]$NonInteractive
)

# Ensure we're running from the project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -Path $projectRoot

Write-Host "Running Pester tests for PSNetworkAdministrator..." -ForegroundColor Cyan

# Define minimum required Pester version
$requiredVersion = [Version]"5.0.0"

# Check if Pester is installed and the version
$pesterModule = Get-Module -ListAvailable -Name Pester
if (-not $pesterModule) {
    Write-Host "Pester module is not installed." -ForegroundColor Yellow
    $installChoice = $null
    
    if ($NonInteractive -or $Force) {
        $installChoice = 'Y'
    }
    else {
        Write-Host "Would you like to install Pester v5.0.0? (Y/N/Q to quit): " -ForegroundColor Cyan -NoNewline
        $installChoice = Read-Host
    }
    
    if ($Force -or $installChoice -eq 'Y' -or $installChoice -eq 'y') {
        try {
            Write-Host "Installing Pester module v5.0.0..." -ForegroundColor Cyan
            Install-Module -Name Pester -MinimumVersion $requiredVersion -Force -SkipPublisherCheck
            Write-Host "Pester module installed successfully." -ForegroundColor Green
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Error "Failed to install Pester module. Error: $errorMessage"
            return
        }
    }
    elseif ($installChoice -eq 'Q' -or $installChoice -eq 'q') {
        Write-Host "Test execution cancelled." -ForegroundColor Yellow
        return
    }
    else {
        Write-Error "Pester module v$requiredVersion or higher is required to run tests."
        return
    }
}
else {
    # Check version
    $currentVersion = $pesterModule | Sort-Object Version -Descending | Select-Object -First 1 -ExpandProperty Version
    Write-Host "Found Pester version: $currentVersion" -ForegroundColor Cyan
    
    if ($currentVersion -lt $requiredVersion) {
        Write-Host "Current Pester version ($currentVersion) is lower than the required version ($requiredVersion)." -ForegroundColor Yellow
        
        if (-not $Force -and -not $NonInteractive) {
            Write-Host "Would you like to install Pester v5.0.0? (Y/N/Q to quit): " -ForegroundColor Cyan -NoNewline
            $updateChoice = Read-Host
        } else {
            $updateChoice = 'Y'
        }
        
        if ($Force -or $updateChoice -eq 'Y' -or $updateChoice -eq 'y') {
            try {
                Write-Host "Installing Pester module v5.0.0..." -ForegroundColor Cyan
                Install-Module -Name Pester -MinimumVersion $requiredVersion -Force -SkipPublisherCheck
                Write-Host "Pester module installed successfully." -ForegroundColor Green
            }
            catch {
                $errorMessage = $_.Exception.Message
                Write-Error "Failed to install Pester module. Error: $errorMessage"
                return
            }
        }
        elseif ($updateChoice -eq 'Q' -or $updateChoice -eq 'q') {
            Write-Host "Test execution cancelled." -ForegroundColor Yellow
            return
        }
        else {
            Write-Error "Pester module v$requiredVersion or higher is required to run tests."
            return
        }
    }
}

# Import the Pester module
try {
    Import-Module Pester -MinimumVersion $requiredVersion -ErrorAction Stop
    Write-Host "Using Pester v$((Get-Module Pester).Version)" -ForegroundColor Cyan
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Error "Failed to import Pester module v$requiredVersion. Error: $errorMessage"
    return
}

# Set up test environment
$modulePath = Join-Path -Path $projectRoot -ChildPath "PSNetworkAdministrator"
Write-Host "Setting up test environment for PSNetworkAdministrator..." -ForegroundColor Cyan

# Always set up these global test variables
$Global:PSNetworkAdminTestMode = $true
$Global:TestsNonInteractive = $NonInteractive

# Create a safe mock environment
Write-Host "Setting up global test mocks..." -ForegroundColor Cyan

# Override Read-Host to prevent interactive prompts
function global:Read-Host { 
    Write-Verbose "MOCK: Read-Host called and returned 'Q'"
    return "Q" 
}

# Mock Get-Host for ReadKey operations
function global:MockGetHost {
    return [PSCustomObject]@{
        UI = [PSCustomObject]@{
            RawUI = [PSCustomObject]@{
                ReadKey = {
                    param($Options)
                    Write-Verbose "MOCK: ReadKey called and returned 'Q'"
                    return [PSCustomObject]@{ Character = 'Q' }
                }
            }
        }
    }
}

# Save original Get-Host if it exists and isn't already mocked
if ((Get-Command Get-Host -ErrorAction SilentlyContinue) -and 
    (Get-Command Get-Host).ScriptBlock -notmatch 'MockGetHost') {
    $Global:OriginalGetHost = (Get-Command Get-Host).ScriptBlock
    Set-Item -Path function:global:Get-Host -Value ${function:global:MockGetHost}
}

# Override certain UI-related functions to prevent any display during tests
function global:Clear-Host { Write-Verbose "MOCK: Clear-Host called (suppressed)" }

# Completely disable Write-Host during test execution to suppress UI output
function global:Write-Host { 
    param($Object, $ForegroundColor, $NoNewline) 
    # If you need to debug test output, uncomment the line below:
    # Write-Debug "MOCK: Write-Host called with: $Object" 
}

# Set up special test behavior for Get-MenuOption
# This ensures any call to Get-MenuOption during tests will use test mode
if (Get-Command Get-MenuOption -ErrorAction SilentlyContinue) {
    # Create a wrapper that ensures test parameters are set
    $originalMenuOption = Get-Command Get-MenuOption
    function global:Get-MenuOption {
        param(
            [Parameter()]
            [switch]$SkipMenuDisplay,
            [Parameter()]
            [string]$TestInput
        )
        
        # Always force SkipMenuDisplay and provide test input in test environment
        & $originalMenuOption.ScriptBlock -SkipMenuDisplay:$true -TestInput ($TestInput -or "1")
    }
}

# Import only specific files needed for test setup
Write-Host "Loading only the essential module files for testing..." -ForegroundColor Cyan

# We'll import only what we need for testing
try {
    # Import only the files needed for testing
    . (Join-Path -Path $modulePath -ChildPath "Private\Write-Log.ps1")
    Write-Host "Module components loaded directly for testing" -ForegroundColor Green
} catch {
    Write-Warning "Error loading module components: $_"
}

# Make sure test dependencies are available    # Create a mock Write-Log function if it doesn't exist
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    Write-Host "Creating mock Write-Log function for tests" -ForegroundColor Yellow
    function Write-Log {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true, Position = 0)]
            [string]$Message,
            
            [Parameter(Mandatory = $false, Position = 1)]
            [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
            [string]$Level = 'Info',
            
            [Parameter(Mandatory = $false)]
            [string]$LogPath
        )
        Write-Verbose "MOCK: [$Level] $Message"
    }
    # Don't use Export-ModuleMember outside of a module context
    # Make the function available in the global scope instead
    Set-Item -Path function:global:Write-Log -Value ${function:Write-Log}
}

# Get the config file path
$configFile = Join-Path -Path $PSScriptRoot -ChildPath "pester.config.ps1"
if (-not (Test-Path -Path $configFile)) {
    Write-Error "Pester configuration file not found at: $configFile"
    return
}

# Load the configuration
$config = . $configFile

# Modify config if needed
if ($SkipCodeCoverage) {
    $config.CodeCoverage.Enabled = $false
}

# Set run in non-interactive mode if specified
if ($NonInteractive) {
    Write-Host "Running tests in non-interactive mode" -ForegroundColor Cyan
    
    # Update configuration to suppress progress
    $config.Output.Verbosity = 'Detailed'
    $config.Run.Exit = $true
    
    # Modify the Pester session state to isolate tests better
    $config.Run.ScriptBlock = {
        param ($Context)
        # Ensure tests run in isolated scope
        $Global:TestsNonInteractive = $true
        # Override Read-Host to always return "Q" during tests
        function Read-Host { return "Q" }
    }
}

# Run the tests
Write-Host "Running tests with Pester v5 configuration..." -ForegroundColor Cyan
$result = Invoke-Pester -Configuration $config

# Generate HTML report if requested
if ($GenerateReport -and $result) {
    try {
        # Ensure we have the module
        if (-not (Get-Module -ListAvailable -Name PSCodeCoverage)) {
            Write-Host "Installing PSCodeCoverage module for HTML report generation..." -ForegroundColor Cyan
            Install-Module -Name PSCodeCoverage -Force -SkipPublisherCheck
        }
        
        # Import module
        Import-Module PSCodeCoverage
        
        # Generate HTML report
        $reportPath = Join-Path -Path $projectRoot -ChildPath "Tests\CodeCoverageReport"
        if (-not (Test-Path -Path $reportPath)) {
            $null = New-Item -Path $reportPath -ItemType Directory -Force
        }
        
        $coverageXmlPath = Join-Path -Path $projectRoot -ChildPath "Tests\CodeCoverage.xml"
        if (Test-Path -Path $coverageXmlPath) {
            Write-Host "Generating HTML code coverage report..." -ForegroundColor Cyan
            $null = New-CoverageReport -CoverageXmlPath $coverageXmlPath -OutputPath $reportPath
            Write-Host "HTML report generated at: $reportPath\index.html" -ForegroundColor Green
        } else {
            Write-Warning "Code coverage XML file not found. Cannot generate HTML report."
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Warning "Failed to generate HTML report. Error: $errorMessage"
    }
}

# Clean up global variables
if (Get-Variable -Name TestsNonInteractive -Scope Global -ErrorAction SilentlyContinue) {
    Remove-Variable -Name TestsNonInteractive -Scope Global
}

# Output test results summary
if ($result) {
    Write-Host "`nTest Results Summary:" -ForegroundColor Cyan
    Write-Host "  Total Tests   : $($result.TotalCount)" -ForegroundColor White
    Write-Host "  Passed        : $($result.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed        : $($result.FailedCount)" -ForegroundColor Red
    Write-Host "  Skipped       : $($result.SkippedCount)" -ForegroundColor Yellow
    
    if ($result.FailedCount -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        foreach ($failure in $result.Failed) {
            Write-Host "  - $($failure.Name): $($failure.FailureMessage)" -ForegroundColor Red
        }
        exit 1
    }
    else {
        Write-Host "`nAll tests passed!" -ForegroundColor Green
        exit 0
    }
}
else {
    Write-Warning "No test results returned."
    exit 1
}
