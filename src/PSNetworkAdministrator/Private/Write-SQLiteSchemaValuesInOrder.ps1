function Write-SQLiteSchemaValuesInOrder {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$DataObject,

        [Parameter(Mandatory)]
        [string[]]$AllColumnNamesWithoutID,

        [string]$DomainName,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== Check the function variables =====
    $DataObjectCheck = Test-FunctionVariables -Param $DataObject -ParamName '$DataObject' -Language $Language
    $AllColumnNamesWithoutIDCheck = Test-FunctionVariables -Param $AllColumnNamesWithoutID -ParamName '$AllColumnNamesWithoutID' -Language $Language
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language

    if (-not ($DataObjectCheck.Success) -or -not ($AllColumnNamesWithoutIDCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DataObjectCheck.Success)) {$ErrorMessages += $DataObjectCheck.Message}
        if (-not ($AllColumnNamesWithoutIDCheck.Success)) {$ErrorMessages += $AllColumnNamesWithoutIDCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }
    
    if ($AllColumnNamesWithoutID -contains 'DomainName' -and -not ($DomainNameCheck.Success)) {throw "$($DomainNameCheck.Message)"}

    # ===== Write values of $DataObject in order =====
    $DataValuesInOrder = foreach ($DataColumn in $AllColumnNamesWithoutID) {
        # Add domain name
        if ($DataColumn -eq 'DomainName') {
            $DomainName
        }
        # Handle specific values of "_DomainComputers_"
        elseif ($DataColumn -eq 'Enabled'){
            $DataEnabled = $DataObject.Enabled
            if ($null -eq $DataEnabled) {$null}
            else {[int]$DataEnabled}
        }
        elseif ($DataColumn -eq 'MemberOf') {
            $DataMemberOf = $DataObject.MemberOf
            if ($null -eq $DataMemberOf) {$null}
            else {@($DataMemberOf) | ConvertTo-Json -Compress}
        }
        # Handle standard values
        else {
            $DataObject.$DataColumn
        }
    }

    # ===== Return ordered values =====
    return $DataValuesInOrder
}