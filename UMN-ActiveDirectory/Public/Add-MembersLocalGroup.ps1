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
    
        [Parameter(ParameterSetName = 'User')]
        [string]$User,
    
        [Parameter(ParameterSetName = 'Group')]
        [string]$Group,
    
        [Parameter(Mandatory)]
        [string]$ADDomain
    )
    
    Begin {
    }
    Process {
        # Validate User/group exist
        try {
            switch ($PsCmdlet.ParameterSetName) {
                'User' { $null = Get-ADUser -Identity $User; $entity = $User }
                'Group' { $null = Get-ADGroup $Group; $entity = $Group }
                default { Throw "Failure to validate user/group" }
            }
        }
        catch { throw $Error[0] }
        $de = [ADSI]("WinNT://$Computer/$GroupToAddTo,group")
        $de.psbase.Invoke("Add", ([ADSI]"WinNT://$ADDomain/$entity").path)
    
        ## Validate change worked
        if ( -not (Get-MembersLocalGroup -grp $GroupToAddTo -computer $Computer | Select-String $entity)) { throw "Final check failed, $entity not added" }
    
    }
    End {
    }
}