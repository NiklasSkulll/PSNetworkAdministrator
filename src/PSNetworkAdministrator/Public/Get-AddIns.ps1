function Get-AddIns {
    <#
    
    #>

    [CmdletBinding()]
    param(
        [ValidateSet('de', 'en')]
        [string]$Language = 'en'
    )

    # ===== Initialize AddIns from config file =====
    $AddInCount = $script:ModuleConfig.AddIns.AddInCount
    $AddInNames = $script:ModuleConfig.AddIns.AddInNames
    $AddInPaths = $script:ModuleConfig.AddIns.AddInPaths
    $AddInArguments = $script:ModuleConfig.AddIns.AddInArguments
    
    # ===== Check the AddIns variables =====
    $AddInCountCheck = Test-FunctionVariables -Param $AddInCount -ParamName '$AddInCount' -Language $Language
    $AddInNamesCheck = Test-FunctionVariables -Param $AddInNames -ParamName '$AddInNames' -Language $Language
    $AddInPathsCheck = Test-FunctionVariables -Param $AddInPaths -ParamName '$AddInPaths' -Language $Language
    $AddInArgumentsCheck = Test-FunctionVariables -Param $AddInArguments -ParamName '$AddInArguments' -Language $Language

    if (-not ($AddInCountCheck.Success) -or -not ($AddInNamesCheck.Success) -or -not ($AddInPathsCheck.Success) -or -not ($AddInArgumentsCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($AddInCountCheck.Success)) {$ErrorMessages += $AddInCountCheck.Message}
        if (-not ($AddInNamesCheck.Success)) {$ErrorMessages += $AddInNamesCheck.Message}
        if (-not ($AddInPathsCheck.Success)) {$ErrorMessages += $AddInPathsCheck.Message}
        if (-not ($AddInArgumentsCheck.Success)) {$ErrorMessages += $AddInArgumentsCheck.Message}
        
        $ErrorMessage = $ErrorMessages -join '; '

        throw $ErrorMessage
    }
    
    # ===== Get all AddIns =====
    try {
        $AddIns = @()
        $AddInCountRef = $AddInCount
        $Names = $AddInNames -split ','
        $Paths = $AddInPaths -split ','
        $Arguments = $AddInArguments -split ','

        $AC = 0
        while ($AddInCountRef -gt 0) {
            $AddInCountRef--

            $AddInN = $Names[$AC].Trim()
            $AddInP = $Paths[$AC].Trim()
            $AddInA = $Arguments[$AC].Trim()

            $AddIn = [pscustomobject]@{
                AddInName = $AddInN
                AddInPath = $AddInP
                AddInArgument = $AddInA
            }

            $AddIns += $AddIn

            $AC++
        }

        # Return AddIns
        return [pscustomobject]@{
            AddInCount = $AddInCount
            AddIns = $AddIns
        }
    }
    catch {
        $RefValue = Get-RefValue -AdditionalRef 'AddIn' -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'SYx0000012' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }
}