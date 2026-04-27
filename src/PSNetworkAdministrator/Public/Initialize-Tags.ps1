function Initialize-Tags {
    <#

    #>

    [CmdletBinding()]
    param(
        [ValidateSet('de', 'en')]
        [string]$Language = $script:ModuleConfig.Language
    )

    # ===== Initialize tags from config file =====
    $HostRoleAttribute = $script:ModuleConfig.Tags.HostRole
    $GroupTagAttribute = $script:ModuleConfig.Tags.Group
    $SystemEnvironmentTagAttribute = $script:ModuleConfig.Tags.SystemEnvironment
    $OperatingSystemAttribute = $script:ModuleConfig.Tags.OperatingSystem

    # ===== Check the tag variables =====
    $HostRoleAttributeCheck = Test-FunctionVariables -Param $HostRoleAttribute -ParamName '$HostRoleAttribute' -Language $Language
    $GroupTagAttributeCheck = Test-FunctionVariables -Param $GroupTagAttribute -ParamName '$GroupTagAttribute' -Language $Language
    $SystemEnvironmentTagAttributeCheck = Test-FunctionVariables -Param $SystemEnvironmentTagAttribute -ParamName '$SystemEnvironmentTagAttribute' -Language $Language
    $OperatingSystemAttributeCheck = Test-FunctionVariables -Param $OperatingSystemAttribute -ParamName '$OperatingSystemAttribute' -Language $Language

    if (-not ($HostRoleAttributeCheck.Success) -and -not ($GroupTagAttributeCheck.Success) -and -not ($SystemEnvironmentTagAttributeCheck.Success) -and -not ($OperatingSystemAttributeCheck.Success)) {
        $ErrorMessages = @()
        if (-not ($HostRoleAttributeCheck.Success)) {$ErrorMessages += $HostRoleAttributeCheck.Message}
        if (-not ($GroupTagAttributeCheck.Success)) {$ErrorMessages += $GroupTagAttributeCheck.Message}
        if (-not ($SystemEnvironmentTagAttributeCheck.Success)) {$ErrorMessages += $SystemEnvironmentTagAttributeCheck.Message}
        if (-not ($OperatingSystemAttributeCheck.Success)) {$ErrorMessages += $OperatingSystemAttributeCheck.Message}

        $ErrorMessage = $ErrorMessages -join '; '
        throw $ErrorMessage
    }

    # ===== Get all tags =====
    try {
        # Get all tags
        $HostRole = @($HostRoleAttribute -split ',' | ForEach-Object {$_.Trim()} | Where-Object {-not [string]::IsNullOrWhiteSpace($_)})
        $GroupTag = @($GroupTagAttribute -split ',' | ForEach-Object {$_.Trim()} | Where-Object {-not [string]::IsNullOrWhiteSpace($_)})
        $SystemEnvironmentTag = @($SystemEnvironmentTagAttribute -split ',' | ForEach-Object {$_.Trim()} | Where-Object {-not [string]::IsNullOrWhiteSpace($_)})
        $OperatingSystem = @($OperatingSystemAttribute -split ',' | ForEach-Object {$_.Trim()} | Where-Object {-not [string]::IsNullOrWhiteSpace($_)})

        # Return all tags with tag counts
        return [pscustomobject]@{
            HostRoleCount = $HostRole.Count
            HostRole = if ($HostRole.Count -gt 0) {$HostRole} else {$null}
            GroupTagCount = $GroupTag.Count
            GroupTag = if ($GroupTag.Count -gt 0) {$GroupTag} else {$null}
            SystemEnvironmentTagCount = $SystemEnvironmentTag.Count
            SystemEnvironmentTag = if ($SystemEnvironmentTag.Count -gt 0) {$SystemEnvironmentTag} else {$null}
            OperatingSystemCount = $OperatingSystem.Count
            OperatingSystem = if ($OperatingSystem.Count -gt 0) {$OperatingSystem} else {$null}
        }
    }
    catch {
        $RefValue = Get-RefValue -AdditionalRef 'Tags' -Language $Language
        $ErrorMessage = Get-ErrorMessages -ErrorCode 'SYx0000012' -ExceptionMessage "$($_.Exception.Message)" -RefValue $RefValue -Language $Language
        throw $ErrorMessage
    }
}