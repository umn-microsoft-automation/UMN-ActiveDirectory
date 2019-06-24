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
		ArrayList of all the guids and GPO objects.
#>
function Get-AllGPOsUnderOU {
	[CmdletBinding()]
	[OutputType([System.Collections.ArrayList])]
	param (
		[Parameter(Mandatory=$true)]
		[string]$SearchBase
	)
	process {
		[System.Collections.ArrayList]$ReturnObject = @()

		$GPOs = Get-ADOrganizationalUnit -SearchBase $SearchBase -Filter * | Select-Object -ExpandProperty "LinkedGroupPolicyObjects" -Unique

		foreach($GPO in $GPOs) {
			$GPOGuid = $GPO | Select-String -Pattern "\{(.*?)\}" | ForEach-Object { $_.Matches.Groups[0].Value }
			try {
				if($ReturnObject.Guid -notcontains $GPOGuid) {
					Write-Verbose -Message "Adding new item: $GPOGuid"

					$GPOInfo = Get-GPO -Guid $GPOGuid

					$null = $ReturnObject.Add([PSCustomObject]@{
						"Guid" = $GPOGuid
						"GPO" = $GPOInfo
					})
				} else {
					Write-Verbose -Message "Skipping already existing item: $GPOGuid"
				}
			} catch {
				throw $_
			}
		}

		return $ReturnObject
	}
}
