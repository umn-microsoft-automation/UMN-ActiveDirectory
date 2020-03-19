@{
    RootModule        = 'UMN-ActiveDirectory.psm1'
    ModuleVersion     = '2.0.0'
    GUID              = 'cc63303c-9fa4-41b6-803a-0b55499995a4'
    Author            = 'Travis Sobeck, Jeff Bolduan'
    CompanyName       = 'University of Minnesota'
    Copyright         = '(c) 2020 University of Minnesota. All rights reserved.'
    Description       = 'Powershell module with functions to interact with Active Directory'
    PowerShellVersion = '5.0'
    FunctionsToExport = '*'
    CmdletsToExport   = '*'
    VariablesToExport = '*'
    AliasesToExport   = '*'
    PrivateData       = @{
        PSData = @{
            Tags                       = @('Automation', 'Windows', 'Active Directory', 'AD', 'UMN')
            LicenseUri                 = 'https://github.com/umn-microsoft-automation/UMN-ActiveDirectory/blob/master/LICENSE'
            ProjectUri                 = 'https://github.com/umn-microsoft-automation/UMN-ActiveDirectory'
            # IconUri                  = ''
            ReleaseNotes               = 'Added funtion Get-OS (returnst OS of a given computer object)'
            ExternalModuleDependencies = @('ActiveDirectory')
        }
    }
}
