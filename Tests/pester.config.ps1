# Pester configuration for PSNetworkAdministrator
@{
    Run = @{
        Path = '.\Tests'
        PassThru = $true
        Exit = $false
        
        # This initialization script will run before any test is executed
        # It sets up proper mocking and overrides for interactive elements
        ScriptBlock = {
            param($Context)
            
            # Global flag to signal we're in test mode
            $Global:PSNetworkAdminTestMode = $true
            Write-Host "Setting up test environment - all UI and interactive elements will be suppressed" -ForegroundColor Cyan
            
            # Mock the Read-Host function globally to avoid interactive prompts
            function global:Read-Host { 
                Write-Verbose "MOCK: Read-Host called and returned 'Q'" 
                return "Q"
            }
            
            # Mock Write-Host to prevent UI output during tests
            # This prevents any visual menu from displaying during tests
            function global:Write-Host { 
                param($Object, $ForegroundColor, $NoNewline) 
                # If you need to debug test output, uncomment the line below:
                # Write-Debug "MOCK: Write-Host called with: $Object"
            }
            
            # Mock Get-Host for ReadKey operations
            function global:MockGetHost {
                return [PSCustomObject]@{
                    UI = [PSCustomObject]@{
                        RawUI = [PSCustomObject]@{
                            ReadKey = {
                                param($Options)
                                Write-Verbose "MOCK: ReadKey called and returned 'Q'"
                                return [PSCustomObject]@{ Character = 'Q' }
                            }
                        }
                    }
                }
            }
            
            # Only mock Get-Host if it hasn't been mocked yet
            if ((Get-Command Get-Host).ScriptBlock -notmatch 'MockGetHost') {
                # Save original Get-Host for later restore if needed
                $Global:OriginalGetHost = (Get-Command Get-Host).ScriptBlock
                
                # Replace with our mock
                Set-Item -Path function:global:Get-Host -Value ${function:global:MockGetHost}
            }
            
            # Ensure all tests use TestInput and SkipMenuDisplay when calling Get-MenuOption
            if (Get-Command Get-MenuOption -ErrorAction SilentlyContinue) {
                # Create a wrapper that ensures test parameters are set
                $originalMenuOption = Get-Command Get-MenuOption
                function global:Get-MenuOption {
                    param(
                        [Parameter()]
                        [switch]$SkipMenuDisplay,
                        [Parameter()]
                        [string]$TestInput
                    )
                    
                    # Always force SkipMenuDisplay in test environment
                    $originalMenuOption.ScriptBlock.Invoke($true, ($TestInput -or "1"))
                }
            }
        }
    }
    Filter = @{
        Tag = ''
        ExcludeTag = @('Integration', 'Manual')
    }
    Output = @{
        Verbosity = 'Detailed'
        StackTraceVerbosity = 'FirstLine'
        CIFormat = 'Auto'
    }
    TestResult = @{
        Enabled = $true
        OutputPath = '.\Tests\TestResults.xml'
        OutputFormat = 'NUnitXml'
    }
    CodeCoverage = @{
        Enabled = $true
        Path = '.\PSNetworkAdministrator\Public\*.ps1', '.\PSNetworkAdministrator\Private\*.ps1'
        OutputPath = '.\Tests\CodeCoverage.xml'
        OutputFormat = 'JaCoCo'
    }
    Should = @{
        ErrorAction = 'Continue'
    }
    Debug = @{
        ShowFullErrors = $true
    }
}
