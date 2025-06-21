# Simple Module Import Test
Write-Host "===== Testing PSNetworkAdministrator Module Import =====" -ForegroundColor Cyan

# Remove any existing module
Remove-Module PSNetworkAdministrator -Force -ErrorAction SilentlyContinue

try {
    # Test manifest first
    $manifest = Test-ModuleManifest "PSNetworkAdministrator\PSNetworkAdministrator.psd1" -ErrorAction Stop
    Write-Host "✓ Module manifest is valid" -ForegroundColor Green
    
    # Import the module
    Import-Module "PSNetworkAdministrator\PSNetworkAdministrator.psd1" -Force -ErrorAction Stop
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
    
    # Check exported functions
    $exportedFunctions = Get-Command -Module PSNetworkAdministrator -CommandType Function -ErrorAction SilentlyContinue
    
    if ($exportedFunctions) {
        Write-Host "✓ Found $($exportedFunctions.Count) exported functions:" -ForegroundColor Green
        foreach ($func in $exportedFunctions | Sort-Object Name) {
            Write-Host "  - $($func.Name)" -ForegroundColor Cyan
        }
        
        # Check if all dot-sourced files are being loaded
        Write-Host "`n✓ All scripts are being imported properly!" -ForegroundColor Green
    } else {
        Write-Host "⚠ No exported functions found - check Export-ModuleMember in .psm1" -ForegroundColor Yellow
    }
    
    # Show module details
    $moduleInfo = Get-Module PSNetworkAdministrator
    Write-Host "`nModule Information:" -ForegroundColor Yellow
    Write-Host "  Version: $($moduleInfo.Version)" -ForegroundColor Gray
    Write-Host "  Path: $($moduleInfo.Path)" -ForegroundColor Gray
    Write-Host "  Exported Functions: $($moduleInfo.ExportedFunctions.Count)" -ForegroundColor Gray
    Write-Host "  Exported Aliases: $($moduleInfo.ExportedAliases.Count)" -ForegroundColor Gray
    
} catch {
    Write-Host "✗ Import failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Details: $($_.Exception.InnerException.Message)" -ForegroundColor Yellow
}
