# PSNetworkAdministrator Syntax and Import Test Script
# This script tests all PowerShell files for syntax errors and import issues

param(
    [switch]$Verbose
)

function Test-PSScriptSyntax {
    param(
        [string]$FilePath,
        [string]$DisplayName
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Host "✗ $DisplayName - File not found" -ForegroundColor Red
            return $false
        }
        
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
        $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
        Write-Host "✓ $DisplayName - Syntax OK" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "✗ $DisplayName - Syntax Error:" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

function Test-ModuleImport {
    param(
        [string]$ModulePath
    )
    
    try {
        # Test module manifest
        $manifest = Test-ModuleManifest $ModulePath -ErrorAction Stop
        Write-Host "✓ Module manifest is valid" -ForegroundColor Green
        
        # Try to import the module
        Import-Module $ModulePath -Force -ErrorAction Stop
        Write-Host "✓ Module imported successfully" -ForegroundColor Green
        
        # Test if exported functions are available
        $exportedFunctions = Get-Command -Module PSNetworkAdministrator -ErrorAction SilentlyContinue
        if ($exportedFunctions) {
            Write-Host "✓ Exported functions found: $($exportedFunctions.Count) functions" -ForegroundColor Green
            if ($Verbose) {
                foreach ($func in $exportedFunctions) {
                    Write-Host "  - $($func.Name)" -ForegroundColor Cyan
                }
            }
        } else {
            Write-Host "⚠ No exported functions found" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Host "✗ Module import failed:" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

# Main execution
Write-Host "===== PSNetworkAdministrator Project Analysis =====" -ForegroundColor Cyan
Write-Host ""

$allTestsPassed = $true

# Test main entry point
Write-Host "Testing Main Entry Point..." -ForegroundColor Yellow
$result = Test-PSScriptSyntax -FilePath "PSNetworkAdministrator.ps1" -DisplayName "PSNetworkAdministrator.ps1"
$allTestsPassed = $allTestsPassed -and $result
Write-Host ""

# Test module files
Write-Host "Testing Module Files..." -ForegroundColor Yellow
$result = Test-PSScriptSyntax -FilePath "PSNetworkAdministrator\PSNetworkAdministrator.psm1" -DisplayName "PSNetworkAdministrator.psm1"
$allTestsPassed = $allTestsPassed -and $result

$result = Test-PSScriptSyntax -FilePath "PSNetworkAdministrator\PSNetworkAdministrator.psd1" -DisplayName "PSNetworkAdministrator.psd1"
$allTestsPassed = $allTestsPassed -and $result
Write-Host ""

# Test Classes
Write-Host "Testing Classes..." -ForegroundColor Yellow
$result = Test-PSScriptSyntax -FilePath "PSNetworkAdministrator\Classes\NetworkAdminClasses.ps1" -DisplayName "Classes\NetworkAdminClasses.ps1"
$allTestsPassed = $allTestsPassed -and $result
Write-Host ""

# Test Private functions
Write-Host "Testing Private Functions..." -ForegroundColor Yellow
$privateFiles = @(
    "ADOperations.ps1",
    "CacheManager.ps1", 
    "ConfigurationManager.ps1",
    "NetworkOperations.ps1",
    "UtilityFunctions.ps1"
)

foreach ($file in $privateFiles) {
    $result = Test-PSScriptSyntax -FilePath "PSNetworkAdministrator\Private\$file" -DisplayName "Private\$file"
    $allTestsPassed = $allTestsPassed -and $result
}
Write-Host ""

# Test Public functions
Write-Host "Testing Public Functions..." -ForegroundColor Yellow
$publicFiles = @(
    "ComputerManagement.ps1",
    "DHCPInfo.ps1",
    "DNSManagement.ps1",
    "DomainControllerInfo.ps1",
    "GroupManagement.ps1",
    "MainInterface.ps1",
    "NetworkDiagnostics.ps1",
    "SecurityAudit.ps1",
    "UserManagement.ps1"
)

foreach ($file in $publicFiles) {
    $result = Test-PSScriptSyntax -FilePath "PSNetworkAdministrator\Public\$file" -DisplayName "Public\$file"
    $allTestsPassed = $allTestsPassed -and $result
}
Write-Host ""

# Test module import
Write-Host "Testing Module Import..." -ForegroundColor Yellow
$result = Test-ModuleImport -ModulePath "PSNetworkAdministrator\PSNetworkAdministrator.psd1"
$allTestsPassed = $allTestsPassed -and $result
Write-Host ""

# Summary
Write-Host "===== Test Summary =====" -ForegroundColor Cyan
if ($allTestsPassed) {
    Write-Host "✅ All tests passed! The project syntax and imports are working correctly." -ForegroundColor Green
} else {
    Write-Host "❌ Some tests failed. Please review the errors above." -ForegroundColor Red
}

# Additional information
Write-Host "`n===== Additional Project Information =====" -ForegroundColor Cyan
try {
    $manifest = Import-PowerShellDataFile "PSNetworkAdministrator\PSNetworkAdministrator.psd1"
    Write-Host "Module Version: $($manifest.ModuleVersion)" -ForegroundColor Cyan
    Write-Host "PowerShell Version Required: $($manifest.PowerShellVersion)" -ForegroundColor Cyan
    Write-Host "Author: $($manifest.Author)" -ForegroundColor Cyan
    Write-Host "Description: $($manifest.Description)" -ForegroundColor Cyan
} catch {
    Write-Host "Could not read module manifest details" -ForegroundColor Yellow
}
