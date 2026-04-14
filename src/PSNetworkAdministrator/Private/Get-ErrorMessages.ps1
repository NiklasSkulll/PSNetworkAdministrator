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
    
    # ===== Check if $ErrorCode is null or whitespace =====
    if ([string]::IsNullOrWhiteSpace($ErrorCode)) {$ErrorCode = 'SYx0000001'}

    # ===== Mapping: $ErrorCode to error message (en, de) =====
    $ErrorMessagesEN = @{
        'COx0000001' = 'Failed to resolve DNS' # CO = connection
        'COx0000002' = 'Failed to reach WSMan/WinRM'
        'COx0000003' = 'Failed to connect via TCP'
        'COx0000004' = 'Failed to ping target'
        'COx0000005' = 'Failed to create CimSession'
        'DBx0000001' = 'Schema is missing required property' # DB = data base
        'DBx0000002' = 'Schema property is empty'
        'DBx0000003' = 'Schema property contains duplicates'
        'DBx0000004' = 'Schema reference is undefined'
        'DBx0000005' = 'SQLite column type is invalid'
        'DBx0000006' = 'Failed to create data table'
        'DBx0000007' = 'Failed to insert data into SQLite'
        'DBx0000008' = 'Failed to get schema'
        'DBx0000009' = 'Failed to initialize schema'
        'IOx0000001' = 'File not found' # IO = input/output
        'IOx0000002' = 'Failed to load file'
        'IOx0000003' = 'Failed to write to file'
        'PRx0000001' = 'Administrative privileges are required' # PR = privileges
        'SYx0000001' = 'ErrorCode is null or whitespace' # SY = system/runtime
        'SYx0000002' = 'ErrorCode is unknown'
        'SYx0000003' = 'Failed to get domain information'
        'SYx0000004' = 'Failed to get computer information'
        'SYx0000005' = 'Failed to load SQLite DLL'
        'SYx0000006' = 'SQLite DLL not found'
        'SYx0000007' = 'Failed to store credentials'
        'SYx0000008' = 'Failed to start a process'
        'SYx0000009' = 'Module not found'
        'SYx0000010' = 'Failed to import module'
        'VAx0000001' = 'Variable is null' # VA = variable
        'VAx0000002' = 'Variable is null or whitespace'
        'VAx0000003' = 'Variable length is 0'
        'VAx0000004' = 'Variable length must be 16, 24, or 32'
        'VAx0000005' = 'Variable has no elements'
        'VAx0000006' = 'Variable name is unknown'
        'VAx0000007' = 'Name is invalid. Only letters, numbers and underscores allowed and not start with a number'
    }

    $ErrorMessagesDE = @{
        'COx0000001' = 'DNS kann nicht aufgelöst werden' # CO = connection
        'COx0000002' = 'WSMan/WinRM nicht erreichbar'
        'COx0000003' = 'TCP-Verbindung fehlgeschlagen'
        'COx0000004' = 'Ping erhielt keine Antwort'
        'COx0000005' = 'Cim-Sitzung konnte nicht erstellt werden'
        'DBx0000001' = 'Im Datenbankschema fehlt die erforderliche Eigenschaft' # DB = data base
        'DBx0000002' = 'Datenbankschema-Eigenschaft ist leer'
        'DBx0000003' = 'Datenbankschema-Eigenschaft enthält Duplikate'
        'DBx0000004' = 'Datenbankschema-Referenz ist undefiniert'
        'DBx0000005' = 'SQLite-Spaltentyp ist ungültig'
        'DBx0000006' = 'Datenbanktabelle konnte nicht erstellt werden'
        'DBx0000007' = 'Daten konnten nicht in SQLite eingefügt werden'
        'DBx0000008' = 'Datenbankschema konnte nicht abgerufen werden'
        'DBx0000009' = 'Datenbankschema konnte nicht initialisiert werden'
        'IOx0000001' = 'Datei fehlt' # IO = input/output
        'IOx0000002' = 'Datei konnte nicht geladen werden'
        'IOx0000003' = 'Datei konnte nicht beschrieben werden'
        'PRx0000001' = 'Administratorrechte sind erforderlich' # PR = privileges
        'SYx0000001' = 'ErrorCode ist NULL oder besteht nur aus Leerzeichen' # SY = system/runtime
        'SYx0000002' = 'ErrorCode ist unbekannt'
        'SYx0000003' = 'Domaininformationen konnten nicht abgerufen werden'
        'SYx0000004' = 'Computerinformationen konnten nicht abgerufen werden'
        'SYx0000005' = 'SQLite-DLL konnte nicht geladen werden'
        'SYx0000006' = 'SQLite-DLL fehlt'
        'SYx0000007' = 'Anmeldeinformationen konnten nicht gespeichert werden'
        'SYx0000008' = 'Prozess konnte nicht gestartet werden'
        'SYx0000009' = 'Modul fehlt'
        'SYx0000010' = 'Modul konnte nicht importiert werden'
        'VAx0000001' = 'Variable ist NULL' # VA = variable
        'VAx0000002' = 'Variable ist NULL oder besteht nur aus Leerzeichen'
        'VAx0000003' = 'Variable hat die Zeichenlänge 0'
        'VAx0000004' = 'Variable hat nicht die Zeichenlänge von 16, 24, oder 32'
        'VAx0000005' = 'Variable enthält keine Elemente'
        'VAx0000006' = 'Variablenname ist unbekannt'
        'VAx0000007' = 'Name ist ungültig. Nur Buchstaben, Zahlen und Unterstrich sind erlaubt und darf nicht mit einer Zahl beginnen'
    }

    # ===== Get the correct error message from $ErrorCode =====
    $ErrorMessagesRef = if ($Language -eq "de") {$ErrorMessagesDE} else {$ErrorMessagesEN}
    $AppErrorMessage = if ($ErrorMessagesRef.ContainsKey($ErrorCode)) {$ErrorMessagesRef[$ErrorCode]} else {$null}

    # ===== Check the $AppErrorMessage variable =====
    if (-not $AppErrorMessage) {
        $ErrorCodeRef = 'SYx0000002'
        $AppErrorMessage = if ($ErrorMessagesRef.ContainsKey($ErrorCodeRef)) {$ErrorMessagesRef[$ErrorCodeRef]} else {$null}
    }

    # ===== Create the final error message =====
    $SpecificErrorMessage = if ($RefValue) {
        if ($ExceptionMessage -and $ExceptionMessage.StartsWith('[')) {
            "[$ErrorCode] $AppErrorMessage | Ref=$RefValue >> $ExceptionMessage"
        }
        elseif ($ExceptionMessage) {
            "[$ErrorCode] $AppErrorMessage | Ref=$RefValue | Exception=$ExceptionMessage"
        }
        else {
            "[$ErrorCode] $AppErrorMessage | Ref=$RefValue"
        }
    }
    else {
        if ($ExceptionMessage -and $ExceptionMessage.StartsWith('[')) {
            "[$ErrorCode] $AppErrorMessage >> $ExceptionMessage"
        }
        elseif ($ExceptionMessage) {
            "[$ErrorCode] $AppErrorMessage | Exception=$ExceptionMessage"
        }
        else {
            "[$ErrorCode] $AppErrorMessage"
        }
    }

    # ===== Return the error message =====
    return $SpecificErrorMessage
}