﻿$TestConfig = @{
    "TestModuleName" = "UMN-ActiveDirectory"
}
try {
    if ($ModuleRoot) {
        Import-Module (Join-Path $ModuleRoot "$ModuleName.psd1") -Force
    }
    else {
        if (Test-Path -Path ..\UMN-ActiveDirectory\UMN-ActiveDirectory.psd1) {
            Import-Module ..\UMN-ActiveDirectory\UMN-ActiveDirectory.psd1 -Force    
        }
        elseif (Test-Path -Path .\UMN-ActiveDirectory\UMN-ActiveDirectory.psd1) {
            Import-Module .\UMN-ActiveDirectory\UMN-ActiveDirectory.psd1
        }
    }

    # Module scope fixes problems with AD mocking.  It needs to be hre to fix issues with running
    # tests on devices without AD module installed.
    InModuleScope -ModuleName $TestConfig.TestModuleName {
        $TestPresetParams = @{
            "DomainName" = "contoso.com"
            "UserName"   = "TestUser"
            "Group"      = "TestGroup"
            "AddGroup"   = "TestLocalGroup"
        }

        $FakeADUser = @{
            "DistinguishedName"     = "CN=$($TestPresetParams.UserName),CN=Users,DC=contoso,DC=com"
            "Enabled"               = $true
            "GivenName"             = ""
            "Name"                  = $TestPresetParams.UserName
            "SamAccountName"        = $TestPresetParams.UserName
            "Surname"               = ""
            "UserPrincipalName"     = ""
            "ServicePrincipalNames" = @("spn/a", "spn/b")
        }

        $FakeADGroup = @{
            "DistingusihedName" = "CN=$($TestPresetParams.Group),CN=Groups,DC=contoso,DC=com"
            "Enabled"           = $true
            "Name"              = $TestPresetParams.Group
            "SamAccountName"    = $TestPresetParams.Group
        }

        function Get-ADUser {
            [cmdletbinding()]
            param(
                [string]$Identity
            )
            return [PSCustomObject]$FakeADUser
        }
        
        function Get-ADGroup {
            [cmdletbinding()]
            param(
                [string]$Identity
            )
            return [PSCustomObject]$FakeADUser
        }

        Describe "Add-MembersLocalGroup" {
            Context "Adding to local group" {
                Mock -CommandName Get-ADUser -MockWith { return [PSCustomObject]$FakeADUser }
                Mock -CommandName Get-ADGroup -MockWith { return [PSCustomObject]$FakeADGroup }
                Mock -CommandName Add-LocalGroupMember -MockWith { return $true }

                It "Should call Get-ADUser once when running with User paramset" {
                    Mock -CommandName Get-MembersLocalGroup -MockWith { return $TestPresetParams.UserName }
                    Add-MembersLocalGroup -GroupToAddTo $TestPresetParams.AddGroup -Computer $env:COMPUTERNAME -User $TestPresetParams.UserName -ADDomain $TestPresetParams.DomainName

                    Assert-MockCalled -CommandName Get-ADUser -Times 1 -Exactly -Scope It
                }

                It "Should call Get-ADGroup once when running with Group paramset" {
                    Mock -CommandName Get-MembersLocalGroup -MockWith { return $TestPresetParams.Group }
                    Add-MembersLocalGroup -GroupToAddTo $TestPresetParams.AddGroup -Computer $env:COMPUTERNAME -Group $TestPresetParams.Group -ADDomain $TestPresetParams.DomainName

                    Assert-MockCalled -CommandName Get-ADGroup -Times 1 -Exactly -Scope It
                }

                It "Should throw an error if not passed user/group" {
                    { Add-MembersLocalGroup -GroupToAddTo $TestPresetParams.AddGroup -Computer $env:COMPUTERNAME -ADDomain $TestPresetParams.DomainName } | Should -Throw
                }

                It "Should throw an error if the user wasn't added to the local group" {
                    Mock -CommandName Get-MembersLocalGroup -MockWith { return $false }
                    
                    { Add-MembersLocalGroup -GroupToAddTo $TestPresetParams.AddGroup -Computer $env:COMPUTERNAME -Group $TestPresetParams.Group -ADDomain $TestPresetParams.DomainName } | Should -Throw
                }
            }
        }
    }
}
catch {
    $Error[0]
}