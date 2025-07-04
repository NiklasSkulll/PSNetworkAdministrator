# Pester configuration for PSNetworkAdministrator
@{
    Run = @{
        Path = '.\Tests'
        PassThru = $true
        Exit = $false
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
