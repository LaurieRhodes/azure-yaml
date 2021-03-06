# Azure-YAML Installation 
**Introduction**

Azure objects can be represented in different formats.  Translating Azure objects into PowerShell Hashtables and storing them as YAML is a logical approach for provisioning and managing Azure.

All Azure objects are provisioned with a corresponding provider (i.e. /providers/*Microsoft.Compute*/) that manages REST API calls for creating, modifying and deleting objects of that specific type.  Because the Object ID is structured, the ID states what type of object is specified. the Subscription and Resource Group it resides in, and its name.  If we know the provider name and can work out the current API version. that Id strings is all that is required for accessing (and provisioning) an Azure object through REST.

Creating a lookup table of Azure providers to versions is extremely simple.  The 'powershell-yaml' module for translating PowerShell to YAML is well used by everyone including Microsoft.  With a slight modification the module may be used for directly working with Microsoft's Azure providers.

A second module (AZRest) is included in this repository that demonstrates how to authenticate to Azure and get objects from the cloud.

Install instructions are referenced in the Repo 'Install' directory

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



## Benefits of using YAML with Azure

Any object can be processed and modified from the command line easily without a risk of dependency failure that is often attributed to PowerShell cmdlets with Azure.

![PSObject](images/PSObject.jpg)

Azure Resource Manager (ARM) templates are only a wrapper for calling Azure's providers.  By using PowerShell as the wrapper (or any other language) creating templates with advanced logic is a lot faster and more powerful.

Unlike third party products, using YAML with Azure isn't a framework.  It's simply working with Azure objects directly and saving them in a YAML format.  This means that all Microsoft Providers are always accessible without the overhead of creating custom libraries as Microsoft's service change.

Importantly, YAML is designed to be human readable and it supports the addition of comments into templates.  Something sorely missing with ARM. 