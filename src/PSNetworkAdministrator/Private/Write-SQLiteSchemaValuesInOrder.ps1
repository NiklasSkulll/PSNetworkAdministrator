function Write-SQLiteSchemaValuesInOrder {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$DataObject,

        [Parameter(Mandatory)]
        [string[]]$AllColumnNamesWithoutID,

        [string]$DomainName
    )

    # === check input ===
    $DataObjectIsNotEmpty = Test-FunctionVariables -Param $DataObject
    $AllColumnNamesWithoutIDIsNotEmpty = Test-FunctionVariables -Param $AllColumnNamesWithoutID
    if (-not $DataObjectIsNotEmpty -or -not $AllColumnNamesWithoutIDIsNotEmpty) {throw "Data object/AllColumnNamesWithoutID is null/empty."}
    if ($AllColumnNamesWithoutID -contains 'DomainName' -and [string]::IsNullOrWhiteSpace($DomainName)) {throw "Domain name for this table is empty/null/whitespace."}

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