---
external help file: UMN-ActiveDirectory-help.xml
Module Name: UMN-ActiveDirectory
online version:
schema: 2.0.0
---

# Get-AllGPOsUnderOU

## SYNOPSIS
Takes in a base OU and then grabs all the unique group policies linked under the OU.

## SYNTAX

```
Get-AllGPOsUnderOU [-SearchBase] <String> [<CommonParameters>]
```

## DESCRIPTION
Give this function an OU and it looks through the OU and sub OU's and gets all the unique GPOs.

## EXAMPLES

### EXAMPLE 1
```
Get-AllGPOsUnderOU -SearchBase ="OU=Test,DC=ad,DC=contoso,DC=.com"
```

## PARAMETERS

### -SearchBase
Distingusihed Name of the top level OU to start searching for group policies in.

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

### ArrayList of all the GPO objects.
## NOTES

## RELATED LINKS
