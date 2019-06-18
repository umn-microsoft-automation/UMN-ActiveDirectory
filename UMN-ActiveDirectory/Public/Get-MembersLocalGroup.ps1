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
function Get-MembersLocalGroup {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$grp,

        [Parameter(Mandatory = $true)]
        [string]$computer
    )

    Begin {
    }
    Process {
        $ADSIComputer = [ADSI]("WinNT://$computer,computer")
        $group = $ADSIComputer.psbase.children.find($grp, 'Group') 
        $group.psbase.invoke("members") | ForEach { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) }
    }
    End {
    }
}