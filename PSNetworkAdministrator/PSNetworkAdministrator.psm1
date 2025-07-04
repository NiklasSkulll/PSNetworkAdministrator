# PSNetworkAdministrator.psm1
# This is the root module file that imports all components

# Load all script files
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import Classes
$Classes = @( Get-ChildItem -Path "$ScriptPath\Classes\*.ps1" -Recurse -ErrorAction SilentlyContinue )
foreach ($Class in $Classes) {
    try {
        . $Class.FullName
    } catch {
        Write-Error "Failed to import class file $($Class.FullName): $_"
    }
}

# Import Private functions
$PrivateFunctions = @( Get-ChildItem -Path "$ScriptPath\Private\*.ps1" -Recurse -ErrorAction SilentlyContinue )
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
    } catch {
        Write-Error "Failed to import private function file $($Function.FullName): $_"
    }
}

# Import Public functions
$PublicFunctions = @( Get-ChildItem -Path "$ScriptPath\Public\*.ps1" -Recurse -ErrorAction SilentlyContinue )
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
    } catch {
        Write-Error "Failed to import public function file $($Function.FullName): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName
