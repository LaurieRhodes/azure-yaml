# Azure DevOps - Using YAML Modules 
This example demonstrates using YAML templates for provisioning an Azure Sentinel environment.

The example will use Sentinel from the templates directory in this Repo.

![DevopsFiles](images/DevopsFiles.JPG)

Note that a 'modules' directory contains the two PowerShell modules required by this process. - AZRest &  powershell-yaml. 

Two variables are also set as part of this project.

<img src="images/variables.JPG" alt="variables" style="zoom:50%;" />

**Example Pipeline**

```powershell
trigger:
- master

pool:
  vmImage: "vs2017-win2016"

steps:
- task: CopyFiles@2
  inputs:
    Contents: '**'
    TargetFolder: '$(build.artifactstagingdirectory)'
    CleanTargetFolder: true

- task: PowerShell@2
  inputs:
    targetType: 'inline'
    script: |
      # Write your PowerShell commands here.
      Import-Module $(build.artifactstagingdirectory)\modules\AZRest\AZRest.psm1
      Import-Module $(build.artifactstagingdirectory)\modules\powershell-yaml\0.4.2\powershell-yaml.psm1

      # Get an authorised Azure Header
      $authHeader = Get-Header -scope "azure"  -Tenant "laurierhodes.info" -AppId $(AppId) -secret $(Secret)

      # Retrieve an up to date list of namespace versions (once per session)
      if (!$AzAPIVersions){$AzAPIVersions = Get-AzureAPIVersions -header $authHeader -SubscriptionID "2be53ae5-6e46-47df-beb9-6f3a795387b8"}

      # Deploy a Sentinel Environment from templates
      Get-Yamlfile -Path "$(build.artifactstagingdirectory)\ResourceGroup.yaml" | Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions
      Get-Yamlfile -Path "$(build.artifactstagingdirectory)\LogAnalytics.yaml" | Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions
      Get-Yamlfile -Path "$(build.artifactstagingdirectory)\EnableSentinel.yaml" | Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions

  env:
    APPID: $($env:APPID) # the recommended way to map to an env variable
    SECRET: $($env:SECRET) # the recommended way to map to an env variable
```



