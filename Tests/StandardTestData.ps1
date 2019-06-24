# Load any additional data from external files
if($ModuleRoot) {
    [xml]$FakeWiFiprofileXML = Get-Content -Path "$ModuleRoot..\Tests\WiFiXMLExample.xml"
} else {
    if(Test-Path -Path "StandardTestData.ps1") {
        [xml]$FakeWiFiProfileXML = Get-Content .\WiFiXMLExample.xml
    } elseif(Test-Path -Path "Tests\StandardTestData.ps1") {
        [xml]$FakeWiFiProfileXML = Get-Content -Path .\Tests\WiFiXMLExample.xml
    } else {
        throw "Error importing WiFiXMLExample.xml"
    }
}

$TestPresetParams = @{
    "DomainName"      = "contoso.com"
    "UserName"        = "TestUser"
    "Group"           = "TestGroup"
    "AddGroup"        = "TestLocalGroup"
    "ComputerName"    = "TestComputer"
    "OperatingSystem" = "Windows 10 Enterprise"
    "OU"              = "OU=TestOU,DC=contoso,DC=com"
    "OU2"             = "OU=TestOU2,OU=TestOU,DC=contoso,DC=com"
    "OUName"          = "TestOU"
    "OU2Name"         = "TestOU2"
    "GPOName"         = "TestGPO"
    "GPOGuid"         = [Guid]::NewGuid()
}

$FakeADUser = @{
    "DistinguishedName" = "CN=$($TestPresetParams.UserName),CN=Users,DC=contoso,DC=com"
    "Enabled"           = $true
    "Name"              = $TestPresetParams.UserName
    "SamAccountName"    = $TestPresetParams.UserName
}

$FakeADGroup = @{
    "DistinguishedName" = "CN=$($TestPresetParams.Group),CN=Groups,DC=contoso,DC=com"
    "Enabled"           = $true
    "Name"              = $TestPresetParams.Group
    "SamAccountName"    = $TestPresetParams.Group
}

$FakeADComputer = @{
    "DistinguishedName" = "CN=$($TestPresetParams.ComputerName),CN=Computers,DC=contoso,DC=com"
    "Enabled"           = $true
    "Name"              = $TestPresetParams.ComputerName
    "SamAccountName"    = $TestPresetParams.ComputerName
    "OperatingSystem"   = $TestPresetParams.OperatingSystem
}

$FakeADOU = @{
    "DistinguishedName"        = $TestPresetParams.OU
    "Name"                     = $TestPresetParams.OUName
    "LinkedGroupPolicyObjects" = "cn={$($TestPresetParams.GPOGuid)},cn=policies,cn=system,DC=contoso,DC=com"
}

$FakeADOU2 = @{
    "DistinguishedName"        = $TestPresetParams.OU2
    "Name"                     = $TestPresetParams.OU2Name
    "LinkedGroupPolicyObjects" = "cn={$($TestPresetParams.GPOGuid.ToString().ToUpper())},cn=policies,cn=system,DC=contoso,DC=com"
}

$FakeGPO = @{
    "DisplayName" = $TestPresetParams.GPOName
    "DomainName"  = $TestPresetParams.DomainName
    "Owner"       = $TestPresetParams.UserName
    "Id"          = $TestPresetParams.GPOGuid
}

$FakeADDomainController = @{
    "HostName" = "DC1"
}

function Get-ADDomainController { return [PSCustomObject]$FakeADDomainController }
function Get-ADComputer { return [PSCustomObject]$FakeADComputer }
function Get-ADUser { return [PSCustomObject]$FakeADUser }
function Get-ADGroup { return [PSCustomObject]$FakeADGroup }
function Get-ADOrganizationalUnit { return [PSCustomObject]$FakeADOU }
function Get-ADObject { return [PSCustomObject]$FakeADComputer }
function Get-GPO { return [PSCustomObject]$FakeGPO }
