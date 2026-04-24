function Get-ComputerSystem {
    <#

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DomainName,

        [Parameter(Mandatory)]
        [string]$ComputerName,
    
        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [string]$DNSHostName,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )
    
    # ===== Check the function variables =====
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language
    $ComputerNameCheck = Test-FunctionVariables -Param $ComputerName -ParamName '$ComputerName' -Language $Language
    $CredentialCheck = Test-FunctionVariables -Param $Credential -ParamName '$Credential' -Language $Language
    $DNSHostNameCheck = Test-FunctionVariables -Param $DNSHostName -ParamName '$DNSHostName' -Language $Language

    if (-not ($DomainNameCheck.Success) -or -not ($ComputerNameCheck.Success) -or -not ($CredentialCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DomainNameCheck.Success)) {$ErrorMessages += $DomainNameCheck.Message}
        if (-not ($ComputerNameCheck.Success)) {$ErrorMessages += $ComputerNameCheck.Message}
        if (-not ($CredentialCheck.Success)) {$ErrorMessages += $CredentialCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }

    # ===== Get current date and time =====
    $ObservationDate = Get-Date -Format "yyyy-MM-dd,HH:mm:ss"

    # ===== Get computer system informations =====
    try {
        # Create $ConnectionTarget
        $ConnectionTarget = if ($DNSHostNameCheck.Success) {$DNSHostName} else {"$ComputerName.$DomainName"}

        # Create CimSession on $ConnectionTarget
        $CimSession = $null
        $CimSession = New-CimSession -ComputerName $ConnectionTarget -Credential $Credential -ErrorAction Stop

        # Get computer system informations
        try {
            $ComputerSystemInfo = Get-CimInstance -CimSession $CimSession -ClassName Win32_ComputerSystem -ErrorAction Stop | Select-Object Manufacturer, Model, SystemType, @{Name='TotalPhysicalMemoryGB'; Expression={[math]::Round($_.TotalPhysicalMemory/1GB, 2)}}

            $ComputerSystemManufacturer = $ComputerSystemInfo.Manufacturer
            $ComputerSystemModel = $ComputerSystemInfo.Model
            $ComputerSystemType = $ComputerSystemInfo.SystemType
            $TotalPhysicalMemoryGB = $ComputerSystemInfo.TotalPhysicalMemoryGB
        }
        catch {
            $ComputerSystemManufacturer = $null
            $ComputerSystemModel = $null
            $ComputerSystemType = $null
            $TotalPhysicalMemoryGB = $null
        }

        # Get BIOS informations
        try {
            $ComputerBIOSInfo = Get-CimInstance -CimSession $CimSession -ClassName Win32_BIOS -ErrorAction Stop | Select-Object SerialNumber, Manufacturer, SMBIOSBIOSVersion

            $BIOSManufacturer = $ComputerBIOSInfo.Manufacturer
            $BIOSSerialNumber = $ComputerBIOSInfo.SerialNumber
            $SMBIOSVersion = $ComputerBIOSInfo.SMBIOSBIOSVersion
        }
        catch {
            $BIOSManufacturer = $null
            $BIOSSerialNumber = $null
            $SMBIOSVersion = $null
        }

        # Get CPU informations
        try {
            $ComputerCPUInfo = Get-CimInstance -CimSession $CimSession -ClassName Win32_Processor -ErrorAction Stop | Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed

            $CPUGenerationName = @($ComputerCPUInfo.Name | Where-Object {$_}) | ConvertTo-Json -Compress -AsArray
            $CPUTotalNumberOfCores = ($ComputerCPUInfo | Measure-Object -Property NumberOfCores -Sum).Sum
            $CPUTotalNumberOfLogicalProcessors = ($ComputerCPUInfo | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
        }
        catch {
            $CPUGenerationName = $null
            $CPUTotalNumberOfCores = $null
            $CPUTotalNumberOfLogicalProcessors = $null
        }

        # Get storage informations
        try {
            $ComputerStorageInfo = Get-CimInstance -CimSession $CimSession -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop | Select-Object DeviceID, VolumeName, @{Name='SizeGB'; Expression={[math]::Round($_.Size/1GB,2)}}, @{Name='FreeGB'; Expression={[math]::Round($_.FreeSpace/1GB,2)}}, @{Name='UsedGB'; Expression={[math]::Round(($_.Size-$_.FreeSpace)/1GB,2)}}

            if ($ComputerStorageInfo) {
                $TotalLocalStorageSizeGB = [math]::Round(($ComputerStorageInfo | Measure-Object -Property SizeGB -Sum).Sum, 2)
                $TotalLocalStorageFreeGB = [math]::Round(($ComputerStorageInfo | Measure-Object -Property FreeGB -Sum).Sum, 2)
                $TotalLocalStorageUsedGB = [math]::Round(($ComputerStorageInfo | Measure-Object -Property UsedGB -Sum).Sum, 2)
            }
            else {
                $TotalLocalStorageSizeGB = $null
                $TotalLocalStorageFreeGB = $null
                $TotalLocalStorageUsedGB = $null
            }
        }
        catch {
            $TotalLocalStorageSizeGB = $null
            $TotalLocalStorageFreeGB = $null
            $TotalLocalStorageUsedGB = $null
        }

        # Return computer system informations
        return [pscustomobject]@{
            ComputerName = $ComputerName
            DomainName = $DomainName
            ComputerSystemManufacturer = $ComputerSystemManufacturer
            ComputerSystemModel = $ComputerSystemModel
            ComputerSystemType = $ComputerSystemType
            BIOSManufacturer = $BIOSManufacturer
            BIOSSerialNumber = $BIOSSerialNumber
            SMBIOSVersion = $SMBIOSVersion
            CPUGenerationName = $CPUGenerationName
            CPUTotalNumberOfCores = $CPUTotalNumberOfCores
            CPUTotalNumberOfLogicalProcessors = $CPUTotalNumberOfLogicalProcessors
            TotalPhysicalMemoryGB = $TotalPhysicalMemoryGB
            TotalLocalStorageSizeGB = $TotalLocalStorageSizeGB
            TotalLocalStorageFreeGB = $TotalLocalStorageFreeGB
            TotalLocalStorageUsedGB = $TotalLocalStorageUsedGB
            ObservationDate = $ObservationDate
        }
    }
    catch {
        # Return $null if connection failed
        return [pscustomobject]@{
            ComputerName = $ComputerName
            DomainName = $DomainName
            ComputerSystemManufacturer = $null
            ComputerSystemModel = $null
            ComputerSystemType = $null
            BIOSManufacturer = $null
            BIOSSerialNumber = $null
            SMBIOSVersion = $null
            CPUGenerationName = $null
            CPUTotalNumberOfCores = $null
            CPUTotalNumberOfLogicalProcessors = $null
            TotalPhysicalMemoryGB = $null
            TotalLocalStorageSizeGB = $null
            TotalLocalStorageFreeGB = $null
            TotalLocalStorageUsedGB = $null
            ObservationDate = $ObservationDate
        }
    }
    finally {
        if ($CimSession) {Remove-CimSession $CimSession}
    }
}