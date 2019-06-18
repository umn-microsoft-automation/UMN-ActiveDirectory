<#
	.SYNOPSIS
		Checks a GPO to see if the WiFi profiles have a specific server name. Ultimately, is a reference
        on how to check for a setting in a GPO.
	.DESCRIPTION
		Takes in a GPO and server name and then determines if the WiFi profiles have the specific server name.
	.EXAMPLE
		Test-GPOWiFiServerName -GPO (Get-GPO -Name "This-Is-A-Test") -ServerName "wifiauth.domain.com"
	.PARAMETER GPOXml
		Group policy xml obtained by running Get-GPO -Name "Name" | Get-GPOReport -ReportType Xml
	.PARAMETER ServerName
		String for the server name to look for.
#>
function Test-GPOWiFiServerName {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[xml]$GPOXml,

		[Parameter(Mandatory=$true)]
		[string]$ServerName
	)
	process {
		$NamespaceManager = New-Object System.Xml.XmlNamespaceManager($GPOXml.NameTable)
		$NamespaceManager.AddNamespace("root", "http://www.microsoft.com/GroupPolicy/Settings")
		$GPOSettings = [array]$GPOXml.SelectNodes("//root:Extension", $NamespaceManager)

		$Profiles = $GPOSettings.WLanSvcSetting.WLanPolicies.profileList.WLANProfile

		$ReturnObject = New-Object -TypeName System.Collections.ArrayList

		foreach($Profile in $Profiles) {
			$ServerNames = $Profile.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.ServerValidation.ServerNames
			$ProfileSSID = $Profile.SSIDConfig.SSID.name
			if($ServerNames -ne $ServerName) {
				$ProfileUpdated = $false
				Write-Verbose -Message "$($GPO.DisplayName) has $ProfileSSID which is not updated."
			} else {
				$ProfileUpdated = $true
				Write-Verbose -Message "$($GPO.DisplayName) has $ProfileSSID which is updated."
			}

			$PSObject = New-Object -TypeName psobject
			$PSObject | Add-Member -MemberType NoteProperty -Name "GPOName" -Value $GPO.DisplayName
			$PSObject | Add-Member -MemberType NoteProperty -Name "ProfileSSID" -Value $ProfileSSID
			$PSObject | Add-Member -MemberType NoteProperty -Name "ServerNames" -Value $ServerNames
			$PSObject | Add-Member -MemberType NoteProperty -Name "ProfileUpdated" -Value $ProfileUpdated
			$null = $ReturnObject.Add($PSObject)
		}

		return $ReturnObject
	}
}