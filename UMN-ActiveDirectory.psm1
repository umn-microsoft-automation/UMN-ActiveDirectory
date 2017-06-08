##
# Copyright 2017 University of Minnesota, Office of Information Technology

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
#
###############
# Module for interacting with local accounts
#
#
###############

function Get-MembersLocalGroup{
<#
    .Synopsis
    Function for retrieving user membership of a windows local computer group.
    .DESCRIPTION
    Function for retrieving user membership of a windows local computer group.
    .EXAMPLE
    Get-MembersLocalGroup -grp 'Administrators' -computer $computer
    .EXAMPLE
    Another example of how to use this cmdlet
#>

    [CmdletBinding()]
    Param
    (

        [Parameter(Mandatory=$true)]
        [string]$grp,

        [Parameter(Mandatory=$true)]
        [string]$computer
    )

    Begin
    {
    }
    Process
    {
        $ADSIComputer = [ADSI]("WinNT://$computer,computer")
        $group = $ADSIComputer.psbase.children.find($grp, 'Group') 
        $group.psbase.invoke("members")  | ForEach{$_.GetType().InvokeMember("Name",  'GetProperty',  $null,  $_, $null)}
    }
    End
    {
    }
}


function Add-MembersLocalGroup{
<#
    .Synopsis
    Add an AD user or group to a local group on computer
    .DESCRIPTION
    Specify either an AD based user or group to add to a local windows security group. This function
    also verifies that the operation.
    .EXAMPLE
    Add-MembersLocalGroup -grpToAddTo $grpToAddTo -computer $computer -user $user -adDomain $domain
    .EXAMPLE
    Add-MembersLocalGroup -grpToAddTo $grpToAddTo -computer $computer -grp $grp -adDomain $domain
#>

    [CmdletBinding()]
    Param
    (

        [Parameter(Mandatory=$true)]
        [string]$grpToAddTo,

        [Parameter(Mandatory=$true)]
        [string]$computer,

        [Parameter(ParameterSetName='User')]
        [string]$user,

        [Parameter(ParameterSetName='Group')]
        [string]$grp,

        [Parameter(Mandatory)]
        [string]$adDomain
    )

    Begin
    {
    }
    Process
    {
        # Validate User/group exist
        try {
            switch($PsCmdlet.ParameterSetName){
                'User'{$null = Get-ADUser -Identity $user;$entity = $user}
                'Group'{$null = Get-ADGroup $grp;$entity = $grp}
                default {Throw "Failure to validate user/group"}
            }
        }
        catch{throw $Error[0]}
        $de = [ADSI]("WinNT://$computer/$grpToAddTo,group")
        $de.psbase.Invoke("Add",([ADSI]"WinNT://$adDomain/$entity").path)

        ## Validate change worked
        if ( -not (Get-MembersLocalGroup -grp $grpToAddTo -computer $computer | Select-String $entity)){throw "Final check failed, $entity not added"}

    }
    End
    {
    }
}


function Confirm-ADObjectExists {
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
		
		.NOTES
		Name: Confirm-ADObjectExists
		Author: Jeff Bolduan
		LASTEDIT: 3/8/2016, 12:48 PM
	#>
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
	} catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
		Write-Verbose -Message "ADIdentityNotFoundException"
		return $false
	} catch {
		Write-Verbose -Message "Other error $($_.Exception.Message)"
		Write-Error -Exception $_.Exception -Message $_.Exception.Message -TargetObject $_.Exception.ItemName
		return $false
	}
	
	if ($ADObject) {
		return $true
	}
	else {
		return $false	
	}
}


function Confirm-ADObjectDCReplication {
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
		
		.NOTES
		Name: Confirm-ADObjectDCReplication
		Author: Jeff Bolduan
		LASTEDIT: 3/8/2016, 12:48 PM
	#>
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
		Write-Error -Message "Message: $_.Exception.Message"
		Write-Error -Message "ItemName: $_.Exception.ItemName"
	}
}


function Get-AllGPOsUnderOU {
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


function Set-ADGroupManager {
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
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$true, Position=0)][string]$ManagerDN,
		[Parameter(Mandatory=$true, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$true, Position=1)][string]$GroupDN,
		[Parameter(Mandatory=$false, ValueFromPipeline=$false, ValueFromPipelineByPropertyName=$true, Position=2)][string]$TargetDC=(Get-ADDomainController).HostName
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


function Test-GPOWiFiServerName {
	<#
	.SYNOPSIS
		Checks a GPO to see if the WiFi profiles have a specific server name. Ultimately, is a reference
        on how to check for a setting in a GPO.
	.DESCRIPTION
		Takes in a GPO and server name and then determines if the WiFi profiles have the specific server name.
	.EXAMPLE
		Test-GPOWiFiServerName -GPO (Get-GPO -Name "This-Is-A-Test") -ServerName "wifiauth.domain.com"
	.PARAMETER GPO
		Group policy object to search within
	.PARAMETER ServerName
		String for the server name to look for.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		[Microsoft.GroupPolicy.Gpo]$GPO,

		[Parameter(Mandatory=$true)]
		[string]$ServerName
	)
	process {
		[xml]$ReportXML = $GPO | Get-GPOReport -ReportType Xml
		$NamespaceManager = New-Object System.Xml.XmlNamespaceManager($ReportXML.NameTable)
		$NamespaceManager.AddNamespace("root", "http://www.microsoft.com/GroupPolicy/Settings")
		$GPOSettings = [array]$ReportXML.SelectNodes("//root:Extension", $NamespaceManager)

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


Function Get-ParentDistinguishedName {
    <#
		.SYNOPSIS
		Cmdlet that returns the parent of a distinguished name.
		
		.DESCRIPTION
		A cmdlet that takes in a string which should be a valid distinguished name. It then returns a string that is the
        distinguished name for the parent object of the object passed in.
		
		.PARAMETER DistinguishedName
		A string that is a valid distinguished name.
		
		.EXAMPLE
		Get-ParentDistinguishedName -DistinguishedName "CN=Foo,OU=Bar,DC=domain,DC=acme,DC=com"
		
		.NOTES
		Name: Get-ParentDistinguishedName
		Author: Craig Woodford
		LASTEDIT: 6/14/2016, 12:48 PM

        Based on: https://www.uvm.edu/~gcd/2012/07/listing-parent-of-ad-object-in-powershell/
	#>
    
    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$false, HelpMessage="Enter in a valid Distinguished Name")][string]$DistinguishedName
	)
    
    process {
        # Split the string on commas that are not preceeded by a slash
        $parts = $DistinguishedName -split '(?<![\\]),'
        # Returns the rejoined string minus the first element
        $parts[1..$($parts.Count-1)] -join ','
    }
}


Function Get-GPOsForOU {
    <#
		.SYNOPSIS
		Cmdlet that returns all GPOs applied to a specific OU.
		
		.DESCRIPTION
		A cmdlet that takes in a string which should be a valid distinguished name for an AD OU. It then returns an array
        containing any group policy objects (.Net class: Microsoft.GroupPolicy.Gpo) that are applied to that OU.
		
		.PARAMETER DistinguishedName
		A string that is a valid distinguished name for an OU in AD.

        .PARAMETER Server
		A domain controller which can be used to see if the item exists on a specific domain controller.
		
		.EXAMPLE
		Get-GPOsForOU -DistinguishedName "OU=Foo,OU=Bar,DC=domain,DC=acme,DC=com" -Server dc1.domain.acme.com
		
		.NOTES
		Name: Get-GPOsForOU
		Author: Craig Woodford
	#>

    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, HelpMessage="Enter in a valid OU distinguished name.")][string]$ouDistinguishedName,
		[Parameter(Mandatory=$false, HelpMessage="Enter in a valid domain controller.")][string]$Server=(Get-ADDomainController).HostName
	)
    
    process {
        $LinkedGPOs = @()
        
        try {

            # Get-GPInheritance doesn't return objects of the same type as Get-GPO so we want to process the results of the InheritedGpoLinks field.
            $GPLinkList = (Get-GPInheritance -Target $ouDistinguishedName -Server $Server).InheritedGpoLinks

            foreach ($gpLink in $GPLinkList) {
                if ($gpLink.DisplayName) {
                    $LinkedGPOs += Get-GPO -Name $gpLink.DisplayName -Server $Server
                }
            }

            $LinkedGPOs
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}


Function Get-GPOsForComputer {
    <#
	    .SYNOPSIS
		Cmdlet that returns all GPOs applied to a computer object.
		
		.DESCRIPTION
		A cmdlet that takes in a string which should be a valid computer name. It then returns an array
        containing any group policy objects (.Net class: Microsoft.GroupPolicy.Gpo) that are applied to that computer.
		
		.PARAMETER ComputerName
		A string that is a valid name for a computer object in AD.

        .PARAMETER Server
		A domain controller which can be used to see if the item exists on a specific domain controller.
		
		.EXAMPLE
		Get-GPOsForComputer -ComputerName "Computer1" -Server dc1.domain.acme.com
		
		.NOTES
		Name: Get-GPOsForComputer
		Author: Craig Woodford
	#>

    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, HelpMessage="Enter in a valid computer object identity")][string]$ComputerName,
		[Parameter(Mandatory=$false, HelpMessage="Enter in a valid domain controller.")][string]$Server=(Get-ADDomainController).HostName
	)
    
    process {

        try {
        
            $computerDistinguishedName = (Get-ADComputer -Identity $ComputerName).DistinguishedName
        
            $parentDistinguishedName = Get-ParentDistinguishedName -DistinguishedName $computerDistinguishedName
            
            $LinkedGPOs = Get-GPOsForOU -ouDistinguishedName $parentDistinguishedName -Server $Server

            $LinkedGPOs
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}


Function Get-MappedDrivesForComputer {
    <#
	    .SYNOPSIS
		Cmdlet that returns all drives mapped by group policy preferences for a computer.
		
		.DESCRIPTION
		A cmdlet that takes in a string which should be a valid computer name. It then returns an array
        containing information about any drives mapped via group policy preferences.
		
		.PARAMETER ComputerName
		A string that is a valid name for a computer object in AD.

        .PARAMETER Server
		A domain controller which can be used to see if the item exists on a specific domain controller.
		
		.EXAMPLE
		Get-MappedDrivesForComputer -ComputerName "Computer1" -Server dc1.domain.acme.com
		
		.NOTES
		Name: Get-MappedDrivesForComputer
		Author: Craig Woodford
	#>

    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, HelpMessage="Enter in a valid computer object identity")][string]$ComputerName,
		[Parameter(Mandatory=$false, HelpMessage="Enter in a valid domain controller.")][string]$Server=(Get-ADDomainController).HostName
	)
    
    process {
        $driveMaps = @()

        $LinkedGPOs = Get-GPOsForComputer -ComputerName $ComputerName -Server $Server

        if ($LinkedGPOs) {
            foreach ($policy in $LinkedGPOs) {
                $GPOID = $Policy.Id
                $GPODom = $Policy.DomainName
                $GPODisp = $Policy.DisplayName
 
                # Test each group policy path in SYSVOL to ensure its there then get the content as XML.
                if (Test-Path "\\$($GPODom)\SYSVOL\$($GPODom)\Policies\{$($GPOID)}\User\Preferences\Drives\Drives.xml") {
                    [xml]$DriveXML = Get-Content "\\$($GPODom)\SYSVOL\$($GPODom)\Policies\{$($GPOID)}\User\Preferences\Drives\Drives.xml"
 
                    # Walk through each mapped drive in the group policy and build an object with information about the mapping.
                    foreach ( $drivemap in $DriveXML.Drives.Drive ) {
                        $driveMaps += New-Object PSObject -Property @{
                            GPOName = $GPODisp
                            DriveLetter = $drivemap.Properties.Letter + ":"
                            DrivePath = $drivemap.Properties.Path
                            DriveAction = $drivemap.Properties.action.Replace("U","Update").Replace("C","Create").Replace("D","Delete").Replace("R","Replace")
                            DriveLabel = $drivemap.Properties.label
                            DrivePersistent = $drivemap.Properties.persistent.Replace("0","False").Replace("1","True")
                            DriveFilterGroup = $drivemap.Filters.FilterGroup.Name
                        }
                    }
                }
            }
        }

        $driveMaps
    }
}

Function Confirm-ADObjectIsInGroup {
    <#
	    .SYNOPSIS
		Cmdlet that confirms if an AD object is a member of an AD group.
		
		.DESCRIPTION
		A cmdlet that takes in a string which should be a valid AD object and another string which should be a
        valid AD group. It then returns true if the object is a member of the group and false if not or if
        either object does not exist.

		.PARAMETER ObjectName
		A string that is a valid name for an object in AD.

        .PARAMETER GroupName
		A string that is a valid name for a group object in AD.

        .PARAMETER Server
		A domain controller which can be used to see if the item exists on a specific domain controller.
		
		.EXAMPLE
		Confirm-ADObjectIsInGroup -ObjectName "user1" -GroupName "group2" -Server dc1.domain.acme.com
		
		.NOTES
		Name: Confirm-ADObjectIsInGroup
		Author: Craig Woodford
	#>

    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, HelpMessage="Enter in a valid user object identity")][string]$ObjectName,
		[Parameter(Mandatory=$true, HelpMessage="Enter in a valid group object identity")][string]$GroupName,
		[Parameter(Mandatory=$false, HelpMessage="Enter in a valid domain controller.")][string]$Server=(Get-ADDomainController).HostName
	)

    process {
        
        try {
        
            # Test if the objects exist before we do anything else.
            if ((Confirm-ADObjectExists -Identity $ObjectName -Type Unknown -Server $Server) -and (
                Confirm-ADObjectExists -Identity $GroupName -Type Group -Server $Server)) {
            
                # Get object so we can access it's distinguished name.
                $targetObject = Get-ADObject -Filter {(
				    DistinguishedName -eq $ObjectName) -or (
				    ObjectGUID -eq $ObjectName) -or (
				    objectSID -eq $ObjectName) -or (
				    SamAccountName -eq $ObjectName)
			    } -Server $Server
            
                $targetGroup =  Get-ADGroup -Identity $GroupName -Server $Server

                # This query will return null if the object is not a member of the group.
                $searchResult = Get-ADObject -Filter { memberOf -RecursiveMatch $targetGroup.DistinguishedName } -SearchBase $targetObject.DistinguishedName -SearchScope Base
            }
            else {
                $searchResult = $null
            }

            if ($searchResult) {
                return $true
            }
            else {
                return $false
            }
        }
        catch {
            # If we encounter an error we want to return false.
            Write-Verbose -Message "Other error $($_.Exception.Message)"
		    Write-Error -Exception $_.Exception -Message $_.Exception.Message -TargetObject $_.Exception.ItemName
		    return $false
        }
    }
}



Function Get-GPOLink {
    <#
        .SYNOPSIS
            Returns the Active Directory (AD) Organization Units (OU's) that a Group Policy Object (GPO) is linked to.

        .DESCRIPTION
            Get-GPOLink is a function that returns the Active Directory Organization Units (OU's) that a Group Policy
            Object (GPO) is linked to.

        .PARAMETER Name
            The Name of the Group Policy Object.

        .EXAMPLE
            Get-GPOLink -Name 'Default Domain Policy'

        .EXAMPLE
            Get-GPOLink -Name 'Default Domain Policy', 'Default Domain Controllers Policy'

        .EXAMPLE
            'Default Domain Policy' | Get-GPOLink

        .EXAMPLE
            'Default Domain Policy', 'Default Domain Controllers Policy' | Get-GPOLink

        .EXAMPLE
            Get-GPO -All | Get-GPO-Link

        .INPUTS
            System.String, Microsoft.GroupPolicy.Gpo

        .OUTPUTS
            PSCustomObject

        .NOTES
            Taken from Mike Robbins and slightly modified. See this page:
            http://mikefrobbins.com/2013/11/14/determine-what-active-directory-organization-units-a-group-policy-is-linked-to-with-powershell/
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
                   ValueFromPipeline,
                   ValueFromPipelineByPropertyName)]
        [Alias('DisplayName')]
        [string[]]$Name
    )
    
    process {
        foreach ($n in $Name) {
            $problem = $false
            try {
                Write-Verbose -Message "Attempting to produce XML report for GPO: $n"
                [xml]$report = Get-GPOReport -Name $n -ReportType Xml -ErrorAction Stop
            }
            catch {
                $problem = $true
                Write-Warning -Message "An error occured while attempting to query GPO: $n"
            }
            if (-not($problem)) {
                Write-Verbose -Message "Returning results for GPO: $n"
                [PSCustomObject]@{
                    'GPOName' = $report.GPO.Name
                    'LinksTo' = $report.GPO.LinksTo.SOMPath
                    'Enabled' = $report.GPO.LinksTo.Enabled
                    'NoOverride' = $report.GPO.LinksTo.NoOverride
                    'CreatedDate' = ([datetime]$report.GPO.CreatedTime).ToShortDateString()
                    'ModifiedDate' = ([datetime]$report.GPO.ModifiedTime).ToShortDateString()
                }
            }
        }
    }
}

Function Get-MappedPrintersForComputer {
    <#
	    .SYNOPSIS
		Cmdlet that returns all printers mapped by group policy preferences for a computer.
		
		.DESCRIPTION
		A cmdlet that takes in a string which should be a valid computer name. It then returns an array
        containing information about any printers mapped via group policy preferences.
		
		.PARAMETER ComputerName
		A string that is a valid name for a computer object in AD.

        .PARAMETER Server
		A domain controller which can be used to see if the item exists on a specific domain controller.
		
		.EXAMPLE
		Get-MappedPrintersForComputer -ComputerName "Computer1" -Server dc1.domain.acme.com
		
		.NOTES
		Name: Get-MappedPrintersForComputer
		Author: Craig Woodford
	#>

    [CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, HelpMessage="Enter in a valid computer object identity")][string]$ComputerName,
		[Parameter(Mandatory=$false, HelpMessage="Enter in a valid domain controller.")][string]$Server=(Get-ADDomainController).HostName
	)
    
    process {
        $printerMaps = @()

        $LinkedGPOs = Get-GPOsForComputer -ComputerName $ComputerName -Server $Server

        if ($LinkedGPOs) {
            foreach ($policy in $LinkedGPOs) {
                $GPOID = $Policy.Id
                $GPODom = $Policy.DomainName
                $GPODisp = $Policy.DisplayName
                $PrefPath = "\\$($GPODom)\SYSVOL\$($GPODom)\Policies\{$($GPOID)}\User\Preferences"
 
                #Get GP Preferences Printers
                $XMLPath = "$PrefPath\Printers\Printers.xml"
                if (Test-Path "$XMLPath") {
                [xml]$PrintXML = Get-Content "$XMLPath"
 
                    foreach ( $Printer in $PrintXML.Printers.SharedPrinter ) {
 
                        $printerMaps += New-Object PSObject -Property @{
                            GPOName = $GPODisp
                            PrinterPath = $printer.Properties.Path
                            PrinterAction = $printer.Properties.action.Replace("U","Update").Replace("C","Create").Replace("D","Delete").Replace("R","Replace")
                            PrinterDefault = $printer.Properties.default.Replace("0","False").Replace("1","True")
                            FilterGroup = $printer.Filters.FilterGroup.Name
                            GPOType = "Group Policy Preferences"
                        }
                    }
                }
            }
            
            $printerMaps
        }
    }
}

function Confirm-GPOExists {
	<#
		.SYNOPSIS
		Cmdlet that returns true if the GPO exists and false if it doesn't.
		
		.DESCRIPTION
		A cmdlet that take in the name or guid of a GPO and an optional server and then returns true or false if the GPO exists.
		
		.PARAMETER Name
		A string representing the GPO name.
		
		.PARAMETER GUID
		A string representing the GPO GUID.
		
		.PARAMETER Server
		A domain controller which can be used to see if the item exists on a specific domain controller.
		
		.EXAMPLE
		Confirm-ADObjectExists -Name "GPOName1" -Server (Get-ADDomainController).HostName
		
		.EXAMPLE
		Confirm-ADObjectExists -GUID "1234-5678-9101112"
		
		.NOTES
		Name: Confirm-GPOExists
		Author: Craig Woodford (with help from Jeff Bolduan)
		LASTEDIT: 8/26/2016, 12:48 PM
	#>
	[CmdletBinding(DefaultParameterSetName='Name')]
	param(
		[Parameter(Mandatory=$true, HelpMessage="Enter in a valid GPO Name",ParameterSetName='Name')][string]$Name,
		[Parameter(Mandatory=$true, HelpMessage="Enter in a valid GPO Name",ParameterSetName='GUID')][string]$GUID,
		[Parameter(Mandatory=$false, HelpMessage="Enter in a valid domain controller.")][string]$Server=(Get-ADDomainController).HostName
	)
	$ErrorActionPreference = "SilentlyContinue"
	Write-Verbose -Message "$Server"
	try {
		if($Name) {
			Write-Verbose -Message "Group Policy Name: $Name"
			$GPOObject = Get-GPO -Name $Name -Server $Server
		} elseif($GUID) {
			Write-Verbose -Message "Group Policy GUID: $GUID"
			$GPOObject = Get-GPO -Guid $GUID -Server $Server
		}
	} catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
		Write-Verbose -Message "ADIdentityNotFoundException"
		return $false
	} catch {
		Write-Verbose -Message "Other error $($_.Exception.Message)"
		Write-Error -Exception $_.Exception -Message $_.Exception.Message -TargetObject $_.Exception.ItemName
		return $false
	}
	
	if ($GPODObject) {
		return $true
	}
	else {
		return $false	
	}
} # end Confirm-GPOExists