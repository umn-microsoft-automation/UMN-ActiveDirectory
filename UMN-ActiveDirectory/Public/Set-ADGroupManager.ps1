<#
	.Synopsis
		Sets manager property on AD group and grants change membership rights.
	.DESCRIPTION
		Sets manager property on AD group and grants change membership rights.
		This is done by manipulating properties directly on the DirectoryEntry object
		obtained with ADSI. This sets the managedBy property and adds an ACE to the DACL
		allowing said manager to modify group membership.
		Taken from: https://mcardletech.com/blog/setting-ad-group-managers-with-powershell/
	.EXAMPLE
		Set-GroupManager -ManagerDN "CN=some manager,OU=All Users,DC=Initech,DC=com" -GroupDN "CN=TPS Reports Dir,OU=All Groups,DC=Initech,DC=com"
	.EXAMPLE
		(Get-AdGroup -Filter {Name -like "sharehost - *"}).DistinguishedName | % {Set-GroupManager "CN=some manager,OU=All Users,DC=Initech,DC=com" $_}
	.PARAMETER ManagerDN
		The distinguished name for the manager group.
	.PARAMETER GroupDN
		The distinguished name for the group to be managed.
	.PARAMETER TargetDC
		The domain controller to target the change on.  If left blank will be pulled from Get-ADDomainController
#>
function Set-ADGroupManager {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$false,
			ValueFromPipelineByPropertyName=$true,
			Position=0)]
		[string]$ManagerDN,
		
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$false,
			ValueFromPipelineByPropertyName=$true,
			Position=1)]
		[string]$GroupDN,
		
		[Parameter(Mandatory=$false,
			ValueFromPipeline=$false,
			ValueFromPipelineByPropertyName=$true,
			Position=2)]
		[string]$TargetDC=(Get-ADDomainController).HostName
	)
	$ErrorActionPreference = "Stop"
	try {
		Write-Verbose -Message "Manager: $ManagerDN"
		Write-Verbose -Message "Group: $GroupDN"
		Write-Verbose -Message "TargetDC: $TargetDC"
		$Manager = [ADSI]"LDAP://$TargetDC/$ManagerDN"
		$IdentityRef = (Get-ADGroup -Identity $ManagerDN -Server $TargetDC).SID.Value
		$SID = New-Object System.Security.Principal.SecurityIdentifier($IdentityRef)

		$ADRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($SID, [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty, [System.Security.AccessControl.AccessControlType]::Allow, [Guid]"bf9679c0-0de6-11d0-a285-00aa003049e2");
		$Group = [ADSI]"LDAP://$TargetDC/$GroupDN"

		$Group.InvokeSet("managedBy", @("$ManagerDN"))
        $Group.CommitChanges()

		# Taken from here: http://blogs.msdn.com/b/dsadsi/archive/2013/07/09/setting-active-directory-object-permissions-using-powershell-and-system-directoryservices.aspx
		[System.DirectoryServices.DirectoryEntryConfiguration]$SecOptions = $Group.get_Options()
		$SecOptions.SecurityMasks = [System.DirectoryServices.SecurityMasks]'Dacl'

		$Group.get_ObjectSecurity().AddAccessRule($ADRule)
		$Group.CommitChanges()
	} catch {
		Write-Error -Message "Message: $($_.Exception.Message)"
		Write-Error -Message "ItemName: $($_.Exception.ItemName)"
	}
}