# Tests for Invoke-PSNetworkAdmin
Describe "Invoke-PSNetworkAdmin" {
    BeforeAll {
        # Check if we're running in non-interactive mode
        $isNonInteractive = Get-Variable -Name TestsNonInteractive -Scope Global -ErrorAction SilentlyContinue
        
        $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\PSNetworkAdministrator"
        
        # Load private functions directly so they can be mocked properly
        . (Join-Path -Path $modulePath -ChildPath "Private\Get-MenuOption.ps1")
        . (Join-Path -Path $modulePath -ChildPath "Private\New-StatusObject.ps1")
        . (Join-Path -Path $modulePath -ChildPath "Private\Show-StatusInformation.ps1")
        . (Join-Path -Path $modulePath -ChildPath "Private\Write-Log.ps1")
        
        # Import module only if not in non-interactive mode
        if (-not $isNonInteractive) {
            Import-Module $modulePath -Force
        }
        
        # Always mock interactive functions
        Mock Clear-Host { }
        Mock Write-Host { }
        Mock Write-Verbose { }
        Mock Write-Log { }
        Mock Read-Host { return "Q" }
        
        # Mock menu selection
        Mock Get-MenuOption {
            return [PSCustomObject]@{
                IsQuit = $false
                IsValid = $true
                Option = [PSCustomObject]@{
                    Number = "1"
                    Name = "User Management"
                    Command = "Invoke-UserManagement"
                }
            }
        }
        
        # Mock status functions
        Mock New-StatusObject {
            $statusObj = [PSCustomObject]@{
                ModuleName = "PSNetworkAdministrator"
                Version = "0.1.0"
                Status = "Testing"
                Domain = "test.domain"
                Timestamp = Get-Date
                UserChoice = $UserChoice
            }
            # Add TypeName the correct way
            $statusObj.PSObject.TypeNames.Insert(0, 'PSNetworkAdministrator.StatusObject')
            return $statusObj
        }
        
        Mock Show-StatusInformation { }
        
        # Mock ReadKey
        Mock Read-Host { return "Q" }
        $mockKeyInfo = [PSCustomObject]@{
            Character = 'Q'
        }
        $global:mockKeyPressed = 'Q'
        
        # Mock Host UI ReadKey
        Mock Get-Host {
            return [PSCustomObject]@{
                UI = [PSCustomObject]@{
                    RawUI = [PSCustomObject]@{
                        ReadKey = {
                            param($Options)
                            return $mockKeyInfo
                        }
                    }
                }
            }
        }
    }
    
    Context "Parameter handling" {
        It "Should accept Domain parameter" {
            { Invoke-PSNetworkAdmin -Domain "test.domain" -WhatIf } | Should -Not -Throw
        }
        
        It "Should accept Credential parameter" {
            $cred = New-Object System.Management.Automation.PSCredential("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
            { Invoke-PSNetworkAdmin -Credential $cred -WhatIf } | Should -Not -Throw
        }
        
        It "Should accept LogPath parameter" {
            { Invoke-PSNetworkAdmin -LogPath "C:\Logs\test.log" -WhatIf } | Should -Not -Throw
        }
    }
    
    Context "Main function flow" {
        It "Should support -WhatIf" {
            # Mock the Write-Verbose inside the module scope for this test
            InModuleScope -ModuleName PSNetworkAdministrator {
                $verboseCalled = $false
                function Write-Verbose {
                    param($Message)
                    $script:verboseCalled = $true
                }
                
                $null = Invoke-PSNetworkAdmin -WhatIf
                $script:verboseCalled | Should -BeTrue
            }
        }
        
        It "Should handle immediate quit" {
            # Mock quit selection
            Mock Get-MenuOption {
                return [PSCustomObject]@{
                    IsQuit = $true
                    IsValid = $true
                    Option = $null
                }
            }
            
            $result = Invoke-PSNetworkAdmin
            $result | Should -Be "Quit"
        }
        
        It "Should call Get-MenuOption" {
            # This test passes by simply verifying the mock is called
            $mockCalled = 0
            
            # Reset mock with a counter
            Mock Get-MenuOption {
                $script:mockCalled++
                return [PSCustomObject]@{
                    IsQuit = $false
                    IsValid = $true
                    Option = [PSCustomObject]@{
                        Number = "1"
                        Name = "User Management"
                        Command = "Invoke-UserManagement"
                    }
                }
            } -ParameterFilter { $true } -ModuleName PSNetworkAdministrator
            
            # Execute the function with TestMode to avoid UI
            $null = Invoke-PSNetworkAdmin -TestMode
            
            # Verify the mock was called
            Should -Invoke Get-MenuOption -Times 1 -Exactly -ModuleName PSNetworkAdministrator
        }
        
        It "Should create and show status object" {
            $null = Invoke-PSNetworkAdmin
            Should -Invoke New-StatusObject -Times 1 -Exactly
            Should -Invoke Show-StatusInformation -Times 1 -Exactly
        }
        
        It "Should handle Q keypress to quit" {
            # Mock user pressing Q to quit
            $global:mockKeyInfo = [PSCustomObject]@{
                Character = 'Q'
            }
            
            $result = Invoke-PSNetworkAdmin
            $result | Should -Be "Quit"
        }
        
        It "Should return status object for programmatic use" {
            # Mock non-Q keypress
            $global:mockKeyInfo = [PSCustomObject]@{
                Character = 'X'
            }
            
            # Use InModuleScope to modify internal function behavior
            $result = InModuleScope -ModuleName PSNetworkAdministrator {
                # Override the CommandOrigin check
                $script:MyInvocation = @{ CommandOrigin = 'Script' }
                Invoke-PSNetworkAdmin
            }
            
            $result | Should -Not -BeNullOrEmpty
            $result.ModuleName | Should -Be "PSNetworkAdministrator"
        }
    }
    
    Context "Error handling" {
        It "Should handle logging errors gracefully" {
            Mock Write-Log { throw "Log error" }
            { Invoke-PSNetworkAdmin } | Should -Not -Throw
        }
        
        It "Should handle domain errors gracefully" {
            Mock Get-Item -ParameterFilter { $Path -eq 'env:USERDNSDOMAIN' } { throw "Domain error" }
            { Invoke-PSNetworkAdmin } | Should -Not -Throw
        }
    }
}
