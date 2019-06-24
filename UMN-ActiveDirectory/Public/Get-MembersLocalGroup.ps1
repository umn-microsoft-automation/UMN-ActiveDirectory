<#
    .Synopsis
        Function for retrieving user membership of a windows local computer group.
    .DESCRIPTION
        Function for retrieving user membership of a windows local computer group.
    .EXAMPLE
        Get-MembersLocalGroup -Group 'Administrators' -computer $Computer
    .PARAMETER Group
        Name of the group to get the members of.
    .PARAMETER Computer
        Name of the computer on which the group is located.
#>
function Get-MembersLocalGroup {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Group,

        [Parameter(Mandatory = $true)]
        [string]$Computer
    )

    Begin {
    }
    Process {
        $ADSIComputer = [ADSI]("WinNT://$Computer,computer")
        $LocalGroup = $ADSIComputer.psbase.children.find($Group, 'Group')
        $LocalGroup.psbase.Invoke("members") | ForEach-Object { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null) }
    }
    End {
    }
}
