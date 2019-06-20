<#
		.SYNOPSIS
		Cmdlet that returns true if the object exists and false if it doesn't.
		
		.DESCRIPTION
		A cmdlet that take in the identity of an object, an object type and an optional server and then returns true or false if the object exists.
		
		.PARAMETER Identity
		A string representing the object, can be a DN, GUID, sAMAccountName or SID.
		
		.PARAMETER Type
		The type of object being tested.  The unknwon identity simply uses Get-ADObject rather than an object specific locator.
		
		.PARAMETER Server
		A domain controller which can be used to see if the item exists on a specific domain controller.
		
		.EXAMPLE
		Confirm-ADObjectExists -Identity "FooBar" -Type "Computer" -Server (Get-ADDomainController).HostName
		
		.EXAMPLE
		Confirm-ADObjectExists -Identity "foobar" -Type "User"
		
		.EXAMPLE
		Confirm-ADObjectExists -Identity "S-1-5-1-5125-16836816-12512325" -Type "Group"
		
		.EXAMPLE
		Confirm-ADObjectExists -Identity "CN=Foo,CN=Bar,DC=domain,DC=acme,DC=com" -Type "OU"
	#>
function Confirm-ADObjectExists {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, HelpMessage="Enter in a valid object identity")][string]$Identity,
		[Parameter(Mandatory=$true, HelpMessage="Enter in a valid object type.")][ValidateSet("Computer", "User", "Group", "OU", "Unknown")][string]$Type,
		[Parameter(Mandatory=$false, HelpMessage="Enter in a valid domain controller.")][string]$Server=(Get-ADDomainController).HostName
	)
	$ErrorActionPreference = "SilentlyContinue"
	Write-Verbose -Message "$Server"
	try {
		if($Type -eq "Computer") {
			Write-Verbose -Message "Computer object test: $Identity"
			$ADObject = Get-ADComputer -Identity $Identity -Server $Server
		} elseif($Type -eq "User") {
			Write-Verbose -Message "User object test: $Identity"
			$ADObject = Get-ADUser -Identity $Identity -Server $Server
		} elseif($Type -eq "Group") {
			Write-Verbose -Message "Group object test: $Identity"
			$ADObject = Get-ADGroup -Identity $Identity -Server $Server
		} elseif($Type -eq "OU") {
			Write-Verbose -Message "OU object test: $Identity"
			$ADObject = Get-ADOrganizationalUnit -Identity $Identity -Server $Server
		} elseif($Type -eq "Unknown") {
			Write-Verbose -Message "Unknown object test: $Identity"
			$ADObject = Get-ADObject -Filter {(
				DistinguishedName -eq $Identity) -or (
				ObjectGUID -eq $Identity) -or (
				objectSID -eq $Identity) -or (
				SamAccountName -eq $Identity)
			} -Server $Server
		}
	} catch {
		throw $_
	}
	
	if ($ADObject) {
		return $true
	}
	else {
		return $false
	}
}