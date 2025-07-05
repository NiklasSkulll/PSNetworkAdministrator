# Tests for New-StatusObject
Describe "New-StatusObject" {
    BeforeAll {
        # Import the module - this will be handled by Pester but we include it explicitly for clarity
        $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\PSNetworkAdministrator"
        Import-Module $modulePath -Force
        
        # Load the private function for direct testing
        . (Join-Path -Path $modulePath -ChildPath "Private\New-StatusObject.ps1")
    }
    
    Context "Parameter validation" {
        It "Creates a status object with default values" {
            $status = New-StatusObject
            $status | Should -Not -BeNullOrEmpty
            $status.ModuleName | Should -Be "PSNetworkAdministrator"
            $status.Status | Should -Be "Initialized"
        }
        
        It "Accepts custom ModuleName parameter" {
            $customName = "CustomModuleName"
            $status = New-StatusObject -ModuleName $customName
            $status.ModuleName | Should -Be $customName
        }
        
        It "Accepts custom Status parameter" {
            $customStatus = "Testing"
            $status = New-StatusObject -Status $customStatus
            $status.Status | Should -Be $customStatus
        }
        
        It "Accepts custom Domain parameter" {
            $customDomain = "test.domain.com"
            $status = New-StatusObject -Domain $customDomain
            $status.Domain | Should -Be $customDomain
        }
        
        It "Accepts custom UserChoice parameter" {
            $customChoice = "1"
            $status = New-StatusObject -UserChoice $customChoice
            $status.UserChoice | Should -Be $customChoice
        }
    }
    
    Context "Object properties" {
        It "Creates an object with all expected properties" {
            # Explicitly pass all parameters to avoid parameter binding issues
            $status = New-StatusObject -ModuleName "Test" -Version "1.0" -Status "Ready" -Domain "test.local" -UserChoice "1"
            $status | Should -HaveProperty "ModuleName"
            $status | Should -HaveProperty "Version"
            $status | Should -HaveProperty "Status"
            $status | Should -HaveProperty "Domain"
            $status | Should -HaveProperty "Timestamp"
            $status | Should -HaveProperty "UserChoice"
        }
        
        It "Sets Timestamp to a DateTime object" {
            $status = New-StatusObject
            $status.Timestamp | Should -BeOfType [DateTime]
        }
        
        It "Has the correct PSTypeNames" {
            $status = New-StatusObject
            $status.PSTypeNames | Should -Contain 'PSNetworkAdministrator.StatusObject'
        }
    }
    
    Context "Error handling" {
        It "Handles null Version gracefully" {
            $status = New-StatusObject -Version $null
            $status.Version | Should -Be "0.1.0"
        }
        
        It "Handles null Domain gracefully" {
            $status = New-StatusObject -Domain $null
            $status.Domain | Should -Be "Not connected to a domain"
        }
    }
}
