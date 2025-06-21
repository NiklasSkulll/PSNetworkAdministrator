# Domain and connectivity functions for NetworkAdmin module

function Get-NetworkAdminDomainName {
    [CmdletBinding()]
    param()
    
    if (-not $script:CurrentDomain) {
        do {
            $domainInput = Read-Host "Please enter the domain name (e.g., company.local)"
            if ([string]::IsNullOrWhiteSpace($domainInput)) {
                Write-Host "Domain name cannot be empty. Please try again." -ForegroundColor Red
            } elseif (-not (Test-NetworkAdminValidInput -Input $domainInput -Type "Domain")) {
                Write-Host "Invalid domain format. Please enter a valid domain name (e.g., company.local)" -ForegroundColor Red
            } else {
                $script:CurrentDomain = $domainInput
                break
            }
        } while ($true)
    }
    
    Write-Host "Working with domain: $script:CurrentDomain" -ForegroundColor Green
    Write-Host ""
    return $script:CurrentDomain
}

# Enhanced network operations with timeout and fallback
function Invoke-NetworkAdminNetworkOperationWithTimeout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 10,
        [Parameter(Mandatory=$false)]
        [string]$OperationName = "Network Operation"
    )
    
    try {
        $job = Start-Job -ScriptBlock $Operation
        $result = $job | Wait-Job -Timeout $TimeoutSeconds | Receive-Job
        Remove-Job $job -Force
        
        if ($null -eq $result -and $job.State -eq "Running") {
            throw "Operation '$OperationName' timed out after $TimeoutSeconds seconds"
        }
        
        return $result
    }
    catch {
        Write-Error "Failed to execute $OperationName : $($_.Exception.Message)"
        return $null
    }
}

function Invoke-NetworkAdminNetworkOperationWithFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$PrimaryOperation,
        
        [Parameter(Mandatory=$false)]
        [scriptblock[]]$FallbackOperations = @(),
        
        [Parameter(Mandatory=$true)]
        [string]$OperationName
    )
    
    # Try primary operation first
    Write-Verbose "Attempting primary operation: $OperationName"
    try {
        $result = & $PrimaryOperation
        if ($null -ne $result) {
            Write-Verbose "Primary operation succeeded: $OperationName"
            return $result
        }
    }
    catch {
        Write-Verbose "Primary operation failed: $($_.Exception.Message)"
    }
    
    # Try fallback operations
    for ($i = 0; $i -lt $FallbackOperations.Count; $i++) {
        try {
            Write-Verbose "Attempting fallback operation $($i + 1) for: $OperationName"
            $result = & $FallbackOperations[$i]
            if ($null -ne $result) {
                Write-Verbose "Fallback operation $($i + 1) succeeded: $OperationName"
                return $result
            }
        }
        catch {
            Write-Verbose "Fallback operation $($i + 1) failed: $($_.Exception.Message)"
        }
    }
    
    Write-ConfigHost "✗ All attempts failed for $OperationName" -ColorType "Error"
    return $null
}

function Test-NetworkAdminPing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Target,
        
        [Parameter(Mandatory=$false)]
        [int]$Count = 4,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 10
    )
    
    $pingOperation = {
        $pingParams = @{
            ComputerName = $Target
            Count = $Count
            ErrorAction = 'Stop'
        }
        Test-Connection @pingParams
    }
    
    $result = Invoke-NetworkAdminNetworkOperationWithTimeout -Operation $pingOperation -TimeoutSeconds $TimeoutSeconds -OperationName "Ping Test to $Target"
    
    return $result
}

function Test-NetworkAdminPortConnectivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Target,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 10
    )
    
    $portTestOperation = {
        Test-NetConnection -ComputerName $Target -Port $Port -WarningAction SilentlyContinue -ErrorAction Stop
    }
    
    $result = Invoke-NetworkAdminNetworkOperationWithTimeout -Operation $portTestOperation -TimeoutSeconds $TimeoutSeconds -OperationName "Port Test to $Target`:$Port"
    
    return $result
}

function Test-NetworkAdminDomainConnectivity {
    [CmdletBinding()]
    param()
    
    Write-Host "Testing connectivity to domain: $script:CurrentDomain" -ForegroundColor Yellow
    Show-NetworkAdminProgress -Activity "Domain Connectivity" -Status "Testing connection..."
    
    try {
        $params = @{
            Domain = $script:CurrentDomain
            ErrorAction = 'Stop'
        }
        if ($script:CurrentCredential) {
            $params.Credential = $script:CurrentCredential
        }
        
        $domainController = (Get-ADDomainController @params).HostName
        Write-ConfigHost "✓ Successfully connected to domain controller: $domainController" -ColorType "Success"
        Write-NetworkAdminAuditLog -Action "Domain Connection Test" -Target $script:CurrentDomain -Result "Success" -Details "DC: $domainController"
        Write-Progress -Activity "Domain Connectivity" -Completed
        return $true
    }
    catch {
        Write-ConfigHost "✗ Unable to connect to domain: $($_.Exception.Message)" -ColorType "Error"
        Write-NetworkAdminAuditLog -Action "Domain Connection Test" -Target $script:CurrentDomain -Result "Failed" -Details $_.Exception.Message
        Write-Progress -Activity "Domain Connectivity" -Completed
        return $false
    }
}

function Test-NetworkAdminConnectivity {
    <#
    .SYNOPSIS
        Tests network connectivity to various targets
    
    .DESCRIPTION
        Comprehensive network connectivity testing function
    
    .PARAMETER Target
        The target to test (hostname, IP, domain)
    
    .PARAMETER Type
        Type of connectivity test (Ping, Port, Domain)
    
    .PARAMETER Port
        Port number for port connectivity tests
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Ping", "Port", "Domain")]
        [string]$Type = "Ping",
        
        [Parameter(Mandatory = $false)]
        [int]$Port = 0
    )
    
    switch ($Type) {
        "Ping" {
            try {
                $config = Get-NetworkAdminConfig
                $result = Test-Connection -ComputerName $Target -Count $config.PingCount -Quiet
                return $result
            }
            catch {
                Write-Verbose "Ping test failed: $($_.Exception.Message)"
                return $false
            }
        }
        "Port" {
            if ($Port -le 0) {
                throw "Port number must be specified for port connectivity tests"
            }
            try {
                $result = Test-NetConnection -ComputerName $Target -Port $Port -WarningAction SilentlyContinue
                return $result.TcpTestSucceeded
            }
            catch {
                Write-Verbose "Port test failed: $($_.Exception.Message)"
                return $false
            }
        }
        "Domain" {
            try {
                $params = @{
                    Domain = $Target
                    ErrorAction = 'Stop'
                }
                if ($script:CurrentCredential) {
                    $params.Credential = $script:CurrentCredential
                }
                Get-ADDomainController @params | Out-Null
                return $true
            }
            catch {
                Write-Verbose "Domain connectivity test failed: $($_.Exception.Message)"
                return $false
            }
        }
    }
}

function Invoke-ConfigurableOperation {
    <#
    .SYNOPSIS
    Executes operations with configurable parallel processing

    .DESCRIPTION
    Runs operations either in parallel or sequentially based on configuration

    .PARAMETER Operations
    Array of script blocks to execute

    .PARAMETER OperationName
    Name of the operation for logging

    .PARAMETER ThrottleLimit
    Maximum number of concurrent operations

    .EXAMPLE
    Invoke-ConfigurableOperation -Operations @($op1, $op2) -OperationName "UserQueries"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock[]]$Operations,
        [Parameter(Mandatory=$false)]
        [string]$OperationName = "Operation",
        [Parameter(Mandatory=$false)]
        [int]$ThrottleLimit = 5
    )
    
    $config = Get-NetworkAdminConfig
    
    if ($config.Performance.UseParallelProcessing -and $Operations.Count -gt 1) {
        Write-Verbose "Using parallel processing for $OperationName with throttle limit $ThrottleLimit"
        
        $jobs = @()
        foreach ($operation in $Operations) {
            $jobs += Start-Job -ScriptBlock $operation
            
            # Throttle job creation
            while ((Get-Job -State Running).Count -ge $ThrottleLimit) {
                Start-Sleep -Milliseconds 100
            }
        }
        
        # Wait for all jobs to complete and collect results
        $results = @()
        foreach ($job in $jobs) {
            $results += $job | Wait-Job | Receive-Job
            Remove-Job $job -Force
        }
        
        return $results
    } else {
        # Sequential processing
        Write-Verbose "Using sequential processing for $OperationName"
        $results = @()
        foreach ($operation in $Operations) {
            $results += & $operation
        }
        return $results
    }
}

function Invoke-NetworkOperationWithFallback {
    <#
    .SYNOPSIS
    Executes network operations with fallback support

    .DESCRIPTION
    Attempts a primary operation and falls back to alternative methods if it fails

    .PARAMETER PrimaryOperation
    The primary operation to attempt

    .PARAMETER FallbackOperations
    Array of fallback operations to try

    .PARAMETER OperationName
    Name of the operation for logging

    .PARAMETER TimeoutSeconds
    Timeout for each operation attempt

    .EXAMPLE
    Invoke-NetworkOperationWithFallback -PrimaryOperation $primaryOp -FallbackOperations @($fallback1, $fallback2)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$PrimaryOperation,
        [Parameter(Mandatory=$false)]
        [scriptblock[]]$FallbackOperations = @(),
        [Parameter(Mandatory=$false)]
        [string]$OperationName = "Network Operation",
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 10
    )
    
    # Try primary operation first
    Write-Verbose "Attempting primary operation: $OperationName"
    try {
        $result = Invoke-NetworkAdminNetworkOperationWithTimeout -Operation $PrimaryOperation -TimeoutSeconds $TimeoutSeconds -OperationName $OperationName
        if ($null -ne $result) {
            return $result
        }
    }
    catch {
        Write-Verbose "Primary operation failed: $($_.Exception.Message)"
    }
    
    # Try fallback operations
    for ($i = 0; $i -lt $FallbackOperations.Count; $i++) {
        Write-Verbose "Attempting fallback operation $(i + 1) for: $OperationName"
        try {
            $result = Invoke-NetworkAdminNetworkOperationWithTimeout -Operation $FallbackOperations[$i] -TimeoutSeconds $TimeoutSeconds -OperationName "$OperationName (Fallback $(i + 1))"
            if ($null -ne $result) {
                Write-ConfigHost "✓ $OperationName succeeded using fallback method $(i + 1)" -ColorType "Warning"
                return $result
            }
        }
        catch {
            Write-Verbose "Fallback operation $(i + 1) failed: $($_.Exception.Message)"
        }
    }
    
    Write-ConfigHost "✗ All attempts failed for $OperationName" -ColorType "Error"
    return $null
}

function Get-AvailableDomainControllers {
    <#
    .SYNOPSIS
    Gets a list of available domain controllers

    .DESCRIPTION
    Discovers and tests connectivity to domain controllers, returning those that are responsive

    .PARAMETER Domain
    The domain to query for domain controllers

    .EXAMPLE
    Get-AvailableDomainControllers -Domain "company.local"
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$Domain = $script:Domain
    )
    
    try {
        $domainControllers = @()
        
        # Try to get all domain controllers
        $allDCs = Get-ADDomainController -Filter * -Server $Domain -ErrorAction SilentlyContinue
        
        if ($allDCs) {
            # Test connectivity to each DC and prioritize by response time
            foreach ($dc in $allDCs) {
                try {
                    $pingResult = Test-Connection -ComputerName $dc.HostName -Count 1 -Quiet -ErrorAction SilentlyContinue
                    if ($pingResult) {
                        $domainControllers += @{
                            HostName = $dc.HostName
                            Name = $dc.Name
                            Site = $dc.Site
                            IsResponding = $true
                        }
                    }
                }
                catch {
                    Write-Verbose "DC $($dc.HostName) is not responding"
                }
            }
        }
        
        # If no DCs found through AD, try DNS resolution
        if ($domainControllers.Count -eq 0) {
            try {
                $dnsResults = Resolve-DnsName -Name "_ldap._tcp.$Domain" -Type SRV -ErrorAction SilentlyContinue
                foreach ($result in $dnsResults) {
                    if ($result.Type -eq "SRV") {
                        $domainControllers += @{
                            HostName = $result.NameTarget
                            Name = $result.NameTarget
                            Site = "Unknown"
                            IsResponding = $true
                        }
                    }
                }
            }
            catch {
                Write-Verbose "DNS SRV lookup failed for domain $Domain"
            }
        }
        
        return $domainControllers
    }
    catch {
        Write-Verbose "Failed to get domain controllers: $($_.Exception.Message)"
        return @()
    }
}
