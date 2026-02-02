# ------------------------------
# start of the Administrator Tool "PSNetworkAdministrator"
# ------------------------------

# import the module "PSNetworkAdministrator"
Import-Module "$PSScriptRoot\..\PSNetworkAdministrator\PSNetworkAdministrator.psd1" -Force

# load configuration
$script:AppConfiguration = Initialize-Configuration
Write-Host ""
Write-Host "  ╔═╗╔═╗╔╗╔╔═╗╔╦╗╦ ╦╔═╗╦═╗╦╔═" -ForegroundColor Magenta
Write-Host "  ╠═╝╚═╗║║║║╣  ║ ║║║║ ║╠╦╝╠╩╗" -ForegroundColor Magenta
Write-Host "  ╩  ╚═╝╝╚╝╚═╝ ╩ ╚╩╝╚═╝╩╚═╩ ╩" -ForegroundColor Magenta
Write-Host "  ╔═╗╔╦╗╔╦╗╦╔╗╔╦╔═╗╔╦╗╦═╗╔═╗╔╦╗╔═╗╦═╗" -ForegroundColor Magenta
Write-Host "  ╠═╣ ║║║║║║║║║║╚═╗ ║ ╠╦╝╠═╣ ║ ║ ║╠╦╝" -ForegroundColor Magenta
Write-Host "  ╩ ╩═╩╝╩ ╩╩╝╚╝╩╚═╝ ╩ ╩╚═╩ ╩ ╩ ╚═╝╩╚═" -ForegroundColor Magenta
Write-Host "  Version $($AppConfiguration.Version)" -ForegroundColor Magenta
Write-Host ""

# start logging
$script:LoggingPath = Join-Path $PSScriptRoot "..\..\$($AppConfiguration.Logging.LoggingPath)"
Write-AppLogging -LoggingMessage "===== PSNetworkAdministrator Starting =====" -LoggingLevel Info -LoggingPath $LoggingPath

try {
    # run checks
    Write-AppLogging -LoggingMessage "Running startup checks." -LoggingLevel Info -LoggingPath $LoggingPath

    Test-PowerShellVersion
    Test-OperatingSystem
    Test-ExecutionContext
    Test-WpfAvailability

    Write-AppLogging -LoggingMessage "All startup checks successfully passed." -LoggingLevel Success -LoggingPath $LoggingPath
}
catch {
    Write-AppLogging -LoggingMessage "Startup check failed: $_" -LoggingLevel Error -LoggingPath $LoggingPath
    exit 1
}