<#

Module Name:

    AZRest.psm1

Description:

    Provides Azure Rest API

Version History

    1.0    - 7 July 2020    Laurie Rhodes       Initial Release

#>




<#
  Function:  Get-Header

  Purpose:  To Generically produce a header for use in calling Microsoft API endpoints

  Parameters:   -Username   = Username
                -Password   = password

                -AppId      = The AppId of the App used for authentication
                -Thumbprint = eg. B35E2C978F83B49C36116802DC08B7DF7B58AB08

                -Tenant     = disney.onmicrosoft.com
                -Scope      = graph / azure

                -Proxy      ="http://proxy:8080"
                -ProxyCredential = (Credential Object)

  Example:  
    
     Get-Header -scope "azure" -Tenant "disney.com" -Username "Donald@disney.com" -Password "Mickey01" 
     Get-Header -scope "graph" -Tenant "disney.com" -AppId "aa73b052-6cea-4f17-b54b-6a536be5c832" -Thumbprint "B35E2C978F83B49C36611802DC08B7DF7B58AB08" 
     Get-Header -scope "azure" -Tenant "disney.com" -AppId "aa73b052-6cea-4f17-b54b-6a536be5c715" -Secret 'xznhW@w/.Yz14[vC0XbNzDFwiRRxUtZ3'

#>
function Get-Header(){
 
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName="User")]
        [string]$Username,
        [Parameter(ParameterSetName="User")]
        [String]$Password,
        [Parameter(ParameterSetName="App")]
        [Parameter(ParameterSetName="App2")]
        [string]$AppId,
        [Parameter(ParameterSetName="App")]
        [string]$Thumbprint,
        [Parameter(mandatory=$true)]
        [string]$Tenant,
        [Parameter(mandatory=$true)]
        [string]$Scope,
        [Parameter(ParameterSetName="App2")]
        [string]$Secret,
        [Parameter(mandatory=$false)]
        [string]$Proxy,
        [Parameter(mandatory=$false)]
        [PSCredential]$ProxyCredential
    )
 
 
    begin {
 
 
       $ClientId       = "1950a258-227b-4e31-a9cf-717495945fc2" 
 
 
       switch($Scope){
           'azure' {$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://management.azure.com/.default"
                    $ResourceID  = "https://management.azure.com/"
                    }
           'graph' {$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/token"
                    $RequestScope = "https://graph.microsoft.com/.default"
                    $ResourceID  = "https://graph.microsoft.com"
                    }
           'keyvault'{$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://vault.azure.net/.default"
                    $ResourceID  = "https://vault.azure.net"
                    }
           'storage'{$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://storage.azure.com/.default"
                    $ResourceID  = "https://storage.azure.com/"
                    }       
           'analytics'{$TokenEndpoint = "https://login.microsoftonline.com/$($tenant)/oauth2/v2.0/token"
                    $RequestScope = "https://api.loganalytics.io/.default"
                    $ResourceID  = "https://api.loganalytics.io/"
                    }                                   
           default { throw "Scope $($Scope) undefined - use azure or graph'" }
        }
 
        #Set Accountname based on Username or AppId
        if (!([string]::IsNullOrEmpty($Username))){$Accountname = $Username }
        if (!([string]::IsNullOrEmpty($AppId))){$Accountname = $AppId }
 
        
 
    }
    
    process {
        
        # Authenticating with Certificate
        if (!([string]::IsNullOrEmpty($Thumbprint))){
            write-host "+++ Certificate Authentication"
 
            # Try Local Machine Certs
            $Certificate = ((Get-ChildItem -Path Cert:\LocalMachine  -force -Recurse )| Where-Object {$_.Thumbprint -match $Thumbprint});
            if ([string]::IsNullOrEmpty($Certificate)){
            # Try Current User Certs
            $Certificate = ((Get-ChildItem -Path Cert:\CurrentUser  -force -Recurse )| Where-Object {$_.Thumbprint -match $Thumbprint});
            }
            
            if ([string]::IsNullOrEmpty($Certificate)){throw "certificate not found"}
 
 
            # Create base64 hash of certificate
            $CertificateBase64Hash = [System.Convert]::ToBase64String($Certificate.GetCertHash())
          
            # Create JWT timestamp for expiration
            $StartDate = (Get-Date "1970-01-01T00:00:00Z" ).ToUniversalTime()
            $JWTExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End (Get-Date).ToUniversalTime().AddMinutes(2)).TotalSeconds
            $JWTExpiration = [math]::Round($JWTExpirationTimeSpan,0)
 
            # Create JWT validity start timestamp
            $NotBeforeExpirationTimeSpan = (New-TimeSpan -Start $StartDate -End ((Get-Date).ToUniversalTime())).TotalSeconds
            $NotBefore = [math]::Round($NotBeforeExpirationTimeSpan,0)
 
            # Create JWT header
            $JWTHeader = @{
                alg = "RS256"
                typ = "JWT"
                x5t = $CertificateBase64Hash -replace '\+','-' -replace '/','_' -replace '='
            }
            
            # Create JWT payload
            $JWTPayLoad = @{
                aud = $TokenEndpoint
                exp = $JWTExpiration
                iss = $AppId
                jti = [guid]::NewGuid()
                nbf = $NotBefore
                sub = $AppId
            }
 
           
            # Convert header and payload to base64
            $JWTHeaderToByte = [System.Text.Encoding]::UTF8.GetBytes(($JWTHeader | ConvertTo-Json))
            $EncodedHeader = [System.Convert]::ToBase64String($JWTHeaderToByte)
 
            $JWTPayLoadToByte =  [System.Text.Encoding]::UTF8.GetBytes(($JWTPayload | ConvertTo-Json))
            $EncodedPayload = [System.Convert]::ToBase64String($JWTPayLoadToByte)
 
            # Join header and Payload with "." to create a valid (unsigned) JWT
            $JWT = $EncodedHeader + "." + $EncodedPayload
 
            # Get the private key object of your certificate
            $PrivateKey = $Certificate.PrivateKey
            if ([string]::IsNullOrEmpty($PrivateKey)){throw "Unable to access certificate Private Key"}
 
            # Define RSA signature and hashing algorithm
            $RSAPadding = [Security.Cryptography.RSASignaturePadding]::Pkcs1
            $HashAlgorithm = [Security.Cryptography.HashAlgorithmName]::SHA256
 
            # Create a signature of the JWT
 
            $Signature = [Convert]::ToBase64String( $PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($JWT),$HashAlgorithm,$RSAPadding) ) -replace '\+','-' -replace '/','_' -replace '='
            
            $JWTBytes = [System.Text.Encoding]::UTF8.GetBytes($JWT)
 
 
            # Join the signature to the JWT with "."
            $JWT = $JWT + "." + $Signature
 
 
       switch($Scope){
           'azure' {
                    $Body = @{
                        client_id = $AppId 
                        client_assertion = $JWT
                        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                        scope = $RequestScope
                        grant_type = "client_credentials"
                    }
                    }
           'graph' {
                    $Body = "grant_type=client_credentials" `
                     +"&username=" +$Accountname `
                     +"&client_id=" +$AppId `
                     +"&client_assertion=" +$JWT `
                     +"&client_assertion_type=" +"urn:ietf:params:oauth:client-assertion-type:jwt-bearer" `
                     +"&scope=" +$RequestScope
                    }
           'keyvault' {
                    $Body = @{
                        client_id = $AppId 
                        client_assertion = $JWT
                        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                        scope = $RequestScope
                        grant_type = "client_credentials"
                        }
                    }
           'analytics' {
                    $Body = @{
                        client_id = $AppId 
                        client_assertion = $JWT
                        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                        scope = $RequestScope
                        grant_type = "client_credentials"
                        }
                    }                   
           'storage' {
                    $Body = @{
                        client_id = $AppId 
                        client_assertion = $JWT
                        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
                        scope = $RequestScope
                        grant_type = "client_credentials"
                        }                    
                    }
        }# end switch
 
 
            $Url = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token"
 
            # Use the self-generated JWT as Authorization
            $Header = @{
                Authorization = "Bearer $JWT"
            }
 
            # Splat the parameters for Invoke-Restmethod for cleaner code
            $PostSplat = @{
                ContentType = 'application/x-www-form-urlencoded'
                Method = 'POST'
                Body = $Body
                Uri = $Url
                Headers = $Header
            }
 
 
            #Get Bearer Token
            $Request = Invoke-RestMethod @PostSplat
            # Create header
            $Header = $null
            $Header = @{
                Authorization = "$($Request.token_type) $($Request.access_token)"
            }
 
 
        } # End Certificate Authentication
 
 
 
        # Authenticating with Password
        if (!([string]::IsNullOrEmpty($Password))){
 
       switch($Scope){
           'azure' {
                    $Body = @{
                        client_id = $clientId 
                        username = $Accountname
                        password = $Password
                        scope = $RequestScope
                        grant_type = "password"
                      }
                    }
           'graph' {
                    $Body = "grant_type=password"`
                     +"&username=" +$Accountname `
                     +"&client_id=" +$clientId `
                     +"&password=" +$Password `
                     +"&resource=" +[system.uri]::EscapeDataString($ResourceID)
                        }
           'keyvault' {
                    $Body = @{
                        client_id = $clientId 
                        username = $Accountname
                        password = $Password
                        scope = $RequestScope
                        grant_type = "password"
                      }
                     }
           'analytics' {
                    $Body = @{
                        client_id = $clientId 
                        username = $Accountname
                        password = $Password
                        scope = $RequestScope
                        grant_type = "password"
                      }
                     }                     
           'storage' {
                    $Body = @{
                        client_id = $clientId 
                        username = $Accountname
                        password = $Password
                        scope = $RequestScope
                        grant_type = "password"
                      }
                     } 
           
 
        }# end switch
 
 
 
        } # end password block
 
        # Authenticating with Secret
        if (!([string]::IsNullOrEmpty($Secret))){
 
       switch($Scope){
           'azure' {
                    $Body = @{
                        client_id = $AppId  
                        client_secret = $Secret
                        scope = $RequestScope
                        grant_type = "client_credentials"
                      }
                    }
           'graph' {
                    $Body = "grant_type=client_credentials"`
                     +"&client_id=" +$AppId `
                     +"&client_secret=" +$Secret `
                     +"&resource=" +[system.uri]::EscapeDataString($ResourceID)
                      }
           'keyvault' {
                    $Body = @{
                        client_id = $AppId  
                        client_secret = $Secret
                        scope = $RequestScope
                        grant_type = "client_credentials"
                      }
                    }  
           'analytics' {
                    $Body = @{
                        client_id = $AppId  
                        client_secret = $Secret
                        scope = $RequestScope
                        grant_type = "client_credentials"
                      }
                    }                                             
           'storage' {
                    $Body = @{
                        client_id = $AppId  
                        client_secret = $Secret
                        scope = $RequestScope
                        grant_type = "client_credentials"
                      }
                    }                      
                      
        }# end switch
 
 
       } #End secret block
 
 
 
            # The result should contain a token for use with any REST endpoint

            $RequestSplat = @{
                Uri = $TokenEndpoint
                Method = “POST”
                Body = $Body 
            }



           # $Response = Invoke-WebRequest -Uri $TokenEndpoint -Method POST -Body $Body -UseBasicParsing

            $RequestSplat = @{
                Uri = $TokenEndpoint
                Method = “POST”
                Body = $Body 
                UseBasicParsing = $true
            }


           #Construct parameters if they exist
           if($Proxy){ $RequestSplat.Add('Proxy', $Proxy) }
           if($ProxyCredential){ $RequestSplat.Add('ProxyCredential', $ProxyCredential) }
                       
           $Response = Invoke-WebRequest @RequestSplat 



 
            $ResponseJSON = $Response|ConvertFrom-Json
 
 
            #Add the token to headers for the Graph request
            $Header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $Header.Add("Authorization", "Bearer "+$ResponseJSON.access_token)
            $Header.Add("Content-Type", "application/json")

            #storage requests require two different keys in the header 
            if ($Scope -eq "storage"){
                $Header.Add("x-ms-version", "2019-12-12")
                $Header.Add("x-ms-date", [System.DateTime]::UtcNow.ToString("R"))
            }

 
    }
    
    end {
 
       return $Header 
 
    }
 
}

 



<#
  Function:  Get-Latest

  Purpose:  Finds the latest date from a series of dates with the PowerShell pipeline

  Example:  
    
           $Hashtable | Get-latest
#>
function Get-Latest {
    Begin { $latest = $null }
    Process {
            if ($_  -gt $latest) { $latest = $_  }
    }
    End { $latest }
}



<#
  Function:  Get-AzureAPIVersions

  Purpose:  Constructs a dictionary of current Azure namespaces

  Parameters:   -SubscriptionId      = The subscription ID of the environment to connect to.
                -Header              = A hashtable (header) with valid authentication for Azure Management

  Example:  
    
             Get-AzureAPIVersions = Get-AnalyticsWorkspaceKey `
                                      -Header $header `
                                      -SubscriptionId "ed4ef888-5466-401c-b77a-6f9cd7cc6815" 
#>
function Get-AzureAPIVersions(){
param(
    [parameter( Mandatory = $true)]
    [string]$header,
    [parameter( Mandatory = $true)]
    [string]$SubscriptionID
)

    $dict = @{}

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionID)/providers/?api-version=2015-01-01"
    $result = Invoke-RestMethod -Uri $uri -Method GET -Headers $authHeader 

    $namespaces = $result.value 

    foreach ($namespace in $namespaces){
       foreach ($resource in $namespace.resourceTypes){

       #Add Provider Plus Resource Type
        $dict.Add("$($namespace.namespace)/$($resource.resourceType)",$($resource.apiVersions | Get-latest) )
       }
     }

     #return dictionary
     $dict
}


<#
  Function:  Get-Yamlfile

  Purpose:  Transforms a saved Yaml file to a Powershell Hash table

  Parameters:   -Path      = The file path for the yaml file to import.

  Example:  
    
            $object = Get-Yamlfile `-Path "C:\templates\vmachine.yaml"
#>
function Get-Yamlfile(){
param(
    [parameter( Mandatory = $true)]
    [string]$Path
)

    $content = ''

    [string[]]$fileContent = Get-Content $path

    foreach ($line in $fileContent) { $content = $content + "`n" + $line }

    ConvertFrom-Yaml $content

}



<#
  Function:  Get-JSONfile

  Purpose:  Transforms a saved Yaml file to a Powershell Hash table

  Parameters:   -Path      = The file path for the json file to import.

  Example:  
    
            $object = Get-JSONfile `-Path "C:\templates\vmachine.json"
#>
function Get-Jsonfile(){
param(
    [parameter( Mandatory = $true)]
    [string]$Path
)

    [string]$content = $null

    [string]$content = Get-Content -Path $path -Raw 
    
    Remove-TypeData System.Array # Remove the redundant ETS-supplied .Count property
    # https://stackoverflow.com/questions/20848507/why-does-powershell-give-different-result-in-one-liner-than-two-liner-when-conve/38212718#38212718

    $jsonobj =  ($content  | ConvertFrom-Json )

    $AzObject = ConvertTo-HashTable -InputObject $jsonobj

    
    $AzObject
}



<#
  Function:  ConvertTo-Hashtable
  
  Author:  Adam Bertram
             https://4sysops.com/archives/convert-json-to-a-powershell-hash-table/

  Purpose:  Transforms a saved Yaml file to a Powershell Hash table

  Parameters:   -InputObject      = the json custom object file to import.

  Example:    $json | ConvertFrom-Json | ConvertTo-HashTable
#>
function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }

        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )

            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}




<#
  Function:  Set-AzureObject

  Purpose:  Changes aspects of the Id Property of an Azure object.  This allows
            Properties to be modified from the default values stored in templates.
            Typically this might be changing subscription or resourcegroup values
            for testing.

  Parameters:   -object        = The PowerShell custom object / Azure object to be modified
                -subscription  = The new subscription gui to deploy to


  Example:  
    
          $object = Set-AzureObject -object $object -Subscription "2be53ae5-6e46-47df-beb9-6f3a795387b8"
#> 
function Set-AzureObject(){
param(
    [parameter( Mandatory = $false)]
    [string]$Subscription,
    [parameter( Mandatory = $true)]
    [hashtable]$AzObject
)



    if ($Subscription){  
      $IdString = Set-IdSubscription -IdString $AzObject.id -Subscription $Subscription 
      $AzObject.id = $IdString
    }

    #return the object
     $AzureObject

}



<#
  Function: Set-IdSubscription

  Purpose:  Changes the subscription of the Id Property with an Azure object.  

  Parameters:   -object        = The PowerShell custom object / Azure object to be modified
                -subscription  = The new subscription gui to deploy to


  Example:  
    
          $object = Set-IdSubscription -object $object -Subscription "2be53ae5-6e46-47df-beb9-6f3a795387b8"
#> 
function Set-IdSubscription(){
param(
    [OutputType([hashtable])]
    [parameter( Mandatory = $true)]
    [string]$Subscription,
    [parameter( Mandatory = $true)]
    [string]$IdString
)

   # write-host "Set-IdSubscription azobject type = $($AzObject.GetType())"
    
    
  #Get Id property and split by '/' subscription
#  try{
#  $id = $AzObject.id
    $IdArray = $IdString.split('/')
     
#  }
#  catch{
#    throw "Unable to split Id element on object for subscription substitution.  Check input object"
#  }
#  finally{
  If ($IdArray[1] -eq 'subscriptions'){
    # substitute the subscription id with the new version
    $IdArray[2] = $Subscription

    #reconstruct the Id
    $id = ""
        for ($i=1;$i -lt $IdArray.Count; $i++) {
        $id = "$($id)/$($IdArray[$i])" 
    }

   #write-debug "new constructed id = $($id)"

   $IdString = $id

   #return the amended string
   #write-host "Set-IdSubscription2 azobject type = $($AzObject.GetType())"

  }
     $IdString
 #    }
}




<#
  Function:  Get-AzureObject

  Purpose:  Gets and Azure API compliant hash table from Azure cloud objects

  Parameters:   -apiversions   = A hashtable representing current API versions
                -authHeader    = A hashtable (header) with valid authentication for Azure Management
                -id            = An Azure object reference (string).

  Example:  
    
             Get-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions -azobject $azobject
#> 
function Get-AzureObject(){
param(
    [parameter( Mandatory = $true, ValueFromPipeline = $true)]
    [string]$id,
    [parameter( Mandatory = $true)]
    $authHeader,
    [parameter( Mandatory = $true)]
    $apiversions
)


Process  {
     $IDArray = ($id).split("/")
     # $namespace = $IDArray[6]
     # $resourcetype = $IDArray[7]

     # Find the last 'provider' element
     for ($i=0; $i -lt $IDArray.length; $i++) {
      if ($IDArray[$i] -eq 'providers'){$provIndex =  $i}
     }

     $arraykey = "$($IDArray[$provIndex + 1])/$($IDArray[$provIndex + 2])"

   #type can be overloaded - include if present
   if($IDArray[$provIndex + 4]){ 
     if($apiversions["$($arraykey)/$($IDArray[$provIndex + 4])"]){ $arraykey = "$($arraykey)/$($IDArray[$provIndex + 4])" } 
   }
     
     #Resource Groups are a special case without a provider
     if($IDArray[-2] -eq "resourceGroups"){ $arraykey = "Microsoft.Resources/resourceGroups"}

     $uri = "https://management.azure.com/$($id)?api-version=$($apiversions["$($arraykey)"])"
    Invoke-RestMethod -Uri $uri -Method GET -Headers $authHeader 

  }

}



<#
  Function:  Remove-AzureObject

  Purpose:  Deletes an azure object

  Parameters:   -id            = A string ID representing an azure object.
                -authHeader    = A hashtable (header) with valid authentication for Azure Management
                -id            = An Azure object reference (string).

  Example:  
    
             Remove-AzureObject -AuthHeader $authHeader -Apiversions $AzAPIVersions -azobject $azobject
#> 
function Remove-AzureObject(){
param(
    [parameter( Mandatory = $true, ValueFromPipeline = $true)]
    [string]$id,
    [parameter( Mandatory = $true)]
    $authHeader,
    [parameter( Mandatory = $true)]
    $apiversions
)


Process  {
     $IDArray = ($id).split("/")
     # $namespace = $IDArray[6]
     # $resourcetype = $IDArray[7]

     # Find the last 'provider' element
     for ($i=0; $i -lt $IDArray.length; $i++) {
      if ($IDArray[$i] -eq 'providers'){$provIndex =  $i}
     }

     $arraykey = "$($IDArray[$provIndex + 1])/$($IDArray[$provIndex + 2])"


   #type can be overloaded - include if present
   if($IDArray[$provIndex + 4]){ 
     if($apiversions["$($arraykey)/$($IDArray[$provIndex + 4])"]){ $arraykey = "$($arraykey)/$($IDArray[$provIndex + 4])" } 
   }
     
     #Resource Groups are a special case without a provider
     if($IDArray.count -eq 5){ $arraykey = "Microsoft.Resources/resourceGroups"}
     
     $uri = "https://management.azure.com/$($id)?api-version=$($apiversions["$($arraykey)"])"

    Invoke-RestMethod -Uri $uri -Method DELETE -Headers $authHeader 

  }

}



<#
  Function:  Push-Azureobject

  Purpose:  Pushes and Azure API compliant hash table to the cloud

  Parameters:   -azobject      = A hashtable representing an azure object.
                -authHeader    = A hashtable (header) with valid authentication for Azure Management
                -azobject      = A hashtable (dictionary) of Azure API versions.
                -unescape      = may be set to $false to prevent the defaul behaviour of unescaping JSON

  Example:  
    
             Push-Azureobject -AuthHeader $authHeader -Apiversions $AzAPIVersions -azobject $azobject
#> 
function Push-Azureobject(){
param(
    [parameter( Mandatory = $true, ValueFromPipeline = $true)]
    [Hashtable]$azobject,
    [parameter( Mandatory = $true)]
    $authHeader,
    [parameter( Mandatory = $true)]
    $apiversions,
    [parameter( Mandatory = $false)]
    [bool]$unescape=$true
)


Process  {
    $IDArray = ($azobject.id).split("/")
    # $namespace = $IDArray[6]
    # $resourcetype = $IDArray[7]

   # Find the last 'provider' element
   for ($i=0; $i -lt $IDArray.length; $i++) {
	   if ($IDArray[$i] -eq 'providers'){$provIndex =  $i}
   }

   $arraykey = "$($IDArray[$provIndex + 1])/$($IDArray[$provIndex + 2])"


   #type can be overloaded - include if present
   if($IDArray[$provIndex + 4]){ 
     if($apiversions["$($arraykey)/$($IDArray[$provIndex + 4])"]){ $arraykey = "$($arraykey)/$($IDArray[$provIndex + 4])" } 
   }
     
     #Resource Groups are a special case without a provider
     if($IDArray.count -eq 5){ $arraykey = "Microsoft.Resources/resourceGroups"}


#write-output "arraykey = $($arraykey )"
     
   $uri = "https://management.azure.com$($azobject.id)?api-version=$($apiversions["$($arraykey)"])"
   
   if ($unescape -eq $true){
      Invoke-RestMethod -Uri $uri -Method PUT -Headers $authHeader -Body $($azobject | ConvertTo-Json -Depth 50 | % { [System.Text.RegularExpressions.Regex]::Unescape($_) })   
   }
   else  
   {
      Invoke-RestMethod -Uri $uri -Method PUT -Headers $authHeader -Body $($azobject | ConvertTo-Json -Depth 50 )   
   }
   
  }

}






Export-ModuleMember -function Get-Header, Get-Latest, Get-AzureAPIVersions, Get-AzureObject, Set-AzureObject, Push-AzureObject, Remove-AzureObject, Get-Yamlfile, Get-Jsonfile
