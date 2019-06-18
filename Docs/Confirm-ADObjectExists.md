---
external help file: UMN-ActiveDirectory-help.xml
Module Name: UMN-ActiveDirectory
online version:
schema: 2.0.0
---

# Confirm-ADObjectExists

## SYNOPSIS
Cmdlet that returns true if the object exists and false if it doesn't.

## SYNTAX

```
Confirm-ADObjectExists [-Identity] <String> [-Type] <String> [[-Server] <String>] [<CommonParameters>]
```

## DESCRIPTION
A cmdlet that take in the identity of an object, an object type and an optional server and then returns true or false if the object exists.

## EXAMPLES

### EXAMPLE 1
```
Confirm-ADObjectExists -Identity "FooBar" -Type "Computer" -Server (Get-ADDomainController).HostName
```

### EXAMPLE 2
```
Confirm-ADObjectExists -Identity "foobar" -Type "User"
```

### EXAMPLE 3
```
Confirm-ADObjectExists -Identity "S-1-5-1-5125-16836816-12512325" -Type "Group"
```

### EXAMPLE 4
```
Confirm-ADObjectExists -Identity "CN=Foo,CN=Bar,DC=domain,DC=acme,DC=com" -Type "OU"
```

## PARAMETERS

### -Identity
A string representing the object, can be a DN, GUID, sAMAccountName or SID.

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

### -Type
The type of object being tested. 
The unknwon identity simply uses Get-ADObject rather than an object specific locator.

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

### -Server
A domain controller which can be used to see if the item exists on a specific domain controller.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (Get-ADDomainController).HostName
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
