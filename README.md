# azure-yaml
 Scripts and examples for provisioning Azure services with YAML.

*Background*

Azure engineers typically use 'ARM templates' for creating cloud objects although ARM templates are a proprietary automation solution for interacting with Resource Providers.  All resources in Azure are objects and may be provisioned and manipulated directly as long as the object type and respective API version are known.

Exactly what code or notation is used to *represent* a cloud object is irrelevant as long as it may be converted info a valid JSON object notation when being submitted to Azure Resource Provider.   Ultimately all cloud operations happen as REST calls.   

PowerShell Hash tables are a perfectly fine as representation of Azure objects just as YAML is a natural representation of the objects.  

Powershell-yaml is a community developed module that translates YAML to PowerShell Hash tables.  As Azure has a structured object Id format it is extremely straightforward translating  PowerShell Hash tables to Azure objects without any need for ARM templates.



