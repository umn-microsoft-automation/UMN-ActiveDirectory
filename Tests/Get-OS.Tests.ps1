$TestConfig = @{
    "TestModuleName" = "UMN-ActiveDirectory"
}

try {
    if ($ModuleRoot) {
        Import-Module (Join-Path $ModuleRoot "$ModuleName.psd1") -Force
    }
    else {
        if (Test-Path -Path "..\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1") {
            Import-Module "..\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1" -Force
        }
        elseif (Test-Path -Path ".\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1") {
            Import-Module ".\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1" -Force
        }
    }

    # Module scope fixes problems with AD mocking.  It needs to be here to fix issues with running
    # tests on devices without AD module installed.
    InModuleScope -ModuleName $TestConfig.TestModuleName {
        if($ModuleRoot) {
            . "$ModuleRoot..\Tests\StandardTestData.ps1"
        } else {
            if(Test-Path -Path "StandardTestData.ps1") {
                . .\StandardTestData.ps1
            } elseif(Test-Path -Path "Tests\StandardTestData.ps1") {
                . .\Tests\StandardTestData.ps1
            } else {
                throw "Error importing StandardTestData.ps1"
            }
        }

        Describe "Get-OS" {
            Context "Basic tests" {
                Mock -CommandName Get-ADComputer -MockWith { return [PSCustomObject]$FakeADComputer }

                $OS = Get-OS -ComputerName $TestPresetParams.ComputerName
                
                It "Should return the correct computer OS" {
                    $OS | Should -Be $TestPresetParams.OperatingSystem
                }

                It "Should call Get-ADComputer once" {
                    Assert-MockCalled -CommandName Get-ADComputer -Times 1 -Exactly
                }
            }
        }
    }
} catch {
    $Error[0]
}