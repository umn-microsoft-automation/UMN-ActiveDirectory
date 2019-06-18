# PSake makes variables declared here available in other scriptblocks
Properties {
    # Find the build folder based on build system
    $ProjectRoot = $env:BHProjectPath
    $ModuleRoot = $env:BHModulePath
    $ModuleName = $env:BHProjectName

    if(-not $ProjectRoot) {
        $ProjectRoot = Resolve-Path "$PSScriptRoot\.."
    }

    $Timestamp = Get-Date -UFormat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$Timestamp.xml"
    $CodeCoverageFile = "CodeCoverage_PS$PSVersion`_$Timestamp.xml"
    $Lines = '----------------------------------------------------------------------'

    [hashtable]$Verbose = @{}
    if($env:BHCommitMessage -match "!verbose") {
        $Verbose = @{ 'Verbose' = $true }
    }
}

Task Default -Depends Test

Task Init {
    $Lines
    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item env:BH*
    "`n"
}

Task Test -Depends Init {
    $Lines
    "`n`tSTATUS: Testing with Powershell $PSVersion"

    # Testing links on GitHub requires tls >= 1.2
    $SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Warning "Project Root: $ProjectRoot"
    Write-Warning "Module Root: $ModuleRoot"
    Write-Warning "Module Name: $ModuleName"

    if($env:BHCommitMessage -notmatch "!skipcodecoverage") {
        $CodeToCheck = Get-ChildItem $ModuleRoot -Include *.ps1, *.psm1 -Recurse
        $CodeCoverageParams = @{
            "CodeCoverageOutputFile" = "$ProjectRoot\Build\$CodeCoverageFile"
            "CodeCoverage" = $CodeToCheck
        }
    } else {
        $CodeCoverageParams = @{}
    }

    Import-Module $ModuleRoot

    # Gather test results. Store them in a variable and file
    $TestResults = Invoke-Pester -Path "$ProjectRoot\Tests" -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\Build\$TestFile" @CodeCoverageParams @Verbose
    [Net.ServicePointManager]::SecurityProtocol = $SecurityProtocol

    # In Appveyor?  Upload our tests!
    if($env:BHBuildSystem -eq 'AppVeyor') {
        (New-Object 'System.Net.WebClient').UploadFile(
            "https://ci.appveyor.com/api/testresults/nunit/$($env.APPVEYOR_JOB_ID)",
            "$ProjectRoot\Build\$TestFile"
        )
    }

    # Put code for Azure Pipelines in here
    if($env:BHBuildSystem -eq 'Azure Pipelines') {

    }

    # Put code for 'Unknown' systems here
    if($env:BHBuildSystem -eq 'Unknown') {
        
    }

    # Failed Tests?
    # Need to tell psake or it will proceed to the deployment.
    if($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed."
    }

    "`n"
}