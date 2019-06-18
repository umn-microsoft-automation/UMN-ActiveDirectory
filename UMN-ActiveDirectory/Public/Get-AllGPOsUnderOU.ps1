<#
	.SYNOPSIS
		Takes in a base OU and then grabs all the unique group policies linked under the OU.
	.DESCRIPTION
		Give this function an OU and it looks through the OU and sub OU's and gets all the unique GPOs.
	.EXAMPLE
		Get-AllGPOsUnderOU -SearchBase ="OU=Test,DC=ad,DC=contoso,DC=.com"
	.PARAMETER SearchBase
		Distingusihed Name of the top level OU to start searching for group policies in.
	.OUTPUTS
		ArrayList of all the GPO objects.
#>
function Get-AllGPOsUnderOU {
	[CmdletBinding()]
	[OutputType([System.Collections.ArrayList])]
	param (
		[Parameter(Mandatory=$true)]
		[string]$SearchBase
	)
	process {
		$ReturnObject = New-Object -ComObject System.Collections.ArrayList
		$GPOs = Get-ADOrganizationalUnit -SearchBase $SearchBase -Filter * | Select-Object -ExpandProperty "LinkedGroupPolicyObjects" -Unique

		foreach($GPO in $GPOs) {
			foreach($GPO in $GPOs) {
				$GPOInfo = [adsi]"LDAP://$GPO" | Select-Object DisplayName
				$ReturnObject -eq $null
				if($ReturnObject.Count -eq 0) {

					Write-Verbose -Message "Added: $($GPOInfo.DisplayName.ToString())"
					$ReturnObject.Add((Get-GPO -Name $GPOInfo.DisplayName.ToString()))

				} elseif(-not $ReturnObject.DisplayName.Contains($GPOInfo.DisplayName.ToString())) {

					Write-Verbose -Message "Added: $($GPOInfo.DisplayName.ToString())"
					$ReturnObject.Add((Get-GPO -Name $GPOInfo.DisplayName.ToString()))

				} else {
					Write-Verbose -Message "Duplicate: $($GPOInfo.DisplayName.ToString())"
				}
			}
		}

		return $ReturnObject
	}
}