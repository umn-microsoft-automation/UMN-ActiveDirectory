param ($Task = 'Default')

# Grab nuget bits, install modules, set build variables, start build.

# Make sure package provider is installed (required for Docker support)
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Pester is already installed, need to skip this check.
Install-Module -Name Pester -Force -SkipPublisherCheck

Install-Module Psake, PSDeploy, BuildHelpers -Force
Import-Module Psake, BuildHelpers

(Get-ChildItem).FullName | Write-Warning

Set-BuildEnvironment

Invoke-Psake -BuildFile .\Build\psake.ps1 -TaskList $Task -NoLogo

exit ([int]( -not $psake.build_success))
