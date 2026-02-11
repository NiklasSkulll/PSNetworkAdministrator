function Initialize-Domain {
    <#
    .SYNOPSIS
        Checks if User is in a Domain and adds it.
    #>

    [CmdletBinding()]
    param()

    # check if user is in a Domain (true/false)
    $IsDomain = (Get-CimInstance Win32_ComputerSystem).PartOfDomain

    # if user is in a Domain, return Domain name
    if ($IsDomain) {
        $UserDomain = (Get-CimInstance Win32_ComputerSystem).Domain
        Write-AppLogging -LoggingMessage "User is in Domain: $UserDomain" -LoggingLevel "Info"
        Return [PSCustomObject]@{
            UserDomain = $UserDomain
        }
    }
    else {
        throw "User isn't in a Domain. Please add a Domain."
    }
}