# Active Directory operations for NetworkAdmin module

function Invoke-NetworkAdminADQueryWithPaging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Filter,
        [Parameter(Mandatory=$false)]
        [string[]]$Properties = @(),
        [Parameter(Mandatory=$false)]
        [string]$SearchBase = "",
        [Parameter(Mandatory=$false)]
        [ValidateSet("User", "Computer", "Group")]
        [string]$ObjectType = "User",
        [Parameter(Mandatory=$false)]
        [int]$PageSize = 1000,
        [Parameter(Mandatory=$false)]
        [int]$MaxResults = 0
    )
    
    $config = Get-NetworkAdminConfig
    
    try {
        $params = @{
            Filter = $Filter
            Server = $script:CurrentDomain
            ResultPageSize = if ($PageSize -gt 0) { $PageSize } else { $config.PageSize }
            ErrorAction = 'Stop'
        }
        
        if ($Properties.Count -gt 0) {
            $params.Properties = $Properties
        }
        
        if (-not [string]::IsNullOrEmpty($SearchBase)) {
            $params.SearchBase = $SearchBase
        }
        
        if ($script:CurrentCredential) {
            $params.Credential = $script:CurrentCredential
        }
        
        # Add timeout using job
        $job = Start-Job -ScriptBlock {
            param($ObjectType, $params)
            switch ($ObjectType) {
                "User" { Get-ADUser @params }
                "Computer" { Get-ADComputer @params }
                "Group" { Get-ADGroup @params }
            }
        } -ArgumentList $ObjectType, $params
        
        $result = $job | Wait-Job -Timeout $config.ADQueryTimeout | Receive-Job
        Remove-Job $job -Force
        
        if ($null -eq $result) {
            throw "AD query timed out after $($config.ADQueryTimeout) seconds"
        }
        
        $totalCount = ($result | Measure-Object).Count
        $isTruncated = $MaxResults -gt 0 -and $totalCount -ge $MaxResults
        
        if ($MaxResults -gt 0 -and $totalCount -gt $MaxResults) {
            $result = $result | Select-Object -First $MaxResults
        }
        
        return [ADQueryResult]::new($result, $totalCount, $isTruncated)
    }
    catch {
        $errorResult = [ADQueryResult]::new(@(), 0, $false)
        $errorResult.ErrorMessage = $_.Exception.Message
        return $errorResult
    }
}

function Invoke-NetworkAdminADOperationWithFailover {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,
        
        [Parameter(Mandatory=$true)]
        [string]$OperationName
    )
    
    $domainControllers = Get-NetworkAdminAvailableDomainControllers
    
    if ($domainControllers.Count -eq 0) {
        Write-ConfigHost "✗ No domain controllers available for $OperationName" -ColorType "Error"
        return $null
    }
    
    foreach ($dc in $domainControllers) {
        try {
            Write-Verbose "Attempting $OperationName against domain controller: $($dc.HostName)"
            $script:CurrentDomain = $dc.HostName
            $result = & $Operation
            Write-Verbose "$OperationName successful against $($dc.HostName)"
            return $result
        }
        catch {
            Write-Verbose "$OperationName failed against $($dc.HostName): $($_.Exception.Message)"
            continue
        }
    }
    
    Write-ConfigHost "✗ $OperationName failed against all available domain controllers" -ColorType "Error"
    return $null
}

function Get-NetworkAdminAvailableDomainControllers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$DomainName = $script:CurrentDomain
    )
    
    try {
        $params = @{
            Filter = "*"
            Server = $DomainName
            ErrorAction = 'Stop'
        }
        
        if ($script:CurrentCredential) {
            $params.Credential = $script:CurrentCredential
        }
        
        $domainControllers = Get-ADDomainController @params
        
        # Test connectivity to each DC and return only responsive ones
        $availableDCs = @()
        foreach ($dc in $domainControllers) {
            if (Test-NetworkAdminConnectivity -Target $dc.HostName -Type "Ping") {
                $availableDCs += $dc
            }
        }
        
        return $availableDCs
    }
    catch {
        Write-Verbose "Failed to get domain controllers: $($_.Exception.Message)"
        
        # Fallback: Try to use the current domain as a single DC
        try {
            $fallbackDC = [PSCustomObject]@{
                HostName = $DomainName
                Name = $DomainName
                Domain = $DomainName
            }
            
            if (Test-NetworkAdminConnectivity -Target $DomainName -Type "Domain") {
                return @($fallbackDC)
            }
        }
        catch {
            Write-Verbose "Fallback domain controller test failed: $($_.Exception.Message)"
        }
        
        return @()
    }
}

function Invoke-ADOperationWithFailover {
    <#
    .SYNOPSIS
    Executes AD operations with domain controller failover

    .DESCRIPTION
    Attempts an AD operation against multiple domain controllers if one fails

    .PARAMETER Operation
    The AD operation to execute

    .PARAMETER OperationName
    Name of the operation for logging

    .PARAMETER MaxRetries
    Maximum number of retries per domain controller

    .EXAMPLE    Invoke-ADOperationWithFailover -Operation { Get-ADUser -Identity "testuser" } -OperationName "Get User"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$Operation,
        [Parameter(Mandatory=$false)]
        [string]$OperationName = "AD Operation",
        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3
    )
    
    $domainControllers = Get-NetworkAdminAvailableDomainControllers
    
    if ($domainControllers.Count -eq 0) {
        Write-ConfigHost "✗ No available domain controllers found for $OperationName" -ColorType "Error"
        return $null
    }
    
    foreach ($dc in $domainControllers) {
        Write-Verbose "Attempting $OperationName against DC: $($dc.HostName)"
        
        try {
            # Modify the operation to use this specific DC
            $dcOperation = {
                $originalServer = $script:Domain
                $script:Domain = $dc.HostName
                try {
                    return & $Operation
                }
                finally {
                    $script:Domain = $originalServer
                }
            }
            
            $result = & $dcOperation
            
            if ($null -ne $result) {
                if ($dc.HostName -ne $script:Domain) {
                    Write-ConfigHost "✓ $OperationName succeeded using DC: $($dc.HostName)" -ColorType "Warning"
                }
                return $result
            }
        }
        catch {
            Write-Verbose "$OperationName failed against DC $($dc.HostName): $($_.Exception.Message)"
            continue
        }
    }
    
    Write-ConfigHost "✗ $OperationName failed against all available domain controllers" -ColorType "Error"
    return $null
}
