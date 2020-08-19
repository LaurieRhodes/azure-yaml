# Sentinel Workbooks

Deploying workbooks allows for the default "My Workbook" selection to be customised / populated for all users of a particular Sentinel environment.

![](\images\workbook.png)

Workbooks use are presented like the object below.

```yaml
#
# Modify the Id string and remove the comment hash prior to deployment. 
#
#id: /subscriptions/<subscription guid>/resourcegroups/<resourcegroupname>/providers/microsoft.insights/workbooks/5be9c384-7896-4916-b21f-0bb75cd64cca
type: microsoft.insights/workbooks
location: australiasoutheast
tags:
  hidden-title: Azure Activity
kind: shared
properties:
  displayName: Azure Activity
  serializedData: "{\"version\":\"Notebook/1.0\",\"items\":[{\"type\":9,\"content\":{\"version\":\"KqlParameterItem/1.0\",\"query\":\"\"... \"}"
  version: "1.0"
  category: sentinel
  userId: 38eb6895-bc03-49c1-bb0b-8afe97dd162b
  sourceId: /subscriptions/2be53ae5-6e46-47df-beb9-6f3a795387b8/resourcegroups/sentinel/providers/microsoft.operationalinsights/workspaces/asesentinel6
  tags:
  - AzureActivityWorkbook
  - "1.2"
  storageUri: 
```



Note: **Workbook templates** contain escaped JSON by design.  To be pushed to Azure successfully, escaping must be left intact.  This is done by setting "unescape" to false.

```powershell
| Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions -unescape $false
```

