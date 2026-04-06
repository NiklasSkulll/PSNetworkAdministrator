function Get-ErrorMessages {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorCode,

        [string]$ExceptionMessage,

        [string]$DomainName,
        [string]$ComputerName,
        [string]$VariableName,

        $VariableValue,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )
    
    # ===== check if ErrorCode is NULL/whitespace =====
    if ([string]::IsNullOrWhiteSpace($ErrorCode)) {
        if ($Language -eq "de") {$ErrorCode = 'ErrorCode-NULL/Leerzeichen'} else {$ErrorCode = 'ErrorCode-NULL/whitespace'}
    }

    # ===== mapping: ErrorCode to error message (en, de) =====
    $ErrorMessagesEN = @{
        'COx0000001' = 'DNS not resolvable' # CO = connection
        'COx0000002' = 'WSMan/WinRM not reachable'
        'COx0000003' = 'TCP Connection failed'
        'COx0000004' = 'IPv4-Ping without response'
        'COx0000005' = 'CimSession failed'
        'FPx0000001' = 'Missing file' # FP = file path
        'FPx0000002' = 'Failed loading file'
        'FPx0000003' = 'Failed to write into file'
        'INx0000001' = 'Failed to get domain informations' # IN = information
        'INx0000002' = 'Failed to get computer informations'
        'RMx0000001' = 'Administrator rights are required' # RM = rights management
        'VAx0000001' = 'Variable is NULL' # VA = variable
        'VAx0000002' = 'Variable is NULL/whitespace'
        'VAx0000003' = 'Variable length is 0'
        'VAx0000004' = 'Variable length must be 16, 24, or 32'
        'VAx0000005' = 'Variable has 0 elements'
        'VAx0000006' = 'Unknown variable name'
    }

    $ErrorMessagesDE = @{
        'COx0000001' = 'DNS kann nicht aufgelöst werden' # CO = connection
        'COx0000002' = 'WSMan/WinRM nicht erreichbar'
        'COx0000003' = 'TCP-Verbindung ist fehlgeschlagen'
        'COx0000004' = 'IPv4-Ping ohne Antwort'
        'COx0000005' = 'Cim-Sitzung ist fehlgeschlagen'
        'FPx0000001' = 'Fehlende Datei' # FP = file path
        'FPx0000002' = 'Datei konnte nicht geladen werden'
        'FPx0000003' = 'Es konnte nicht in die Datei geschrieben werden'
        'INx0000001' = 'Domaininformationen konnten nicht abgerufen werden' # IN = information
        'INx0000002' = 'Computerinformationen konnten nicht abgerufen werden'
        'RMx0000001' = 'Administratorrechte werde benötigt' # RM = rights management
        'VAx0000001' = 'Variable ist NULL' # VA = variable
        'VAx0000002' = 'Variable ist NULL/besteht aus Leerzeichen'
        'VAx0000003' = 'Variable hat eine Zeichenlänge von 0'
        'VAx0000004' = 'Variable muss eine Zeichenlänge von 16, 24, oder 32 haben'
        'VAx0000005' = 'Variable hat 0 Elemente'
        'VAx0000006' = 'Unbekannter Variablenname'
    }

    # ===== creating a reference value for the error message =====
    $RefValues = @()
    
    if ($DomainName -or $ComputerName -or $VariableName -or $VariableValue) {
        $RefValueComAndVar = if ($ComputerName -and $VariableName) {"$ComputerName-$VariableName"} else {$null}

        if ($DomainName) {$RefValues += $DomainName}
        if ($RefValueComAndVar) {$RefValues += $RefValueComAndVar}
        if ($VariableValue) {$RefValues += $VariableValue}
        if (-not $RefValueComAndVar) {
            if ($ComputerName) {$RefValues += $ComputerName}
            if ($VariableName) {$RefValues += $VariableName}
        }
    }

    $RefValuesJoin = $RefValues -join '|'
    $RefValue = "|$RefValuesJoin|"

    # ===== get the correct error message from the ErrorCode =====
    $AppErrorMessage = if ($Language -eq "de") {
        if ($ErrorMessagesDE.ContainsKey($ErrorCode)) {$ErrorMessagesDE[$ErrorCode]} else {$null}
    }
    else {
        if ($ErrorMessagesEN.ContainsKey($ErrorCode)) {$ErrorMessagesEN[$ErrorCode]} else {$null}
    }

    # ===== check if AppErrorMessage is NULL =====
    if ($null -eq $AppErrorMessage) {
        if($Language -eq "de") {
            $AppErrorMessage = "ErrorCode ist nicht verfügbar"
        }
        else {
            $AppErrorMessage = "ErrorCode is not available"
        }
    }

    # ===== create the final error message =====
    $SpecificErrorMessage = if ($RefValue) {
        if ($ExceptionMessage) {
            "$RefValue '$ErrorCode': $AppErrorMessage. 'ExceptionMessage': $ExceptionMessage."
        }
        else {
            "$RefValue '$ErrorCode': $AppErrorMessage."
        }
    } else {
        if ($ExceptionMessage) {
            "'$ErrorCode': $AppErrorMessage. 'ExceptionMessage': $ExceptionMessage."
        }
        else {
            "'$ErrorCode': $AppErrorMessage."
        }
    }

    return $SpecificErrorMessage
}