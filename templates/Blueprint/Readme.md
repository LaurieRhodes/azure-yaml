# Blueprints

*Directory Structure*

| Name                                       | Object Reference                                             |
| ------------------------------------------ | ------------------------------------------------------------ |
| [Folder]\Blueprint.yaml                    | The Blueprint file https://docs.microsoft.com/en-us/rest/api/blueprints/blueprints/createorupdate#request-body |
| [Folder]\artifacts                         | Folder for linked Blueprint artifacts https://docs.microsoft.com/en-us/rest/api/blueprints/artifacts/createorupdate#request-body |
| [Folder]\artifacts\(policyAssignment).yaml | Assignment objects https://docs.microsoft.com/en-us/rest/api/blueprints/assignments/createorupdate |
| [Folder]\artifacts\(roleAssignment).yaml   |                                                              |
| [Folder]\artifacts\(template.yaml          |                                                              |
|                                            |                                                              |
|                                            |                                                              |

**Important Note**

Two modifications need to be made to support the deployment of template artifacts that are stored with YAML.  

1. A modification of the Powershell-YAML module supports overriding data type detections by using quote marks to force the 'apiVersion' property to be recognised as a string.   When creating Template artifacts, enclosing 'apiVersion' dates in quotes is a manual task.

![](\images\DateMod.JPG)



2.  'powershell-yaml' modification.

This module is available for installation via [Powershell Gallery](http://www.powershellgallery.com/). Simply run the following command:

```
Install-Module powershell-yaml
```

The installed module will be found at "C:\Program Files\WindowsPowerShell\Modules\powershell-yaml"

The current version (0.4.2) does not natively support overriding the automatic detection of data types, which is a fundamental problem for the version field with ARM templates.  After the powershell-yaml module is installed, either the '*powershell-yaml.psm1*' file may be modified directly or a copy can be made and amended.

Line 84: (original) function - Convert-ValueToProperType

```
  if([Text.RegularExpressions.Regex]::IsMatch($Node.Value, $regex, [Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace) ) {
        [DateTime]$datetime = [DateTime]::MinValue
        if( ([DateTime]::TryParse($Node.Value,[ref]$datetime)) ) {
            return $datetime
        }
    }
```

The updated function is below with a final "if statement"... if the date sequence is enclosed in single or double quotes (which is the style property), return the string value and not DateTime:

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

An example syntax for using the amended module is below:

```
Remove-Module -Name powershell-yaml
Import-Module "<path to module>\powershell-yaml\0.4.2\powershell-yaml.psm1" 
```





