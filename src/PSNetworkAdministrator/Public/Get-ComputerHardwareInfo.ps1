function Get-ComputerHardwareInfo {
    <#
    
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    # variables which store the hardware information
    $ComputerCPUInfo = $null
    $ComputerSystemInfo = $null

    # get hardware information from WinRM
    try {
        $WinRMSession = $null

        # CIM over WinRM
        $WinRMSession = New-CimSession -ComputerName $ComputerName
        $ComputerCPUInfo = Get-CimInstance -CimSession $WinRMSession -ClassName Win32_Processor | Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
        $ComputerSystemInfo = Get-CimInstance -CimSession $WinRMSession -ClassName Win32_ComputerSystem | Select-Object DomainRole, Manufacturer, Model, SystemType, @{Name='TotalPhysicalMemoryGB'; Expression={[math]::Round($_.TotalPhysicalMemory/1GB, 2)}}, HypervisorPresent, UserName
    }
    catch {
        $ComputerCPUInfo = $null
        $ComputerSystemInfo = $null
    }
    finally {
        if ($WinRMSession) {Remove-CimSession $WinRMSession}
    }
    
    # if WinRM didnt work, get hardware information from DCOM
    if (-not $ComputerCPUInfo -or -not $ComputerSystemInfo) {
        try {
            $DCOMSession = $null

            # CIM over DCOM
            $DCOMSessionOption = New-CimSessionOption -Protocol Dcom
            $DCOMSession = New-CimSession -ComputerName $ComputerName -SessionOption $DCOMSessionOption
            $ComputerCPUInfo = Get-CimInstance -CimSession $DCOMSession -ClassName Win32_Processor | Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
            $ComputerSystemInfo = Get-CimInstance -CimSession $DCOMSession -ClassName Win32_ComputerSystem | Select-Object DomainRole, Manufacturer, Model, SystemType, @{Name='TotalPhysicalMemoryGB'; Expression={[math]::Round($_.TotalPhysicalMemory/1GB, 2)}}, HypervisorPresent, UserName
        }
        catch {
            $HardwareStatusCPU = if (-not $ComputerCPUInfo) {
                Write-AppLogging -LoggingMessage "Couldn't get the CPU informations from '$ComputerName'." -LoggingLevel "Warning"
                $false
            }
            else
            {$true}
            $HardwareStatusSystem = if (-not $ComputerSystemInfo) {
                Write-AppLogging -LoggingMessage "Couldn't get the system informations from '$ComputerName'." -LoggingLevel "Warning"
                $false
            } else {$true}

            return [PSCustomObject]@{
                ComputerName = $ComputerName
                HardwareStatusCPU = $HardwareStatusCPU
                HardwareStatusSystem = $HardwareStatusSystem
                ComputerCPUInfo = $ComputerCPUInfo
                ComputerSystemInfo = $ComputerSystemInfo
            }
        }
        finally {
            if ($DCOMSession) {Remove-CimSession $DCOMSession}
        }
    }

    $HardwareStatusCPU = if (-not $ComputerCPUInfo) {$false} else {$true}
    $HardwareStatusSystem = if (-not $ComputerSystemInfo) {$false} else {$true}
    return [PSCustomObject]@{
        ComputerName = $ComputerName
        HardwareStatusCPU = $HardwareStatusCPU
        HardwareStatusSystem = $HardwareStatusSystem
        ComputerCPUInfo = $ComputerCPUInfo
        ComputerSystemInfo = $ComputerSystemInfo
    }
}