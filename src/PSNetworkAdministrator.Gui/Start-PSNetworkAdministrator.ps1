# ------------------------------
# start of the Administrator Tool "PSNetworkAdministrator"
# ------------------------------

# import the module
Import-Module "$PSScriptRoot\..\PSNetworkAdministrator\PSNetworkAdministrator.psd1" -Force

# run checks
Write-Host "`nChecking current PowerShell Version..." -ForegroundColor Yellow
if (-not (Test-PowerShellVersion)) { exit 1 }

Write-Host "`nChecking current Operation System..." -ForegroundColor Yellow
if (-not (Test-OperatingSystem)) { exit 1 }

Write-Host "`nChecking current Execution Context..." -ForegroundColor Yellow
if (-not (Test-ExecutionContext)) { exit 1 }
