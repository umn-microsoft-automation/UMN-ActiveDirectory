---
external help file: UMN-ActiveDirectory-help.xml
Module Name: UMN-ActiveDirectory
online version:
schema: 2.0.0
---

# Set-ADGroupManager

## SYNOPSIS
Sets manager property on AD group and grants change membership rights.

## SYNTAX

```
Set-ADGroupManager [-ManagerDN] <String> [-GroupDN] <String> [[-TargetDC] <String>] [<CommonParameters>]
```

## DESCRIPTION
Sets manager property on AD group and grants change membership rights.
This is done by manipulating properties directly on the DirectoryEntry object
obtained with ADSI.
This sets the managedBy property and adds an ACE to the DACL
allowing said manager to modify group membership.
Taken from: https://mcardletech.com/blog/setting-ad-group-managers-with-powershell/

## EXAMPLES

### EXAMPLE 1
```
Set-GroupManager -ManagerDN "CN=some manager,OU=All Users,DC=Initech,DC=com" -GroupDN "CN=TPS Reports Dir,OU=All Groups,DC=Initech,DC=com"
```

### EXAMPLE 2
```
(Get-AdGroup -Filter {Name -like "sharehost - *"}).DistinguishedName | % {Set-GroupManager "CN=some manager,OU=All Users,DC=Initech,DC=com" $_}
```

## PARAMETERS

### -ManagerDN
{{ Fill ManagerDN Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -GroupDN
{{ Fill GroupDN Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -TargetDC
{{ Fill TargetDC Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (Get-ADDomainController).HostName
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
