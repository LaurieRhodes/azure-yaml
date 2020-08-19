# Sentinel Install
These templates and scripts may be used to install a working Sentinel environment.

The installation steps involve the creation of:

* A Resource Group object
* A Log Analytics Workspace
* The Sentinel product

Optional Additions:

* Data Connectors
* Alert Rules
* Workbooks
* Playbooks

The Id of each object requires customising within the template to reflect the intended Subscription, Resource Group and Name of the object.

## Customise YAML Templates

Each object in Azure had a unique identification that represents the subscription, Resource Group and name of the resource.  These need to be updated in each template prior to deployment.

**<u>LogAnalytics.yaml</u>**

![](img\LogAnalytics.JPG)

The Log Analytics workspace template needs to be customised to set the resource location, name and reference Id.

**<u>EnableSentinel.yaml</u>**

![](img\EnableSentinel.JPG)

Sentinel is enabled from a Log Analytics Workspace.  Note that in this example 'asesentinel6' is the name of the Log Analytics workspace.



## *Example Install Script*

```powershell

# Optional import of modules
# Install-Module -Name powershell-yaml
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

# Add data connectors
Get-Yamlfile -Path "$path\Sentinel\dataConnectors\253f8493-841e-4264-a218-4b7697026292.yaml" | Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions 

# Add Alert Rules, Playbooks etc.

```



