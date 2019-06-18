---
external help file: UMN-ActiveDirectory-help.xml
Module Name: UMN-ActiveDirectory
online version:
schema: 2.0.0
---

# Confirm-ADObjectDCReplication

## SYNOPSIS
Cmdlet that returns true if the object exists on all domain controllers within the domain and false if it doesn't.

## SYNTAX

```
Confirm-ADObjectDCReplication [-ADObject] <String> [-Type] <String> [[-MaxWait] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
A cmdlet that take in the identity of an object, an object type and an optional maximum wait time (default is 30 seconds)
      to determine if that object exists on all domain controllers within a domain.
The script tries once each second up until
      thte maximum wait time is reached before returning a false if not all domain controllers return true.

## EXAMPLES

### EXAMPLE 1
```
Confirm-ADObjectDCReplication -ADObject "FooBar" -Type "Computer" -MaxWait 5
```

### EXAMPLE 2
```
Confirm-ADObjectDCReplication -ADObject "foobar" -Type "User"
```

### EXAMPLE 3
```
Confirm-ADObjectDCReplication -ADObject "S-1-5-1-5125-16836816-12512325" -Type "Group"
```

### EXAMPLE 4
```
Confirm-ADObjectDCReplication -ADObject "CN=Foo,CN=Bar,DC=domain,DC=acme,DC=com" -Type "OU"
```

## PARAMETERS

### -ADObject
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

### -MaxWait
The maximum time to wait in seconds before determining that the object does not exist on all domain controllers.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
