<#
		.SYNOPSIS
		Cmdlet that returns true if the object exists on all domain controllers within the domain and false if it doesn't.
		
		.DESCRIPTION
		A cmdlet that take in the identity of an object, an object type and an optional maximum wait time (default is 30 seconds)
        to determine if that object exists on all domain controllers within a domain. The script tries once each second up until
        thte maximum wait time is reached before returning a false if not all domain controllers return true.
		
		.PARAMETER ADObject
		A string representing the object, can be a DN, GUID, sAMAccountName or SID.
		
		.PARAMETER Type
		The type of object being tested.  The unknwon identity simply uses Get-ADObject rather than an object specific locator.
		
		.PARAMETER MaxWait
		The maximum time to wait in seconds before determining that the object does not exist on all domain controllers.
		
		.EXAMPLE
		Confirm-ADObjectDCReplication -ADObject "FooBar" -Type "Computer" -MaxWait 5
		
		.EXAMPLE
		Confirm-ADObjectDCReplication -ADObject "foobar" -Type "User"
		
		.EXAMPLE
		Confirm-ADObjectDCReplication -ADObject "S-1-5-1-5125-16836816-12512325" -Type "Group"
		
		.EXAMPLE
		Confirm-ADObjectDCReplication -ADObject "CN=Foo,CN=Bar,DC=domain,DC=acme,DC=com" -Type "OU"
	#>
function Confirm-ADObjectDCReplication {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)][string]$ADObject,
		[Parameter(Mandatory=$true)][ValidateSet("Computer", "User", "Group", "OU", "Unknown")][string]$Type,
		[Parameter(Mandatory=$false)][int]$MaxWait=30
	)

	$DomainControllers = New-Object System.Collections.ArrayList
	$GoodServers = New-Object System.Collections.ArrayList

	$Count = 1

	try {
		# Get the list of domain controllers to check
		$null = Get-ADDomainController -Filter * | Foreach-Object { $DomainControllers.Add($_.HostName) }

		while(($Count -le $MaxWait) -and ($DomainControllers)) {
			# Walk through each DC and identify the DC's that see the AD object
			$DomainControllers | Foreach-Object {
				if(Confirm-ADObjectExists -Identity $ADObject -Server $_ -Type $Type) {
					$null = $GoodServers.Add($_)
				}
			}

			# Remove the DC's that already see the AD object from the list of DC's to check

			$GoodServers | Foreach-Object {
				$DomainControllers.Remove($_)
			}

			$null = Start-Sleep -Seconds 1

			$Count++
		}

		if(-not ($DomainControllers)) {
			return $true
		} else {
			return $false
		}
	} catch {
		throw $_
	}
}