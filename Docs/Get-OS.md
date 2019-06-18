---
external help file: UMN-ActiveDirectory-help.xml
Module Name: UMN-ActiveDirectory
online version:
schema: 2.0.0
---

# Get-OS

## SYNOPSIS
Return Operating system of given computer

## SYNTAX

```
Get-OS [-computername] <String> [<CommonParameters>]
```

## DESCRIPTION
Queries AD and returns the Operatingsystem attribute for given computer.

## EXAMPLES

### EXAMPLE 1
```
get-os wamcitrix
```

## PARAMETERS

### -computername
Name of computer object

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
