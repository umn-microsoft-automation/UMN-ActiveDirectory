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

        Describe "Test-GPOWiFiServerName" {
            Context "Should return an object" {
                It "Should return an object for the ssid and indicate it was updated" {
                    (Test-GPOWiFiServerName -GPOXml $FakeWiFiProfileXML -ServerName "contoso.com").ProfileUpdated | Should -Be $true
                }

                It "Should return an object for the ssid and indicate it was not updated" {
                    (Test-GPOWiFiServerName -GPOXml $FakeWiFiProfileXML -ServerName "newcontoso.com").ProfileUpdated | Should -Be $false
                }
            }
        }
    }
} catch {
    $Error[0]
}