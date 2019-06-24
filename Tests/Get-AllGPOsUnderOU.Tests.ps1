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

        Describe "Get-AllGPOsUnderOU" {
            Context "Should pass back a valid result if given good info" {
                Mock -CommandName Get-GPO -MockWith { return [PSCustomObject]$FakeGPO }
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject]$FakeADOU }

                $Return = Get-AllGPOsUnderOU -SearchBase $TestPresetParams.OU

                It "Should return an object with the guid and GPO" {
                    $Return.Guid | Should -Be "{$($TestPresetParams.GPOGuid)}"
                }

                It "Should return a GPO with the right name based on the guid" {
                    $Return.GPO.DisplayName | Should -Be $TestPresetParams.GPOName
                }

                It "Should return a GPO with the right domain name" {
                    $Return.GPO.DomainName | Should -Be $TestPresetParams.DomainName
                }

                It "Should return a GPO with the right owner" {
                    $Return.GPO.Owner | Should -Be $TestPresetParams.UserName
                }

                It "Should have matching guids" {
                    "{$($Return.GPO.Id)}" -eq $Return.Guid | Should -Be $true
                }

                It "Should make one call to Get-GPO" {
                    Assert-MockCalled -CommandName Get-GPO -Times 1 -Exactly
                }

                It "Should make one call to Get-ADOrganizationalUnit" {
                    Assert-MockCalled -CommandName Get-ADOrganizationalUnit -Times 1 -Exactly
                }
            }

            Context "Should return errors when issues arise" {
                It "Should error when there are issues with the Get-GPO call" {
                    Mock -CommandName Get-GPO -MockWith { throw "error" }
                    Mock -CommandName Get-ADOrganizationalUnit -MockWith { return [PSCustomObject]$FakeADOU }
                    
                    { Get-AllGPOsUnderOU -SearchBase $TestPresetParams.OU } | Should -Throw
                }

                It "Should error when there are issues with the Get-ADOrganizationalUnit call" {
                    Mock -CommandName Get-GPO -MockWith { return [PSCustomObject]$FakeGPO }
                    Mock -CommandName Get-ADOrganizationalUnit -MockWith { throw "error" }

                    { Get-AllGPOsUnderOU -SearchBase $TestPresetParams.OU } | Should -Throw
                }
            }

            Context "Duplicate GPO behavior" {
                Mock -CommandName Get-GPO -MockWith { return [PSCustomObject]$FakeGPO }
                Mock -CommandName Get-ADOrganizationalUnit -MockWith { return @([PSCustomObject]$FakeADOU, [PSCustomObject]$FakeADOU2) }

                $VerboseOutput = Get-AllGPOsUnderOU -SearchBase $TestPresetParams.OU -Verbose 4>&1

                It "Should write verbose that it added the first GPO" {
                    $VerboseOutput[0] | Should -Be "Adding new item: {$($TestPresetParams.GPOGuid)}"
                }

                It "Should write verbose that it skipped the second GPO" {
                    $VerboseOutput[1] | Should -Be "Skipping already existing item: {$($TestPresetParams.GPOGuid)}"
                }
            }
        }
    }
}
catch {
    $Error[0]
}
