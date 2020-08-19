# AZRest Module
[TOC]

## Installation

This module is available for download here: 

[/1.0/AZRest.zip]: /1.0/AZRest.zip	" current version"

Download and extract the module to be locally accessible

```powershell
Import-Module "<path-to-module>\AZRest\AZRest.psm1" 
```

## Functions:



## Get-Header

To Generically produce a header for use in calling Microsoft API endpoints.  Authentication supports combinations of either Username and Password, AppId and certificate thumbprint or AppId and Secret.  This module does not support MultiFactor Authentication.

**Parameters:**   

-Username   = Username
-Password   = password

-AppId      = The AppId of the App used for authentication

-Thumbprint = eg. B35E2C978F83B49C36116802DC08B7DF7B58AB08

-Tenant     = disney.onmicrosoft.com
 -Scope      = graph / azure



 **Examples:**  

```powershell
 Get-Header -scope "azure" -Tenant "disney.com" -Username "Donald@disney.com" -Password "Mickey01" 
 Get-Header -scope "graph" -Tenant "disney.com" -AppId "aa73b052-6cea-4f17-b54b-6a536be5c832" -Thumbprint "B35E2C978F83B49C36611802DC08B7DF7B58AB08" 
 Get-Header -scope "azure" -Tenant "disney.com" -AppId "aa73b052-6cea-4f17-b54b-6a536be5c715" -Secret 'xznhW@w/.Yz14[vC0XbNzDFwiRRxUtZ3'
```


## Get-AzureAPIVersions

Constructs a dictionary of current Azure namespaces.  This is used by processes to select the most current API versions when making Azure REST calls.

**Parameters:**  

-SubscriptionId      = The subscription ID of the environment to connect to.
-Header                   = A hashtable (header) with valid authentication for Azure Management

 **Example:**  

```powershell
Get-AzureAPIVersions = Get-AnalyticsWorkspaceKey `
                           -Header $header `
                           -SubscriptionId "ed4ef888-5466-401c-b77a-6f9cd7cc6815" 
```


## Get-Yamlfile

  Purpose:  Transforms a saved Yaml file to a Powershell Hash table

**Parameters:**   

-Path      =  The file path for the yaml file to import.

**Example:**      

```powershell
        $object = Get-Yamlfile `-Path "C:\templates\vmachine.yaml"
```



## Get-AzureObject

Gets an Azure API compliant hash table from Azure cloud objects

**Parameters:**   

-apiversions     = A hashtable representing current API versions
-authHeader    = A hashtable (header) with valid authentication for Azure Management
-id                      = An Azure object reference (string).

  **Example:**      

```powershell
Get-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions -id "/subscriptions/2be53ae5-6e46-47df-beb9-6f3a795387b8/resourcegroups/sentinel/providers/microsoft.insights/workbooks/$guid"
```



## Push-AzureObject

Pushes and Azure API compliant hash table to the cloud

**Parameters:**   

-azobject          = A hashtable representing an azure object.
-authHeader   = A hashtable (header) with valid authentication for Azure Management
-azobject          = A hashtable (dictionary) of Azure API versions.
-unescape        = may be set to $false to prevent the defaul behaviour of unescaping JSON

 **Example:**  

```powershell
Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions -azobject $azobject
```



## Remove-AzureObject

Deletes an azure object

**Parameters:**   

-apiversions     = A hashtable representing current API versions
-authHeader    = A hashtable (header) with valid authentication for Azure Management
-id                      = An Azure object reference (string).

  **Example:**      

```powershell
Remove-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions -id "/subscriptions/2be53ae5-6e46-47df-beb9-6f3a795387b8/resourcegroups/sentinel/providers/microsoft.insights/workbooks/$guid"
```

