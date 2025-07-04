<#
.SYNOPSIS
    Displays status information for PSNetworkAdministrator
.DESCRIPTION
    Shows a formatted display of the PSNetworkAdministrator status object
.PARAMETER StatusObject
    The status object to display, typically created with New-StatusObject
.EXAMPLE
    $status = New-StatusObject
    Show-StatusInformation -StatusObject $status
.NOTES
    For internal module use only
#>
function Show-StatusInformation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$StatusObject
    )
    
    Write-Host "`n "
    Write-Host "  PSNetworkAdministrator Status:" -ForegroundColor Cyan
    Write-Host "  ModuleName  : $($StatusObject.ModuleName)" -ForegroundColor Gray
    Write-Host "  Version     : $($StatusObject.Version)" -ForegroundColor Gray
    Write-Host "  Status      : $($StatusObject.Status)" -ForegroundColor Gray
    Write-Host "  Domain      : $($StatusObject.Domain)" -ForegroundColor Gray
    Write-Host "  Timestamp   : $($StatusObject.Timestamp)" -ForegroundColor Gray
    if ($StatusObject.UserChoice) {
        Write-Host "  UserChoice : $($StatusObject.UserChoice)" -ForegroundColor Gray
    }
    Write-Host # Add another blank line
}
