---
external help file: UMN-ActiveDirectory-help.xml
Module Name: UMN-ActiveDirectory
online version:
schema: 2.0.0
---

# Add-MembersLocalGroup

## SYNOPSIS
Add an AD user or group to a local group on computer

## SYNTAX

### User
```
Add-MembersLocalGroup -grpToAddTo <String> -computer <String> [-user <String>] -adDomain <String>
 [<CommonParameters>]
```

### Group
```
Add-MembersLocalGroup -grpToAddTo <String> -computer <String> [-grp <String>] -adDomain <String>
 [<CommonParameters>]
```

## DESCRIPTION
Specify either an AD based user or group to add to a local windows security group.
This function
also verifies that the operation.

## EXAMPLES

### EXAMPLE 1
```
Add-MembersLocalGroup -grpToAddTo $grpToAddTo -computer $computer -user $user -adDomain $domain
```

### EXAMPLE 2
```
Add-MembersLocalGroup -grpToAddTo $grpToAddTo -computer $computer -grp $grp -adDomain $domain
```

## PARAMETERS

### -grpToAddTo
{{ Fill grpToAddTo Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
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
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -user
{{ Fill user Description }}

```yaml
Type: String
Parameter Sets: User
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -grp
{{ Fill grp Description }}

```yaml
Type: String
Parameter Sets: Group
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -adDomain
{{ Fill adDomain Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
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
