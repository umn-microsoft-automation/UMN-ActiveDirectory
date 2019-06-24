---
external help file: UMN-ActiveDirectory-help.xml
Module Name: UMN-ActiveDirectory
online version:
schema: 2.0.0
---

# Get-MembersLocalGroup

## SYNOPSIS
Function for retrieving user membership of a windows local computer group.

## SYNTAX

```
Get-MembersLocalGroup [-grp] <String> [-computer] <String> [<CommonParameters>]
```

## DESCRIPTION
Function for retrieving user membership of a windows local computer group.

## EXAMPLES

### EXAMPLE 1
```
Get-MembersLocalGroup -grp 'Administrators' -computer $computer
```

### EXAMPLE 2
```
Another example of how to use this cmdlet
```

## PARAMETERS

### -grp
{{ Fill grp Description }}

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

### -computer
{{ Fill computer Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
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
