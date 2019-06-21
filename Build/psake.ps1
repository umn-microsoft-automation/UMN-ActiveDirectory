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

Task Default -Depends Build

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

Task Build -Depends Test {
    $Lines
    Set-ModuleFunctions

    if(-not (Test-Path -Path $env:GHBuildOutput)) {
        New-Item $env:BHBuildOutput -Force -ItemType Directory
    }

    $AzureDevOpsCredentialPair = "$($env:PROJECT_PUBUSER):$($env:PROJECT_PUBKEY)"

    $EncodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($AzureDevOpsCredentialPair))
    $Headers = @{
        "Authorization" = "Basic $EncodedCredentials"
    }

    try {
        $DevOpsPackages = Invoke-RestMethod -Headers $Headers -Method Get -Uri "https://feeds.dev.azure.com/umn-microsoft/_apis/Packaging/Feeds/UMN-Internal/packages?api-version=5.0-preview.1"

        $UMNActiveDirectoryInfo = $DevOpsPackages | Where-Object -FilterScript { $_.normalizedName -eq "UMN-ActiveDirectory" }

        $UMNActiveDirectoryPkg = Invoke-RestMethod -Headers $Headers -Method Get -Uri "https://feeds.dev.azure.com/umn-microsoft/_apis/packaging/Feeds/UMN-Internal/packages/$($UMNActiveDirectoryInfo.id)?api-version=5.0-preview.1"

        [System.Version]$AzureDevOpsVersion = [System.Version]$UMNActiveDirectoryPkg.value.versions.version

        if($null -eq $AzureDevOpsVersion) {
            Write-Warning -Message "Null Version Detected"
            [System.Version]$AzureDevOpsVersion = "0.0.1"
        }
    } catch {
        Write-Warning -Message "No DevOps version found or there were issues"
        [System.Version]$AzureDevOpsVersion = "0.0.1"
    }

    try {
        [System.Version]$GalleryVersion = Get-NextNugetPackageVersion -Name $env:GHProjectName -ErrorAction Stop
    } catch {
        Write-Warning -Message "Failed to update gallery version for '$env:BHProjectName': $_.`nContinuing with existing version"
    }

    try {
        [System.Version]$GitHubVersion = Get-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -ErrorAction Stop
    } catch {
        Write-Warning -Message "Failed to update GitHub version for '$env:BHProjectName': $_`nContinuing with existing version"
    }

    Write-Host "---"
    Write-Host "GalleryVersion = $($GalleryVersion.ToString())"
    Write-Host "AzureDevOpsVersion = $($AzureDevOpsVersion.ToString())"
    Write-Host "GitHubVersion = $($GitHubVersion.ToString())"
    Write-Host "---"

    if(($GalleryVersion -ge $GitHubVersion) -and ($GalleryVersion -ge $AzureDevOpsVersion)) {
        $NewVersion = New-Object System.Version ($GalleryVersion.Major, $GalleryVersion.Minor, ($GalleryVersion.Build + 1))
    } elseif($GitHubVersion -ge $AzureDevOpsVersion) {
        $NewVersion = New-Object System.Version ($GitHubVersion.Major, $GitHubVersion.Minor, $GitHubVersion.Build)
    } else {
        $NewVersion = New-Object System.Version ($AzureDevOpsVersion.Major, $AzureDevOpsVersion.Minor, ($AzureDevOpsVersion.Build + 1))
    }

    Write-Warning -Message "NewVersion = $($NewVersion.ToString())"

    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName "ModuleVersion" -Value $NewVersion -ErrorAction Stop
    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName "RequiredModules" -Value @("ActiveDirectory") -ErrorAction Stop

    Register-PSRepository -Name "LocalPSRepo" -SourceLocation "$env:BUILD_SOURCESDIRECTORY\BuildOutput" -PublishLocation "$env:BUILD_SOURCESDIRECTORY\BuildOutput" -InstallationPolicy Trusted
    nuget.exe sources Add -Name "LocalPSRepo" -Source "$env:BUILD_SOURCESDIRECTORY\BuildOutput"

    Publish-Module -Path $env:BHModulePath -Repository "LocalPSRepo" -NuGetApiKey "AzureDevOps" -Verbose
}