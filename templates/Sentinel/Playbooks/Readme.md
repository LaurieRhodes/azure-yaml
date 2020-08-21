# //TODO Playbooks

The Playbooks in this directory are community contributed and forked from the Sentinel community site.  The convention is to develop ARM templates as Playbooks / Logic Apps.  

It would be a mistake to not use existing ARM resources with YAML. 

![ARM-Templates](Images/ARM-Templates.JPG)

ARM Templates are deployed to their own dedicated 'deployment' Provider which can be managed with YAML like all other objects.

https://docs.microsoft.com/en-us/rest/api/resources/deployments/createorupdate#deploymentproperties

This allows ARM templates to be wrapped in YAML and deployed to the traditional ARM provider.

... examples of using "converted arm" templates is coming next...

