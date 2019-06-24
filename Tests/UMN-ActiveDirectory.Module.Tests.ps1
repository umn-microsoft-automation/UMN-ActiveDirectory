Describe "General project validation: $moduleName" {

    $scripts = Get-ChildItem $moduleRoot -Include *.ps1,*.psm1,*.psd1 -Recurse

    $predicate = {
        param ( $ast )

        if ($ast -is [System.Management.Automation.Language.BinaryExpressionAst] -or
            $ast -is [System.Management.Automation.Language.CommandParameterAst] -or
            $ast -is [System.Management.Automation.Language.AssignmentStatementAst]) {

            if ($ast.ErrorPosition.Text[0] -in 0x2013, 0x2014, 0x2015) {return $true}
            
        }
        if ($ast -is [System.Management.Automation.Language.CommandAst] -and
            $ast.GetCommandName() -match '\u2013|\u2014|\u2015') {return $true}

        if (($ast -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
                $ast -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) -and
            $ast.Parent -is [System.Management.Automation.Language.CommandExpressionAst]) {
            if ($ast.Parent -match '^[\u2018-\u201e]|[\u2018-\u201e]$') {return $true}
        }
    }

    function Get-FileEncoding
{
<#
	.SYNOPSIS
		Tests a file for encoding.
	
	.DESCRIPTION
		Tests a file for encoding.
	
	.PARAMETER Path
		The file to test
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
		[Alias('FullName')]
		[string]
		$Path
	)
	
	[byte[]]$byte = get-content -Encoding byte -ReadCount 4 -TotalCount 4 -Path $Path
	
	if ($byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf) { 'UTF8' }
	elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff) { 'Unicode' }
	elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff) { 'UTF32' }
	elseif ($byte[0] -eq 0x2b -and $byte[1] -eq 0x2f -and $byte[2] -eq 0x76) { 'UTF7' }
	else { 'Unknown' }
}

    # TestCases are splatted to the script so we need hashtables
    $testCase = $scripts | Foreach-Object{@{file=$_}}
    It "Script <file> should be valid powershell" -TestCases $testCase {
        param (
            $file
        )
        $script = Get-Content -Raw -Encoding UTF8 -Path $file
        $tokens = $errors = @()
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($Script, [Ref]$tokens, [Ref]$errors)
        $elements = $ast.FindAll($predicate, $true)

        $elements | Should -BeNullOrEmpty -Because $elements
        $errors | Should -BeNullOrEmpty -Because $errors
    }

    It "Script <file> should have UTF8 BOM encoding" -TestCases $testCase {
        param (
            $file
        )
        Get-FileEncoding -Path $file.FullName | Should -Be 'UTF8'
    }

    It "Script <file> Should have no trailing space" -TestCases $testCase {
        param (
            $file
        )
        ($file | Select-String "\s$" | Where-Object { $_.Line.Trim().Length -gt 0}).LineNumber | Should -BeNullOrEmpty
    }

    It "Module '$moduleName' can import cleanly" {
        {Import-Module (Join-Path $moduleRoot "$moduleName.psm1") -force } | Should Not Throw
    }
}
