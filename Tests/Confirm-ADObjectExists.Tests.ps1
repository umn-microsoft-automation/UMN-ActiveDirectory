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

        Describe "Confirm-ADObjectExists" {
            Mock -CommandName Get-ADDomainController -MockWith {
                return [PSCustomObject]@{
                    HostName = "DC1"
                }
            }

            Context "Successfully found object" {
                Mock -CommandName Get-ADComputer -MockWith { return [PSCustomObject]$FakeADComputer }
                Mock -CommandName Get-ADUser -MockWith { return [PSCustomObject]$FakeADUser }
                Mock -CommandName Get-ADGroup -MockWith { return [PSCustomObject]$FakeADGroup }
                Mock -CommandName Get-ADOrganizationalUnit { return [PSCustomObject]$FakeADOU }
                Mock -CommandName Get-ADObject -MockWith { return [PSCustomObject]$FakeADComputer }

                It "Should return true if given a computer that exists" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.ComputerName -Type "Computer" | Should -Be $true
                }

                It "Should return true if given a user that exists" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.UserName -Type "User" | Should -Be $true
                }

                It "Should return true if given a group that exists" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.Group -Type "Group" | Should -Be $true
                }

                It "Should return true if given an OU that exists" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.OU -Type "OU" | Should -Be $true
                }

                It "Should return true if given an unknown object that exists" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.ComputerName -Type "Unknown" | Should -Be $true
                }
            }

            Context "Failure to find object" {
                Mock -CommandName Get-ADComputer -MockWith { return $null }
                Mock -CommandName Get-ADUser -MockWith { return $null }
                Mock -CommandName Get-ADGroup -MockWith { return $null }
                Mock -CommandName Get-ADOrganizationalUnit { return $null }
                Mock -CommandName Get-ADObject -MockWith { return $null }

                It "Should return false if given a computer that doesn't exist" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.ComputerName -Type "Computer" | Should -Be $false
                }

                It "Should return false if given a user that doesn't exist" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.UserName -Type "User" | Should -Be $false
                }

                It "Should return false if given a group that doen't exist" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.Group -Type "Group" | Should -Be $false
                }

                It "Should return false if given an OU that doesn't exist" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.OU -Type "OU" | Should -Be $false
                }

                It "Should return false if given an unknown object that doesn't exist" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.ComputerName -Type "Unknown" | Should -Be $false
                }
            }

            Context "Error handling on AD calls" {
                Mock -CommandName Get-ADComputer -MockWith { throw "error" }
                Mock -CommandName Get-ADUser -MockWith { throw "error" }
                Mock -CommandName Get-ADGroup -MockWith { throw "error" }
                Mock -CommandName Get-ADOrganizationalUnit { throw "error" }
                Mock -CommandName Get-ADObject -MockWith { throw "error" }

                It "Should throw an error if triggered by a computer" {
                    { Confirm-ADObjectExists -Identity $TestPresetParams.ComputerName -Type "Computer" } | Should -Throw
                }

                It "Should throw an error if triggered by a user" {
                    { Confirm-ADObjectExists -Identity $TestPresetParams.UserName -Type "User" } | Should -Throw
                }

                It "Should throw an error if triggered by a group" {
                    { Confirm-ADObjectExists -Identity $TestPresetParams.Group -Type "Group" } | Should -Throw
                }

                It "Should throw an error if triggered by an OU" {
                    { Confirm-ADObjectExists -Identity $TestPresetParams.OU -Type "OU" } | Should -Throw
                }

                It "Should throw an error if triggered by an unknown object" {
                    { Confirm-ADObjectExists -Identity $TestPresetParams.ComputerName -Type "Unknown" } | Should -Throw
                }
            }

            Context "AD Functions should be called" {
                Mock -CommandName Get-ADComputer -MockWith { return [PSCustomObject]$FakeADComputer }
                Mock -CommandName Get-ADUser -MockWith { return [PSCustomObject]$FakeADUser }
                Mock -CommandName Get-ADGroup -MockWith { return [PSCustomObject]$FakeADGroup }
                Mock -CommandName Get-ADOrganizationalUnit { return [PSCustomObject]$FakeADOU }
                Mock -CommandName Get-ADObject -MockWith { return [PSCustomObject]$FakeADComputer }

                It "Should return true if given a computer that exists" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.ComputerName -Type "Computer"

                    Assert-MockCalled -CommandName Get-ADComputer -Times 1 -Exactly
                }

                It "Should return true if given a user that exists" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.UserName -Type "User"

                    Assert-MockCalled -CommandName Get-ADUser -Times 1 -Exactly
                }

                It "Should return true if given a group that exists" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.Group -Type "Group"

                    Assert-MockCalled -CommandName Get-ADGroup -Times 1 -Exactly
                }

                It "Should return true if given an OU that exists" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.OU -Type "OU"

                    Assert-MockCalled -CommandName Get-ADOrganizationalUnit -Times 1 -Exactly
                }

                It "Should return true if given an unknown object that exists" {
                    Confirm-ADObjectExists -Identity $TestPresetParams.ComputerName -Type "Unknown"

                    Assert-MockCalled -CommandName Get-ADObject -Times 1 -Exactly
                }
            }
        }
    }
} catch {
    $Error[0]
}