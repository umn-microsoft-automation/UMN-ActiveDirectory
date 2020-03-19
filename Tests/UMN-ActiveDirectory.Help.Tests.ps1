$TestConfig = @{
    "TestModuleName" = "UMN-ActiveDirectory"
}

try {
    if ($ModuleRoot) {
        Import-Module (Join-Path $ModuleRoot "$($TestConfig.TestModuleName).psd1") -Force
    }
    else {
        if (Test-Path -Path ..\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1) {
            Import-Module ..\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1 -Force    
        }
        elseif (Test-Path -Path .\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1) {
            Import-Module .\$($TestConfig.TestModuleName)\$($TestConfig.TestModuleName).psd1 -Force
        }
    }
    Describe "Help tests for $($TestConfig.TestModuleName)" -Tags 'Build' {
    
        $functions = Get-Command -Module $($TestConfig.TestModuleName) -CommandType Function
        foreach ($Function in $Functions) {
            $help = Get-Help $Function.name
            Context $help.name {
                #it "Has a HelpUri" {
                #    $Function.HelpUri | Should Not BeNullOrEmpty
                #}
                #It "Has related Links" {
                #    $help.relatedLinks.navigationLink.uri.count | Should BeGreaterThan 0
                #}
                it "Has a description" {
                    $help.description | Should Not BeNullOrEmpty
                }
                it "Has an example" {
                    $help.examples | Should Not BeNullOrEmpty
                }
                foreach ($parameter in $help.parameters.parameter) {
                    if ($parameter -notmatch 'whatif|confirm') {
                        it "Has a Parameter description for '$($parameter.name)'" {
                            $parameter.Description.text | Should Not BeNullOrEmpty
                        }
                    }
                }
            }
        }
    }
}
catch {
    $Error[0]
}
