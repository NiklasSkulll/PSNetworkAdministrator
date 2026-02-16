function Get-ComputerHardwareInfo {
    <#
    
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DNSHostName,

        [Parameter(Mandatory)]
        [PSCredential]$Credential
    )

    # === variables ===
    $ComputerCPUInfo = $null
    $ComputerSystemInfo = $null

    $WinRMError = $null
    $DCOMError = $null

    # === get hardware information over WinRM ===
    try {
        # CIM over WinRM
        $WinRMSession = $null

        $WinRMSession = New-CimSession -ComputerName $DNSHostName -Credential $Credential -ErrorAction Stop
        $ComputerCPUInfo = Get-CimInstance -CimSession $WinRMSession -ClassName Win32_Processor -ErrorAction Stop | Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
        $ComputerSystemInfo = Get-CimInstance -CimSession $WinRMSession -ClassName Win32_ComputerSystem -ErrorAction Stop | Select-Object DomainRole, Manufacturer, Model, SystemType, @{Name='TotalPhysicalMemoryGB'; Expression={[math]::Round($_.TotalPhysicalMemory/1GB, 2)}}, HypervisorPresent, UserName
    }
    catch {
        # catch error message
        $WinRMError = "$($_.Exception.Message)"

        $ComputerCPUInfo = $null
        $ComputerSystemInfo = $null
    }
    finally {
        if ($WinRMSession) {Remove-CimSession $WinRMSession}
    }
    
    # === get hardware information over DCOM, if WinRM don't work ===
    if (-not $ComputerCPUInfo -or -not $ComputerSystemInfo) {
        try {
            # CIM over DCOM
            $DCOMSession = $null

            $DCOMSessionOption = New-CimSessionOption -Protocol Dcom
            $DCOMSession = New-CimSession -ComputerName $DNSHostName -Credential $Credential -SessionOption $DCOMSessionOption -ErrorAction Stop
            $ComputerCPUInfo = Get-CimInstance -CimSession $DCOMSession -ClassName Win32_Processor -ErrorAction Stop | Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
            $ComputerSystemInfo = Get-CimInstance -CimSession $DCOMSession -ClassName Win32_ComputerSystem -ErrorAction Stop | Select-Object DomainRole, Manufacturer, Model, SystemType, @{Name='TotalPhysicalMemoryGB'; Expression={[math]::Round($_.TotalPhysicalMemory/1GB, 2)}}, HypervisorPresent, UserName
        }
        catch {
            # catch error message
            $DCOMError = "$($_.Exception.Message)"

            # set status with logging
            $HardwareStatusCPU = if (-not $ComputerCPUInfo) {
                Write-AppLogging -LoggingMessage "Couldn't get the CPU informations from '$DNSHostName'." -LoggingLevel "Warning"
                $false
            }
            else {
                $true
            }

            $HardwareStatusSystem = if (-not $ComputerSystemInfo) {
                Write-AppLogging -LoggingMessage "Couldn't get the system informations from '$DNSHostName'." -LoggingLevel "Warning"
                $false
            }
            else {
                $true
            }

            # set $StatusMessage (error message)
            $StatusMessage = if ($WinRMError -and $DCOMError) {
                "Both failed. WinRM: $WinRMError; DCOM: $DCOMError"
            }
            elseif ($WinRMError) {
                "Both failed. WinRM failed: $WinRMError; DCOM: Unknown error"
            }
            elseif ($DCOMError) {
                "Both failed. WinRM failed: Unknown error; DCOM: $DCOMError"
            }
            else {
                "Unknown error occurred."
            }

            return [PSCustomObject]@{
                DNSHostName = $DNSHostName
                HardwareStatusCPU = $HardwareStatusCPU
                HardwareStatusSystem = $HardwareStatusSystem
                StatusMessage = $StatusMessage
                ComputerCPUInfo = $ComputerCPUInfo
                ComputerSystemInfo = $ComputerSystemInfo
            }
        }
        finally {
            if ($DCOMSession) {Remove-CimSession $DCOMSession}
        }
    }

    # === set $StatusMessage (error message) ===
    $StatusMessage = if ($WinRMError -and $DCOMError) {
        "Both failed. WinRM: $WinRMError; DCOM: $DCOMError"
    }
    elseif ($WinRMError) {
        "DCOM succeeded. WinRM failed: $WinRMError"
    }
    elseif ($DCOMError) {
        "WinRM succeeded. DCOM failed: $DCOMError"
    }
    else {
        "WinRM succeeded."
    }

    # === set status ===
    $HardwareStatusCPU = if (-not $ComputerCPUInfo) {$false} else {$true}
    $HardwareStatusSystem = if (-not $ComputerSystemInfo) {$false} else {$true}

    # === return PSCustomObject ===
    return [PSCustomObject]@{
        DNSHostName = $DNSHostName
        HardwareStatusCPU = $HardwareStatusCPU
        HardwareStatusSystem = $HardwareStatusSystem
        StatusMessage = $StatusMessage
        ComputerCPUInfo = $ComputerCPUInfo
        ComputerSystemInfo = $ComputerSystemInfo
    }
}