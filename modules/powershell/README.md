# PowerShell Modules
The PowerShell modules required for provisioning Azure  with YAML:

| Module          | Details                                                      |
| --------------- | ------------------------------------------------------------ |
| AZRest          | Used for retrieving and pushing objects to Azure.            |
| powershell-yaml | A wrapper for the YAML-Dot-Net library.  https://github.com/cloudbase/powershell-yaml |



**powershell-yaml**

A slight fork of Gabriel Samfira's powershell-yaml module is recommended to allow dates to be treated as strings when quotes are used.  The modification occurs in the file: **powershell-yaml.psm1**

Nodes (i.e. the yaml values) also have a style tag as either plain, 'single quoted' or "double quoted". If a date representation is enclosed in single or double quotes, I'm happy to accept the quotes indicate it should be treated as a string. That's an easy If statement to add...

Line 84: (original) function - Convert-ValueToProperType

```
  if([Text.RegularExpressions.Regex]::IsMatch($Node.Value, $regex, [Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace) ) {
        [DateTime]$datetime = [DateTime]::MinValue
        if( ([DateTime]::TryParse($Node.Value,[ref]$datetime)) ) {
            return $datetime
        }
    }
```

Updated... - added a final if statement... if the date sequence is enclosed in single or doube quotes (which is the style property), return the string value and not DateTime:

```
    if([Text.RegularExpressions.Regex]::IsMatch($Node.Value, $regex, [Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace) ) {
        [DateTime]$datetime = [DateTime]::MinValue
        if( ([DateTime]::TryParse($Node.Value,[ref]$datetime)) ) {
            if ($Node.Style -in 'DoubleQuoted','SingleQuoted') {
                return $Node.Value
            }
            else {
                return $datetime
            }
        }
    }
```

By enclosing the date in quotes means it's always converted from yaml as a string.

**AZRest**

The AZRest module is produced from this repository.



