<#
   .SYNOPSIS
        Return Operating system of given computer

    .DESCRIPTION
        Queries AD and returns the Operatingsystem attribute for given computer.

    .EXAMPLE
        Get-OS wamcitrix
   
    .PARAMETER ComputerName
        Name of computer object
#>
function Get-OS
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    Get-ADComputer $ComputerName -Properties OperatingSystem | Select-Object -ExpandProperty Operatingsystem
}