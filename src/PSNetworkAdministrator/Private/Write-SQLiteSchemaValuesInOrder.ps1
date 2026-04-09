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

    # === check input ===
    $DataObjectCheck = Test-FunctionVariables -Param $DataObject -ParamName '$DataObject' -Language $Language
    $AllColumnNamesWithoutIDCheck = Test-FunctionVariables -Param $AllColumnNamesWithoutID -ParamName '$AllColumnNamesWithoutID' -Language $Language
    $DomainNameCheck = Test-FunctionVariables -Param $DomainName -ParamName '$DomainName' -Language $Language

    if (-not ($DataObjectCheck.Success) -or -not ($AllColumnNamesWithoutIDCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($DataObjectCheck.Success)) {$ErrorMessages += $DataObjectCheck.Message}
        if (-not ($AllColumnNamesWithoutIDCheck.Success)) {$ErrorMessages += $AllColumnNamesWithoutIDCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join ' || '

        throw $ErrorMessage
    }
    
    if ($AllColumnNamesWithoutID -contains 'DomainName' -and -not ($DomainNameCheck.Success)) {
        throw "$($DomainNameCheck.Message)"
    }

    # === order the values of the $DataObject ===
    $DataValuesInOrder = foreach ($DataColumn in $AllColumnNamesWithoutID) {
        # add domain name
        if ($DataColumn -eq 'DomainName') {$DomainName}
        # handle specific values of "_DomainComputers_"
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
        # handle standard values
        else {$DataObject.$DataColumn}
    }

    # === return ordered values ===
    return $DataValuesInOrder
}