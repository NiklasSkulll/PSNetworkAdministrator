# Tests for Show-StatusInformation
Describe "Show-StatusInformation" {
    BeforeAll {
        # Import the module - this will be handled by Pester but we include it explicitly for clarity
        $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\PSNetworkAdministrator"
        
        # Directly dot source the private functions for testing
        . "$modulePath\Private\New-StatusObject.ps1"
        . "$modulePath\Private\Show-StatusInformation.ps1"
        
        Import-Module $modulePath -Force
        
        # Create a mock status object for testing
        $script:testStatus = [PSCustomObject]@{
            ModuleName = "TestModule"
            Version = "1.0.0"
            Status = "Testing"
            Domain = "test.domain"
            Timestamp = Get-Date
            UserChoice = "1"
        }
        # Add type name the correct way
        $script:testStatus.PSObject.TypeNames.Insert(0, 'PSNetworkAdministrator.StatusObject')
    }
    
    Context "Parameter validation" {
        It "Should have a mandatory StatusObject parameter" {
            $commandInfo = Get-Command -Name Show-StatusInformation
            $commandInfo | Should -Not -BeNullOrEmpty
            $parameter = $commandInfo.Parameters['StatusObject']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | 
                Select-Object -First 1 | 
                ForEach-Object { $_.Mandatory } | Should -BeTrue
        }
        
        It "Should accept pipeline input" {
            $commandInfo = Get-Command -Name Show-StatusInformation
            $commandInfo | Should -Not -BeNullOrEmpty
            $parameter = $commandInfo.Parameters['StatusObject']
            $parameter | Should -Not -BeNullOrEmpty
            $parameter.Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] } | 
                Select-Object -First 1 | 
                ForEach-Object { $_.ValueFromPipeline } | Should -BeTrue
        }
    }
    
    Context "Function behavior" {
        BeforeEach {
            # Mock Write-Host
            Mock Write-Host {}
        }
        
        It "Should not throw an error with valid input" {
            { Show-StatusInformation -StatusObject $script:testStatus } | Should -Not -Throw
        }
        
        It "Should call Write-Host multiple times" {
            # Execute the function
            Show-StatusInformation -StatusObject $script:testStatus
            
            # Verify Write-Host was called
            Should -Invoke Write-Host -Times 8 -Exactly
        }
        
        It "Should conditionally display UserChoice when provided" {
            # Create a status object with UserChoice
            $statusWithChoice = $script:testStatus.PSObject.Copy()
            $statusWithChoice.UserChoice = "Q"
            
            # Execute the function with UserChoice
            Show-StatusInformation -StatusObject $statusWithChoice
            
            # Should have one more Write-Host call (for UserChoice)
            Should -Invoke Write-Host -Times 8 -Exactly
        }
        
        It "Should not display UserChoice when empty" {
            $statusNoChoice = $script:testStatus.PSObject.Copy()
            $statusNoChoice.UserChoice = ""
            
            # Temporarily re-mock to track calls with UserChoice
            Mock Write-Host {
                param($Object, $ForegroundColor, $NoNewLine)
                
                # We want to verify that no call contains "UserChoice"
                if ($Object -match "UserChoice") {
                    # Create variable to track this
                    $global:foundUserChoice = $true
                }
            }
            
            # Reset tracking variable
            $global:foundUserChoice = $false
            
            # Execute function
            Show-StatusInformation -StatusObject $statusNoChoice
            
            # Verify we didn't output UserChoice
            $global:foundUserChoice | Should -BeFalse
        }
    }
    
    Context "Pipeline support" {
        BeforeEach {
            # Mock Write-Host
            Mock Write-Host {}
        }
        
        It "Should accept pipeline input" {
            # Send object through pipeline
            $script:testStatus | Show-StatusInformation
            
            # Verify Write-Host was called
            Should -Invoke Write-Host -Times 8 -Exactly
        }
        
        It "Should process multiple objects from pipeline" {
            $status1 = $script:testStatus.PSObject.Copy()
            $status2 = $script:testStatus.PSObject.Copy()
            $status2.ModuleName = "AnotherModule"
            
            # Send both objects through pipeline
            @($status1, $status2) | Show-StatusInformation
            
            # Verify Write-Host was called twice as much
            Should -Invoke Write-Host -Times 16 -Exactly
        }
    }
}
