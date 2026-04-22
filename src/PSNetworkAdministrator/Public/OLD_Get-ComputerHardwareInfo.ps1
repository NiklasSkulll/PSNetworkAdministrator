function Get-ComputerHardwareInfo {
    <#
    .SYNOPSIS
        Retrieves CPU, system, and local storage information from a remote computer using CIM (WinRM first, then DCOM fallback).

    .DESCRIPTION
        The Get-ComputerHardwareInfo function queries remote hardware/system information via CIM/WMI classes.
        It attempts to create a CIM session over WinRM (WSMan) first and, if that fails, retries using DCOM.
        The function collects:
        - CPU information via Win32_Processor
        - System information via Win32_ComputerSystem
        - Local storage/volume information (drive letters) via Win32_LogicalDisk (DriveType=3)

        In addition to per-volume data (C:, D:, etc.), the function computes total local storage capacity, free space,
        and used space by summing the values across all fixed local volumes.

        If both WinRM and DCOM fail, the function returns partial results (if any) along with captured error message(s).
        Optionally, it writes warning logs only when the target is considered a server.
    
    .PARAMETER DNSHostName
        The DNS host name of the target computer (FQDN recommended). This value is used as the remote
        connection target for CIM sessions.
    
    .PARAMETER Credential
        A PSCredential object used to authenticate to the target computer for WinRM/DCOM CIM sessions.
        The credential must have sufficient permissions to query WMI/CIM classes on the remote system.

    .PARAMETER IsServerTrue
        Indicates whether the target computer should be treated as a server for logging purposes.
        If set to $true, warning logs are written when CPU/system information cannot be retrieved.
        If $false (or not provided), the function suppresses these warning logs to reduce noise for clients.
    
    .EXAMPLE
        $cred = Get-Credential
        Get-ComputerHardwareInfo -DNSHostName "server01.contoso.com" -Credential $cred -IsServerTrue $true

        Retrieves CPU, system, and local storage volume information from server01 using WinRM, falling back to DCOM if needed.
        Writes warning logs if the host cannot be queried.
    
    .EXAMPLE
        $cred = Get-Credential
        Get-ComputerHardwareInfo -DNSHostName "client42.contoso.com" -Credential $cred

        Retrieves CPU, system, and local storage volume information from client42. Suppresses warning logs by default.
    
    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        PSCustomObject
        Returns an object containing:
        - DNSHostName: Target DNS name used for the session
        - HardwareStatusCPU: Boolean indicating whether CPU information was retrieved
        - HardwareStatusSystem: Boolean indicating whether system information was retrieved
        - HardwareStatusStorage: Boolean indicating whether storage information was retrieved
        - StatusMessage: Text describing success/failure and (if applicable) WinRM/DCOM errors
        - ComputerCPUInfo: Object/array with CPU properties
        - ComputerSystemInfo: Object with system properties
        - ComputerStorageInfo: Array of local fixed volumes (DriveType=3)
        - TotalLocalStorageInfo: Object with totals across all volumes

        ComputerCPUInfo properties = Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
        ComputerSystemInfo properties = DomainRole, Manufacturer, Model, SystemType, TotalPhysicalMemoryGB, HypervisorPresent, UserName
        ComputerStorageInfo properties = DeviceID, VolumeName, FileSystem, SizeGB, FreeGB, UsedGB
        TotalLocalStorageInfo properties = TotalLocalStorageSizeGB, TotalLocalStorageFreeGB, TotalLocalStorageUsedGB
    
    .NOTES
        Author: Niklas Schneider
        Version: 1.0.0
        Requires: PowerShell 7.0+, CIM cmdlets (New-CimSession/Get-CimInstance), Write-AppLogging function

        Transport behavior:
        - WinRM/WSMan is attempted first.
        - If WinRM fails, DCOM is attempted as a fallback (Windows-to-Windows scenarios).
        - Success depends on network connectivity, firewall rules, authentication/trust relationships,
        and permissions to query WMI/CIM on the target.

        Classes queried:
        - Win32_Processor
        - Win32_ComputerSystem
        - Win32_LogicalDisk (DriveType=3)

        Notes on output:
        - Win32_Processor may return multiple instances on multi-socket systems; therefore ComputerCPUInfo can be an array.
        - TotalPhysicalMemoryGB is calculated from Win32_ComputerSystem.TotalPhysicalMemory (bytes).
        - Storage totals are computed by summing the per-volume values returned from Win32_LogicalDisk.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DNSHostName,

        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [bool]$IsServerTrue
    )
    # === check parameters ===
    $DNSHostNameIsNotEmpty = Test-FunctionVariables -Param $DNSHostName
    $CredentialIsNotEmpty = Test-FunctionVariables -Param $Credential
    if (-not $DNSHostNameIsNotEmpty -or -not $CredentialIsNotEmpty) {throw "DNSHostName/Credential is null/empty."}

    # === variables ===
    $ComputerCPUInfo = $null
    $ComputerSystemInfo = $null
    $ComputerStorageInfo = $null

    $WinRMError = $null
    $DCOMError = $null

    # === get hardware information over WinRM ===
    try {
        # CIM over WinRM
        $WinRMSession = $null

        $WinRMSession = New-CimSession -ComputerName $DNSHostName -Credential $Credential -ErrorAction Stop
        $ComputerCPUInfo = Get-CimInstance -CimSession $WinRMSession -ClassName Win32_Processor -ErrorAction Stop | Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
        $ComputerSystemInfo = Get-CimInstance -CimSession $WinRMSession -ClassName Win32_ComputerSystem -ErrorAction Stop | Select-Object DomainRole, Manufacturer, Model, SystemType, @{Name='TotalPhysicalMemoryGB'; Expression={[math]::Round($_.TotalPhysicalMemory/1GB, 2)}}, HypervisorPresent, UserName
        $ComputerStorageInfo = Get-CimInstance -CimSession $WinRMSession -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop | Select-Object DeviceID, VolumeName, FileSystem, @{n='SizeGB';e={[math]::Round($_.Size/1GB,2)}}, @{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,2)}}, @{n='UsedGB';e={[math]::Round(($_.Size-$_.FreeSpace)/1GB,2)}}

        # provide the full storage size aswell
        if ($ComputerStorageInfo) {
            $TotalLocalStorageSizeGB = [math]::Round(($ComputerStorageInfo | Measure-Object -Property SizeGB -Sum).Sum, 2)
            $TotalLocalStorageFreeGB = [math]::Round(($ComputerStorageInfo | Measure-Object -Property FreeGB -Sum).Sum, 2)
            $TotalLocalStorageUsedGB = [math]::Round(($ComputerStorageInfo | Measure-Object -Property UsedGB -Sum).Sum, 2)
        }
    }
    catch {
        # catch error message
        $WinRMError = "$($_.Exception.Message)"

        $ComputerCPUInfo = $null
        $ComputerSystemInfo = $null
        $ComputerStorageInfo = $null
    }
    finally {
        if ($WinRMSession) {Remove-CimSession $WinRMSession}
    }
    
    # === get hardware information over DCOM, if WinRM don't work ===
    if (-not $ComputerCPUInfo -or -not $ComputerSystemInfo -or -not $ComputerStorageInfo) {
        try {
            # CIM over DCOM
            $DCOMSession = $null

            $DCOMSessionOption = New-CimSessionOption -Protocol Dcom
            $DCOMSession = New-CimSession -ComputerName $DNSHostName -Credential $Credential -SessionOption $DCOMSessionOption -ErrorAction Stop
            $ComputerCPUInfo = Get-CimInstance -CimSession $DCOMSession -ClassName Win32_Processor -ErrorAction Stop | Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed
            $ComputerSystemInfo = Get-CimInstance -CimSession $DCOMSession -ClassName Win32_ComputerSystem -ErrorAction Stop | Select-Object DomainRole, Manufacturer, Model, SystemType, @{Name='TotalPhysicalMemoryGB'; Expression={[math]::Round($_.TotalPhysicalMemory/1GB, 2)}}, HypervisorPresent, UserName
            $ComputerStorageInfo = Get-CimInstance -CimSession $DCOMSession -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop | Select-Object DeviceID, VolumeName, FileSystem, @{n='SizeGB';e={[math]::Round($_.Size/1GB,2)}}, @{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,2)}}, @{n='UsedGB';e={[math]::Round(($_.Size-$_.FreeSpace)/1GB,2)}}

            # provide the full storage size aswell
            if ($ComputerStorageInfo) {
                $TotalLocalStorageSizeGB = [math]::Round(($ComputerStorageInfo | Measure-Object -Property SizeGB -Sum).Sum, 2)
                $TotalLocalStorageFreeGB = [math]::Round(($ComputerStorageInfo | Measure-Object -Property FreeGB -Sum).Sum, 2)
                $TotalLocalStorageUsedGB = [math]::Round(($ComputerStorageInfo | Measure-Object -Property UsedGB -Sum).Sum, 2)
            }
        }
        catch {
            # catch error message
            $DCOMError = "$($_.Exception.Message)"

            # set status with logging
            $HardwareStatusCPU = if (-not $ComputerCPUInfo) {
                if ($IsServerTrue) {Write-AppLogging -LoggingMessage "Couldn't get the CPU informations from '$DNSHostName'." -LoggingLevel "Warning"}
                $false
            }
            else {
                $true
            }

            $HardwareStatusSystem = if (-not $ComputerSystemInfo) {
                if ($IsServerTrue) {Write-AppLogging -LoggingMessage "Couldn't get the system informations from '$DNSHostName'." -LoggingLevel "Warning"}
                $false
            }
            else {
                $true
            }

            $HardwareStatusStorage = if (-not $ComputerStorageInfo) {
                if ($IsServerTrue) {Write-AppLogging -LoggingMessage "Couldn't get the storage informations from '$DNSHostName'." -LoggingLevel "Warning"}
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
                "Unknown errors occurred (WinRM and DCOM)."
            }

            return [PSCustomObject]@{
                DNSHostName = $DNSHostName
                HardwareStatusCPU = $HardwareStatusCPU
                HardwareStatusSystem = $HardwareStatusSystem
                HardwareStatusStorage = $HardwareStatusStorage
                StatusMessage = $StatusMessage
                ComputerCPUInfo = $ComputerCPUInfo
                ComputerSystemInfo = $ComputerSystemInfo
                ComputerStorageInfo = $ComputerStorageInfo
                TotalLocalStorageInfo = [PSCustomObject]@{
                    TotalLocalStorageSizeGB = $TotalLocalStorageSizeGB
                    TotalLocalStorageFreeGB = $TotalLocalStorageFreeGB
                    TotalLocalStorageUsedGB = $TotalLocalStorageUsedGB
                }
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
    $HardwareStatusStorage = if (-not $ComputerStorageInfo) {$false} else {$true}

    # === return PSCustomObject ===
    return [PSCustomObject]@{
        DNSHostName = $DNSHostName
        HardwareStatusCPU = $HardwareStatusCPU
        HardwareStatusSystem = $HardwareStatusSystem
        HardwareStatusStorage = $HardwareStatusStorage
        StatusMessage = $StatusMessage
        ComputerCPUInfo = $ComputerCPUInfo
        ComputerSystemInfo = $ComputerSystemInfo
        ComputerStorageInfo = $ComputerStorageInfo
        TotalLocalStorageInfo = [PSCustomObject]@{
            TotalLocalStorageSizeGB = $TotalLocalStorageSizeGB
            TotalLocalStorageFreeGB = $TotalLocalStorageFreeGB
            TotalLocalStorageUsedGB = $TotalLocalStorageUsedGB
        }
    }
}