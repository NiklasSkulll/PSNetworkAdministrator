function Get-ErrorMessages {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ErrorCode,

        [string]$ExceptionMessage,

        [string]$RefValue,

        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )
    
    # ===== Check if ErrorCode is NULL/whitespace =====
    if ([string]::IsNullOrWhiteSpace($ErrorCode)) {
        $ErrorCode = if ($Language -eq "de") {'ErrorCode-NULL/Leerzeichen'} else {'ErrorCode-NULL/whitespace'}
    }

    # ===== Mapping: ErrorCode to error message (en, de) =====
    $ErrorMessagesEN = @{
        'COx0000001' = 'DNS not resolvable' # CO = connection
        'COx0000002' = 'WSMan/WinRM not reachable'
        'COx0000003' = 'TCP Connection failed'
        'COx0000004' = 'Ping without response'
        'COx0000005' = 'CimSession failed'
        'DBx0000001' = 'Data schema is missing Table' # DB = data base
        'DBx0000002' = 'Data schema is missing Columns'
        'DBx0000003' = 'Columns are empty'
        'DBx0000004' = 'Column is missing Name'
        'DBx0000005' = 'Column is missing Type'
        'DBx0000006' = 'Index is missing UX'
        'DBx0000007' = 'Index is missing IndexNames'
        'DBx0000008' = 'IndexNames are empty'
        'DBx0000009' = 'IndexNames is missing Name'
        'DBx0000010' = 'Index column is not defined in schema columns'
        'DBx0000011' = 'IndexNames contains duplicates'
        'DBx0000012' = 'Invalid SQLite type for column. Allowed types: INTEGER/TEXT/REAL/BLOB'
        'DBx0000013' = 'Failed to create data table'
        'DBx0000014' = 'Failed to add data into SQLite'
        'FPx0000001' = 'Missing file' # FP = file path
        'FPx0000002' = 'Failed loading file'
        'FPx0000003' = 'Failed to write into file'
        'INx0000001' = 'Failed to get domain informations' # IN = information
        'INx0000002' = 'Failed to get computer informations'
        'INx0000003' = 'Failed to get SQLite data schema'
        'INx0000004' = 'Failed to load SQLite DLL during PSNetworkAdministrator module import'
        'INx0000005' = 'Failed to store credentials'
        'INx0000006' = 'Failed to start a process'
        'RMx0000001' = 'Administrator rights are required' # RM = rights management
        'VAx0000001' = 'Variable is NULL' # VA = variable
        'VAx0000002' = 'Variable is NULL/whitespace'
        'VAx0000003' = 'Variable length is 0'
        'VAx0000004' = 'Variable length must be 16, 24, or 32'
        'VAx0000005' = 'Variable has 0 elements'
        'VAx0000006' = 'Unknown variable name'
        'VAx0000007' = 'Invalid name. Allowed: letters/numbers/_ and not start with a number'
    }

    $ErrorMessagesDE = @{
        'COx0000001' = 'DNS kann nicht aufgelöst werden' # CO = connection
        'COx0000002' = 'WSMan/WinRM nicht erreichbar'
        'COx0000003' = 'TCP-Verbindung ist fehlgeschlagen'
        'COx0000004' = 'Ping ohne Antwort'
        'COx0000005' = 'Cim-Sitzung ist fehlgeschlagen'
        'DBx0000001' = 'Datenbankschema hat keine Table' # DB = data base
        'DBx0000002' = 'Datenbankschema hat keine Columns'
        'DBx0000003' = 'Spalten sind leer'
        'DBx0000004' = 'Spalte fehlt Name'
        'DBx0000005' = 'Spalte fehlt Type'
        'DBx0000006' = 'Index hat kein UX'
        'DBx0000007' = 'Index hat kein IndexNames'
        'DBx0000008' = 'IndexNames ist leer'
        'DBx0000009' = 'IndexNames fehlt Name'
        'DBx0000010' = 'Index-Spalte ist nicht in den Spalten des Schemas definiert'
        'DBx0000011' = 'IndexNames enthält Duplikate'
        'DBx0000012' = 'SQLite-Typ für Spalten ist invalide. Erlaubte Typen: INTEGER/TEXT/REAL/BLOB'
        'DBx0000013' = 'Datenbanktabelle konnte nicht erstellt werden'
        'DBx0000014' = 'Daten konnten nicht in SQLite hinzugefügt werden'
        'FPx0000001' = 'Fehlende Datei' # FP = file path
        'FPx0000002' = 'Datei konnte nicht geladen werden'
        'FPx0000003' = 'Es konnte nicht in die Datei geschrieben werden'
        'INx0000001' = 'Domaininformationen konnten nicht abgerufen werden' # IN = information
        'INx0000002' = 'Computerinformationen konnten nicht abgerufen werden'
        'INx0000003' = 'SQLite-Datenschema konnte nicht abgerufen werden'
        'INx0000004' = 'SQLite DLL konnte beim Importieren des PSNetworkAdministrator-Modules nicht geladen werden'
        'INx0000005' = 'Credentials konnten nicht gespeichert werden'
        'INx0000006' = 'Prozess konnte nicht gestartet werden'
        'RMx0000001' = 'Administratorrechte werde benötigt' # RM = rights management
        'VAx0000001' = 'Variable ist NULL' # VA = variable
        'VAx0000002' = 'Variable ist NULL/besteht aus Leerzeichen'
        'VAx0000003' = 'Variable hat eine Zeichenlänge von 0'
        'VAx0000004' = 'Variable muss eine Zeichenlänge von 16, 24, oder 32 haben'
        'VAx0000005' = 'Variable hat 0 Elemente'
        'VAx0000006' = 'Unbekannter Variablenname'
        'VAx0000007' = 'Name ist nicht valide. Erlaubt: Buchstaben/Nummern/_ und nicht mit einer Nummer starten'
    }

    # ===== Get the correct error message from the ErrorCode =====
    $AppErrorMessage = if ($Language -eq "de") {
        if ($ErrorMessagesDE.ContainsKey($ErrorCode)) {$ErrorMessagesDE[$ErrorCode]} else {$null}
    }
    else {
        if ($ErrorMessagesEN.ContainsKey($ErrorCode)) {$ErrorMessagesEN[$ErrorCode]} else {$null}
    }

    # ===== Check the $AppErrorMessage variable =====
    if (-not $AppErrorMessage) {
        $AppErrorMessage = if ($Language -eq "de") {'ErrorCode ist nicht verfügbar'} else {'ErrorCode is not available'}
    }

    # ===== Create the final error message =====
    $SpecificErrorMessage = if ($RefValue) {
        if ($ExceptionMessage.StartsWith("<")) {
            "$RefValue <'$ErrorCode': $AppErrorMessage. >> $ExceptionMessage.>"
        }
        elseif ($ExceptionMessage) {
            "$RefValue <'$ErrorCode': $AppErrorMessage. 'ExceptionMessage': $ExceptionMessage.>"
        }
        else {
            "$RefValue <'$ErrorCode': $AppErrorMessage.>"
        }
    }
    else {
        if ($ExceptionMessage.StartsWith("<")) {
            "<'$ErrorCode': $AppErrorMessage. >> $ExceptionMessage.>"
        }
        elseif ($ExceptionMessage) {
            "<'$ErrorCode': $AppErrorMessage. 'ExceptionMessage': $ExceptionMessage.>"
        }
        else {
            "<'$ErrorCode': $AppErrorMessage.>"
        }
    }

    return $SpecificErrorMessage
}