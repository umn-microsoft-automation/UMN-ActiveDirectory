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

        Describe "Confirm-ADObjectDCReplication" {
            Mock -CommandName Get-ADDomainController -MockWith {
                [System.Collections.ArrayList]$ReturnObject = @()

                foreach ($int in 1..6) {
                    $ReturnObject.Add([PSCustomObject]@{
                            HostName = "DC$int"
                        })
                }

                return $ReturnObject
            }

            Context "Successful object replacation across domain controllers" {
                Mock -CommandName Confirm-ADObjectExists { return $true }

                It "Should return true if a computer is found on all the domain controllers" {
                    Confirm-ADObjectDCReplication -ADObject $TestPresetParams.ComputerName -Type "Computer" | Should -Be $true
                }

                It "Should return true if a user is found on all the domain controllers" {
                    Confirm-ADObjectDCReplication -ADObject $TestPresetParams.UserName -Type "User" | Should -Be $true
                }

                It "Should return true if a group is found on all the domain controllers" {
                    Confirm-ADObjectDCReplication -ADObject $TestPresetParams.Group -Type "Group" | Should -Be $true
                }

                It "Should return true if an OU is found on all the domain controllers" {
                    Confirm-ADObjectDCReplication -ADObject $TestPresetParams.OU -Type "OU" | Should -Be $true
                }

                It "Should return true if an unknown object is found on all the domain controllers" {
                    Confirm-ADObjectDCReplication -ADObject "SomethingUnknown" -Type "Unknown" | Should -Be $true
                }
            }

            Context "Unsuccessful object replacation across domain controllers" {
                Mock -CommandName Confirm-ADObjectExists { return $false }

                It "Should return false if a computer is not found on all the domain controllers" {
                    Confirm-ADObjectDCReplication -ADObject $TestPresetParams.ComputerName -Type "Computer" -MaxWait 2 | Should -Be $false
                }

                It "Should return false if a user is not found on all the domain controllers" {
                    Confirm-ADObjectDCReplication -ADObject $TestPresetParams.UserName -Type "User" -MaxWait 2 | Should -Be $false
                }

                It "Should return false if a group is not found on all the domain controllers" {
                    Confirm-ADObjectDCReplication -ADObject $TestPresetParams.Group -Type "Group" -MaxWait 2 | Should -Be $false
                }

                It "Should return false if an OU is not found on all the domain controllers" {
                    Confirm-ADObjectDCReplication -ADObject $TestPresetParams.OU -Type "OU" -MaxWait 2 | Should -Be $false
                }

                It "Should return false if an unknown object is not found on all the domain controllers" {
                    Confirm-ADObjectDCReplication -ADObject "SomethingUnknown" -Type "Unknown" -MaxWait 2 | Should -Be $false
                }
            }

            Context "Error during main confirmation logic" {
                Mock -CommandName Confirm-ADObjectExists { throw [System.Exception] }

                It "Should not throw an error if there is an error during the confirm logic for a computer" {
                    { Confirm-ADObjectDCReplication -ADObject $TestPresetParams.ComputerName -Type "Computer" -MaxWait 1 } | Should -Not -Throw
                }

                It "Should not throw an error if there is an error during the confirm logic for a user" {
                    { Confirm-ADObjectDCReplication -ADObject $TestPresetParams.UserName -Type "User" -MaxWait 1 } | Should -Not -Throw
                }

                It "Should not throw an error if there is an error during the confirm logic for a group" {
                    { Confirm-ADObjectDCReplication -ADObject $TestPresetParams.Group -Type "Group" -MaxWait 1 } | Should -Not -Throw
                }

                It "Should not throw an error if there is an error during the confirm logic for an OU" {
                    { Confirm-ADObjectDCReplication -ADObject $TestPresetParams.OU -Type "OU" -MaxWait 1 } | Should -Not -Throw
                }

                It "Should not throw an error if there is an error during the confirm logic for an unknown object" {
                    { Confirm-ADObjectDCReplication -ADObject "SomethingUnknown" -Type "Unknown" -MaxWait 1 } | Should -Not -Throw
                }
            }
        }
    }
}
catch {
    $Error[0]
}
