<#
    .Synopsis
        Add an AD user or group to a local group on computer
    .DESCRIPTION
        Specify either an AD based user or group to add to a local windows security group. This function
        also verifies that the operation.
    .EXAMPLE
        Add-MembersLocalGroup -GroupToAddTo $GroupToAddTo -Computer $Computer -User $User -ADDomain $domain
    .EXAMPLE
        Add-MembersLocalGroup -GroupToAddTo $GroupToAddTo -Computer $Computer -Group $Group -ADDomain $domain
    .PARAMETER GroupToAddTo
        Name of the local group to be added to.
    .PARAMETER Computer
        Name of the computer where the local group is located.
    .PARAMETER User
        Name of the user if you want to add a user.
    .PARAMETER Group
        Name of the group if you want to add a group.
    .PARAMETER ADDomain
        Domain where the user or group is located.
#>
function Add-MembersLocalGroup {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$GroupToAddTo,
    
        [Parameter(Mandatory = $true)]
        [string]$Computer,
    
        [Parameter(Mandatory = $true,
            ParameterSetName = 'User')]
        [string]$User,
    
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Group')]
        [string]$Group,
    
        [Parameter(Mandatory = $true)]
        [string]$ADDomain
    )
    
    Begin {
    }
    Process {
        # Validate User/group exist
        try {
            switch ($PsCmdlet.ParameterSetName) {
                'User' { $null = Get-ADUser -Identity $User; $entity = $User }
                'Group' { $null = Get-ADGroup -Identity $Group; $entity = $Group }
                default { Throw "Failure to validate user/group" }
            }
        }
        catch { throw $Error[0] }

        if(Get-Command Add-LocalGroupMember) {
            Add-LocalGroupMember -Group $GroupToAddTo -Member "$ADDomain\$entity"
        } else {
            # Support older operating systems
            $de = [ADSI]("WinNT://$Computer/$GroupToAddTo,group")
            $de.psbase.Invoke("Add", ([ADSI]"WinNT://$ADDomain/$entity").path)
        }
    
        ## Validate change worked
        if ( -not (Get-MembersLocalGroup -Group $GroupToAddTo -Computer $Computer | Select-String $entity)) { throw "Final check failed, $entity not added" }
    
    }
    End {
    }
}