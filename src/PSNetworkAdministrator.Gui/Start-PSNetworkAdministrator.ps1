# ------------------------------
# start of the Administrator Tool "PSNetworkAdministrator"
# ------------------------------

# import the module "PSNetworkAdministrator"
Import-Module "$PSScriptRoot\..\PSNetworkAdministrator\PSNetworkAdministrator.psd1" -Force

try {
    # run checks
    Test-PowerShellVersion
    Test-OperatingSystem
    Test-ExecutionContext
    Test-WpfAvailability

}
catch {
    Write-Host "Startup check failed: $_" -ForegroundColor Red
    exit 1
}