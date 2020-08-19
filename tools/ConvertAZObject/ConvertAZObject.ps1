# Example of Exporting an existing object to YAML

 Import-Module "C:\Scripts\AZRest\1.0\AZRest\AZRest.psm1" 
 Import-Module "C:\Scripts\\powershell-yaml\0.4.2\powershell-yaml.psm1" 

# Get an authorised Azure Header
$authHeader = Get-Header -scope "azure"  -Tenant "laurierhodes.info" -AppId "aa73b052-6cea-4f17-b54b-6a536be5c715" `
                         -secret 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'

# Retrieve an up to date list of namespace versions (once per session)
if (!$AzAPIVersions){$AzAPIVersions = Get-AzureAPIVersions -header $authHeader -SubscriptionID "2be53ae5-6e46-47df-beb9-6f3a795387b8"}

$id="/subscriptions/ed4ef888-5466-401c-b77a-6f9cd7cc6815/resourcegroups/rg-compliance-automation/providers/microsoft.operationalinsights/workspaces/compliance-automation"

$object = $null

$object =    Get-Azureobject -AuthHeader $authHeader -apiversions $AzAPIVersions -id $id


Out-File -FilePath "C:\Test\deploy.yaml" -InputObject (ConvertTo-Yaml -data $object) -Force 