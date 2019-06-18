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
function Add-MembersLocalGroup {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$grpToAddTo,
    
        [Parameter(Mandatory = $true)]
        [string]$computer,
    
        [Parameter(ParameterSetName = 'User')]
        [string]$user,
    
        [Parameter(ParameterSetName = 'Group')]
        [string]$grp,
    
        [Parameter(Mandatory)]
        [string]$adDomain
    )
    
    Begin {
    }
    Process {
        # Validate User/group exist
        try {
            switch ($PsCmdlet.ParameterSetName) {
                'User' { $null = Get-ADUser -Identity $user; $entity = $user }
                'Group' { $null = Get-ADGroup $grp; $entity = $grp }
                default { Throw "Failure to validate user/group" }
            }
        }
        catch { throw $Error[0] }
        $de = [ADSI]("WinNT://$computer/$grpToAddTo,group")
        $de.psbase.Invoke("Add", ([ADSI]"WinNT://$adDomain/$entity").path)
    
        ## Validate change worked
        if ( -not (Get-MembersLocalGroup -grp $grpToAddTo -computer $computer | Select-String $entity)) { throw "Final check failed, $entity not added" }
    
    }
    End {
    }
}