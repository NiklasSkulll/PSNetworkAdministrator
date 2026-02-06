# ------------------------------
# start of the Administrator Tool "PSNetworkAdministrator"
# ------------------------------

# import the module "PSNetworkAdministrator"
try {
    Import-Module "$PSScriptRoot\..\PSNetworkAdministrator\PSNetworkAdministrator.psd1" -Force
}
catch {
    Write-Host "Import-Module 'PSNetworkAdministrator.psd1' failed." -ForegroundColor Red
    Write-Host "Possible reasons: PowerShell Version is below 7" -ForegroundColor Red

    Write-Host "`nView Module information for more context:" -ForegroundColor Red
    $ViewManifest = Import-PowerShellDataFile -Path "$PSScriptRoot\..\PSNetworkAdministrator\PSNetworkAdministrator.psd1"
    $ViewManifest
}

# load configuration
$script:AppConfiguration = Initialize-Configuration

# display PSNetworkAdministrator ASCII + Version
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

    Test-ExecutionContext

    Write-AppLogging -LoggingMessage "All startup checks successfully passed." -LoggingLevel Success -LoggingPath $LoggingPath
}
catch {
    Write-AppLogging -LoggingMessage "Startup check failed: $_" -LoggingLevel Error -LoggingPath $LoggingPath
    exit 1
}