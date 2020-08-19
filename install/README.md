# Azure-YAML Installation 
**Introduction**

Azure objects can be represented in different formats.  Translating Azure objects into PowerShell Hashtables and storing them as YAML is a logical approach for provisioning and managing Azure.

All Azure objects are provisioned with a corresponding provider (i.e. /providers/*Microsoft.Compute*/) that manages REST API calls for creating, modifying and deleting objects of that specific type.  Because the Object ID is structured, the ID states what type of object is specified. the Subscription and Resource Group it resides in, and its name.  If we know the provider name and can work out the current API version. that Id strings is all that is required for accessing (and provisioning) an Azure object through REST.

Creating a lookup table of Azure providers to versions is extremely simple.  The 'powershell-yaml' module for translating PowerShell to YAML is well used by everyone including Microsoft.  With a slight modification the module may be used for directly working with Microsoft's Azure providers.

A second module (AZRest) is included in this repository that demonstrates how to authenticate to Azure and get objects from the cloud.



**Required Modules**

1.  <u>'powershell-yaml' - with modificationmodification.</u>

The 'powershell-yaml' module is available for installation via [Powershell Gallery](http://www.powershellgallery.com/). Simply run the following command:

```
Install-Module powershell-yaml
```

The installed module will be found at "C:\Program Files\WindowsPowerShell\Modules\powershell-yaml"

The current version (0.4.2) does not natively support overriding the automatic detection of data types, which is a fundamental problem for the version field with ARM templates.  After the powershell-yaml module is installed, either the '*powershell-yaml.psm1*' file may be modified directly or a copy can be made and amended.

Line 84: (original) function - Convert-ValueToProperType

```powershell
  if([Text.RegularExpressions.Regex]::IsMatch($Node.Value, $regex, [Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace) ) {
        [DateTime]$datetime = [DateTime]::MinValue
        if( ([DateTime]::TryParse($Node.Value,[ref]$datetime)) ) {
            return $datetime
        }
    }
```

The updated function is below with a final "if statement"... if the date sequence is enclosed in single or double quotes (which is the style property), return the string value and not DateTime:

```powershell
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

```powershell
Remove-Module -Name powershell-yaml
Import-Module "<path to module>\powershell-yaml\0.4.2\powershell-yaml.psm1" 
```



2. AZRest (this Repo)

[\modules\powershell]: \modules\powershell	"Found here"

Please take time to review the Readme lined to this module.





## *Example Install Script*

The example below demonstrates the deployment of YAML files into Azure.  

Note that Id entries for objects must be set prior to deployment.  Note the templates folder and subsequent Readme for further details.

```powershell
# Optional import of modules
# Import-Module "C:\Scripts\AZRest\1.0\powershell-yaml\0.4.2\powershell-yaml.psm1" 
# Import-Module "C:\Scripts\AZRest\1.0\AZRest\AZRest.psm1" 


# Get an authorised Azure Header for REST
$authHeader = Get-Header -scope "azure"  -Tenant "laurierhodes.info" -AppId "aa73b052-6cea-4f17-b54b-6a536be5c722" -secret 'XXXXXXXXXXXXXXXXXXXXXXXXX’ 


# Retrieve an up to date list of API versions (once per session) - note that any subscription may be used for generating a current API versions file.

if (!$AzAPIVersions){$AzAPIVersions = Get-AzureAPIVersions -header $authHeader -SubscriptionID "2be53ae5-6e46-47df-beb9-6f3a795387b8"}


# Create a Sentinel space

$path  = "C:\Scripts\yaml"
Get-Yamlfile -Path "$path\Sentinel\ResourceGroup.yaml" | Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions 
Get-Yamlfile -Path "$path\Sentinel\LogAnalytics.yaml" | Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions 
Get-Yamlfile -Path "$path\Sentinel\EnableSentinel.yaml" | Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions 


```



