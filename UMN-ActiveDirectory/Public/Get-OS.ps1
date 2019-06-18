<#
   .Synopsis
        Return Operating system of given computer
    .DESCRIPTION
        Queries AD and returns the Operatingsystem attribute for given computer.
    .EXAMPLE
        get-os wamcitrix
   
    .PARAMETER computername
        Name of computer object
#>
function Get-OS
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$computername
    )
    get-adcomputer $computername -Properties Operatingsystem|select -ExpandProperty  Operatingsystem
}